"""Bounded, fail-open checks for Codex question and Stop hooks."""

import argparse
from collections import deque
from contextlib import contextmanager
import fcntl
import hashlib
import json
import os
from pathlib import Path
import signal
import stat
import subprocess
import sys
import tempfile
import time


ASSETS = Path(__file__).resolve().parent
MAX_INPUT = 256_000
MAX_REQUESTS = 64_000
MAX_TRANSCRIPT = 32_000_000
MAX_EVENTS = 48_000
RETENTION = 7 * 24 * 60 * 60
QUESTION_TOOLS = {"request_user_input", "request_user_input_async"}
INJECTED_PREFIXES = (
    "<environment_context>",
    "<subagent_notification>",
    "<codex_internal_context>",
    "<skill>",
    "# AGENTS.md instructions",
    "<INSTRUCTIONS>",
)
DISABLED_FEATURES = (
    "hooks",
    "shell_tool",
    "shell_snapshot",
    "view_image",
    "sleep_tool",
    "deferred_executor",
    "request_permissions_tool",
    "token_budget",
    "current_time_reminder",
    "send_message_to_user_async",
    "multi_agent",
    "multi_agent_v2",
    "agent_message_board",
    "apps",
    "plugins",
    "image_generation",
    "goals",
    "memories",
    "skill_search",
    "executor_capability_discovery",
    "executor_capability_discovery_v2",
    "multi_env_copy_file",
    "code_mode",
    "code_mode_only",
    "js_repl",
)


def empty_state():
    return {"requests": [], "requests_incomplete": False, "turns": {}, "audit": []}


def is_user_request(text):
    return (
        isinstance(text, str)
        and bool(text.strip())
        and not text.lstrip().startswith(INJECTED_PREFIXES)
    )


def record_request(state, turn_id, prompt):
    entry = {"turn_id": turn_id, "text": prompt}
    if not is_user_request(prompt) or state["requests"][-1:] == [entry]:
        return
    state["requests"].append(entry)
    while sum(len(x["text"]) for x in state["requests"]) > MAX_REQUESTS:
        state["requests"].pop(0)
        state["requests_incomplete"] = True


def message_text(payload):
    content = payload.get("content", [])
    if isinstance(content, str):
        return content
    if not isinstance(content, list):
        return ""
    return "\n".join(
        x["text"]
        for x in content
        if isinstance(x, dict)
        and x.get("type") in {"input_text", "output_text", "text"}
        and isinstance(x.get("text"), str)
    )


def normalize_item(item):
    """Keep observable messages/actions, never hidden reasoning or injected policy."""
    if item.get("type") != "response_item":
        return None
    payload = item.get("payload", {})
    kind = payload.get("type")
    if kind == "message":
        role = payload.get("role")
        text = message_text(payload)
        if role == "user" and is_user_request(text):
            return {"type": "user", "text": text}
        if role == "assistant" and payload.get("phase") in {
            None,
            "commentary",
            "final_answer",
            "partial_answer",
        }:
            return {"type": "assistant", "text": text}
    if kind in {"function_call", "custom_tool_call"}:
        return {
            "type": "tool_call",
            "call_id": payload.get("call_id"),
            "name": payload.get("name"),
            "input": payload.get("arguments", payload.get("input")),
        }
    if kind in {"function_call_output", "custom_tool_call_output"}:
        return {
            "type": "tool_result",
            "call_id": payload.get("call_id"),
            "output": payload.get("output"),
        }
    return None


def read_transcript(path):
    requests, events, limitations = [], deque(), []
    event_size, request_size, total = 0, 0, 0
    if not path:
        return requests, [], ["transcript_unavailable"], True
    with open(path, "rb") as source:
        if not stat.S_ISREG(os.fstat(source.fileno()).st_mode):
            raise ValueError("not a regular transcript")
        if os.fstat(source.fileno()).st_size > MAX_TRANSCRIPT:
            return [], [], ["transcript_too_large"], True
        for raw in source:
            total += len(raw)
            if total > MAX_TRANSCRIPT:
                return [], [], ["transcript_too_large"], True
            item = json.loads(raw)
            if item.get("type") == "compacted":
                limitations.append("compaction_present")
            event = normalize_item(item)
            if event is None:
                continue
            if event["type"] == "user":
                request_size += len(event["text"])
                if request_size > MAX_REQUESTS:
                    return [], [], ["request_history_too_large"], True
                requests.append(event["text"])
                continue
            encoded = json.dumps(event, ensure_ascii=False)
            if len(encoded) > 6000:
                event = {
                    "type": event["type"],
                    "call_id": event.get("call_id"),
                    "truncated_record": encoded[:6000],
                }
                limitations.append("tool_or_message_truncated")
            size = len(json.dumps(event, ensure_ascii=False))
            events.append((event, size))
            event_size += size
            while event_size > MAX_EVENTS:
                _, removed_size = events.popleft()
                event_size -= removed_size
                limitations.append("older_actions_omitted")
    return requests, [x for x, _ in events], sorted(set(limitations)), not requests


def build_evidence(kind, event, state):
    requests, actions, limitations, incomplete = read_transcript(
        event.get("transcript_path")
    )
    # Match occurrences in order. Identical instructions may recur after a reversal.
    cursor = 0
    for entry in state["requests"]:
        try:
            cursor = requests.index(entry["text"], cursor) + 1
        except ValueError:
            # Only append an unambiguous new input from the current turn.
            if entry["turn_id"] == event["turn_id"] and entry["text"] not in requests:
                requests.append(entry["text"])
                cursor = len(requests)
            else:
                incomplete = True
                limitations.append("recorded_request_missing_from_transcript")
    if (
        state["requests"]
        and state["requests"][-1]["turn_id"] == event["turn_id"]
        and requests[-1:] != [state["requests"][-1]["text"]]
    ):
        incomplete = True
        limitations.append("latest_recorded_request_order_uncertain")
    incomplete = incomplete or state["requests_incomplete"]
    candidate = (
        event.get("last_assistant_message")
        if kind == "stop"
        else json.dumps(event.get("tool_input", {}), ensure_ascii=False)
    )
    if (
        not isinstance(candidate, str)
        or not candidate.strip()
        or len(candidate) > 20_000
    ):
        raise ValueError("candidate missing or too large")
    return {
        "check": kind,
        "requests": requests,
        "events": actions,
        "candidate": candidate,
        "limitations": limitations,
        "requests_incomplete": incomplete,
    }


def validate_verdict(verdict, evidence):
    if not isinstance(verdict, dict) or set(verdict) != {
        "decision",
        "reason",
        "user_quote",
        "candidate_quote",
    }:
        raise ValueError("invalid judgement")
    if any(not isinstance(x, str) for x in verdict.values()):
        raise ValueError("invalid judgement fields")
    if verdict["decision"] not in {"allow", "revise", "unknown"}:
        raise ValueError("invalid decision")
    if len(verdict["reason"]) > 1200:
        raise ValueError("reason too large")
    if verdict["decision"] == "revise":
        user_quote, candidate_quote = verdict["user_quote"], verdict["candidate_quote"]
        if (
            evidence["requests_incomplete"]
            or not verdict["reason"].strip()
            or not user_quote.strip()
            or not candidate_quote.strip()
            or len(user_quote) > 1000
            or len(candidate_quote) > 1000
            or not any(user_quote in request for request in evidence["requests"])
            or candidate_quote not in evidence["candidate"]
        ):
            raise ValueError("revision lacks evidence")
    return verdict


def hook_reply(kind, verdict):
    if verdict["decision"] != "revise":
        return {}
    reason = (
        "既存の依頼と権限の範囲内で再確認してください。新しい要件や承認を追加する指示ではありません。"
        "中断・撤回・必要な承認待ちは優先してください。\n" + verdict["reason"]
    )
    if kind == "stop":
        return {"decision": "block", "reason": reason}
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }


def judge_command(codex, directory, extra_config=()):
    settings = (
        [
            'model_provider="openai"',
            'model="gpt-6.2-sol"',
            'model_reasoning_effort="medium"',
            'approval_policy="never"',
            'web_search="disabled"',
            "project_doc_max_bytes=0",
            "agents.enabled=false",
            "tools.experimental_request_user_input.enabled=false",
            "tools.update_plan.enabled=false",
            "cloud.skills.enabled=false",
            "orchestrator.mcp.enabled=false",
            "skills.include_instructions=false",
            "check_for_update_on_startup=false",
            "analytics.enabled=false",
            'history.persistence="none"',
            "model_catalog_json=" + json.dumps(str(ASSETS / "judge_models.json")),
            "model_instructions_file=" + json.dumps(str(ASSETS / "judge_prompt.txt")),
            "sqlite_home=" + json.dumps(str(directory / "state")),
            "log_dir=" + json.dumps(str(directory / "logs")),
        ]
        + [f"features.{name}=false" for name in DISABLED_FEATURES]
        + list(extra_config)
    )
    command = [
        codex,
        "exec",
        "--ignore-user-config",
        "--ephemeral",
        "--skip-git-repo-check",
        "--sandbox",
        "read-only",
        "--color",
        "never",
        "-C",
        str(directory),
        "--output-schema",
        str(ASSETS / "judge_schema.json"),
        "--output-last-message",
        str(directory / "verdict.json"),
    ]
    for setting in settings:
        command.extend(["-c", setting])
    return command + [
        "Evaluate the supplied evidence only. Return the required judgement JSON."
    ]


def run_judge(evidence, codex, timeout=30):
    with tempfile.TemporaryDirectory(prefix="codex-task-check-") as temporary:
        directory = Path(temporary)
        environment = dict(os.environ, CODEX_TASK_CHECK_JUDGE="1")
        process = subprocess.Popen(
            judge_command(codex, directory),
            stdin=subprocess.PIPE,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            text=True,
            env=environment,
            start_new_session=True,
        )
        try:
            process.communicate(
                json.dumps(evidence, ensure_ascii=False), timeout=timeout
            )
        except BaseException:
            os.killpg(process.pid, signal.SIGKILL)
            process.communicate()
            raise
        if process.returncode:
            raise RuntimeError("judge failed")
        output = (directory / "verdict.json").read_text()
        if len(output) > 8000:
            raise ValueError("judge output too large")
        return validate_verdict(json.loads(output), evidence)


def write_state(path, state):
    descriptor, temporary = tempfile.mkstemp(prefix=".state-", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w") as target:
            json.dump(state, target, ensure_ascii=False)
            target.flush()
            os.fsync(target.fileno())
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


@contextmanager
def session_lock(root, session_id):
    root.mkdir(mode=0o700, parents=True, exist_ok=True)
    if root.is_symlink() or root.stat().st_uid != os.getuid():
        raise ValueError("invalid state directory")
    root.chmod(0o700)
    digest = hashlib.sha256(session_id.encode()).hexdigest()
    descriptor = os.open(
        root / (digest + ".lock"), os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600
    )
    with os.fdopen(descriptor, "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        yield root / (digest + ".json")


def cleanup(root, now):
    for path in root.glob("*.json"):
        if path.is_symlink() or now - path.stat().st_mtime <= RETENTION:
            continue
        lock_path = path.with_suffix(".lock")
        with open(lock_path, "a") as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                continue
            if now - path.stat().st_mtime > RETENTION:
                path.unlink()


def audit(state, kind, outcome, elapsed):
    state["audit"] = (
        state["audit"]
        + [
            {
                "time": int(time.time()),
                "check": kind,
                "outcome": outcome,
                "duration_ms": int(elapsed * 1000),
            }
        ]
    )[-100:]


def process_event(kind, event, root, mode, codex, judge=run_judge):
    expected = {"record": "UserPromptSubmit", "question": "PreToolUse", "stop": "Stop"}
    if event.get("hook_event_name") != expected[kind]:
        return {}
    if kind == "question" and event.get("tool_name") not in QUESTION_TOOLS:
        return {}
    session_id, turn_id = event.get("session_id"), event.get("turn_id")
    if not all(isinstance(x, str) and 0 < len(x) <= 256 for x in (session_id, turn_id)):
        return {}
    started = time.monotonic()
    with session_lock(root, session_id) as path:
        cleanup(root, time.time())
        state = json.loads(path.read_text()) if path.exists() else empty_state()
        if kind == "record":
            record_request(state, turn_id, event.get("prompt"))
            write_state(path, state)
            return {}
        used = state["turns"].get(turn_id, [])
        if kind in used or (kind == "stop" and event.get("stop_hook_active")):
            audit(state, kind, "limit", 0)
            write_state(path, state)
            return {}
        reply = {}
        try:
            evidence = build_evidence(kind, event, state)
            if evidence["requests_incomplete"]:
                outcome = "incomplete_history"
            else:
                verdict = validate_verdict(judge(evidence, codex), evidence)
                outcome = verdict["decision"]
                if outcome == "revise" and mode == "enforce":
                    state["turns"][turn_id] = used + [kind]
                    state["turns"] = dict(list(state["turns"].items())[-128:])
                    reply = hook_reply(kind, verdict)
                elif outcome == "revise":
                    outcome = "observed_revision"
        except Exception as error:
            outcome = "error:" + type(error).__name__
        audit(state, kind, outcome, time.monotonic() - started)
        # Persist the allowance before returning a rejection. Failure must pass.
        write_state(path, state)
        return reply


def interrupted(_signal, _frame):
    raise InterruptedError("hook interrupted")


def main():
    signal.signal(signal.SIGTERM, interrupted)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("kind", choices=["record", "question", "stop"])
    parser.add_argument(
        "--mode", choices=["enforce", "observe", "off"], default="enforce"
    )
    parser.add_argument("--codex", default="codex")
    parser.add_argument(
        "--state-dir",
        type=Path,
        default=Path(
            os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))
        )
        / "codex-task-check",
    )
    args = parser.parse_args()
    reply = {}
    try:
        if args.mode != "off" and not os.environ.get("CODEX_TASK_CHECK_JUDGE"):
            raw = sys.stdin.buffer.read(MAX_INPUT + 1)
            if len(raw) > MAX_INPUT:
                raise ValueError("hook input too large")
            event = json.loads(raw)
            reply = process_event(
                args.kind, event, args.state_dir, args.mode, args.codex
            )
    except Exception:
        # Never expose transcript/model errors to stdout or turn a check failure into a block.
        pass
    print(json.dumps(reply, ensure_ascii=False))


if __name__ == "__main__":
    main()
