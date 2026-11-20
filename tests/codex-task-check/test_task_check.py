import importlib.util
import json
import os
from pathlib import Path
import stat
import tempfile
import time
import unittest
from unittest.mock import patch


MODULE_PATH = (
    Path(__file__).resolve().parents[2] / "config/codex/task-check/task_check.py"
)
spec = importlib.util.spec_from_file_location("task_check", MODULE_PATH)
task_check = importlib.util.module_from_spec(spec)
spec.loader.exec_module(task_check)


def message(role, text, **extra):
    return {
        "type": "response_item",
        "payload": {
            "type": "message",
            "role": role,
            "content": [
                {
                    "type": "input_text" if role == "user" else "output_text",
                    "text": text,
                }
            ],
            **extra,
        },
    }


def revise(user="Build the report", candidate="Should I proceed?"):
    return {
        "decision": "revise",
        "reason": "Continue the requested work.",
        "user_quote": user,
        "candidate_quote": candidate,
    }


class TaskCheckTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.root = self.base / "state"
        self.transcript = self.base / "session.jsonl"
        self.write_transcript(
            message("user", "Build the report"), message("assistant", "Working on it.")
        )
        self.captured = []

    def write_transcript(self, *items):
        self.transcript.write_text("".join(json.dumps(item) + "\n" for item in items))

    def event(self, kind, turn="turn-1", **overrides):
        data = {
            "hook_event_name": {
                "record": "UserPromptSubmit",
                "question": "PreToolUse",
                "stop": "Stop",
            }[kind],
            "session_id": "session-1",
            "turn_id": turn,
            "transcript_path": str(self.transcript),
        }
        if kind == "record":
            data["prompt"] = "Build the report"
        elif kind == "question":
            data.update(
                tool_name="request_user_input",
                tool_input={"questions": [{"question": "Should I proceed?"}]},
            )
        else:
            data["last_assistant_message"] = "Should I proceed?"
        data.update(overrides)
        return data

    def judge(self, verdict=None):
        def fake(evidence, _codex):
            self.captured.append(evidence)
            return verdict if verdict is not None else revise()

        return fake

    def process(self, kind, event=None, mode="enforce", judge=None):
        return task_check.process_event(
            kind,
            event or self.event(kind),
            self.root,
            mode,
            "unused",
            judge or self.judge(),
        )

    def test_ledger_retains_original_and_late_requests_across_turns(self):
        self.process("record")
        self.process(
            "record", self.event("record", turn="turn-2", prompt="Also include a chart")
        )
        self.process(
            "question",
            self.event("question", turn="turn-2"),
            judge=self.judge(revise("Also include a chart")),
        )
        self.assertIn("Build the report", self.captured[-1]["requests"])
        self.assertIn("Also include a chart", self.captured[-1]["requests"])
        # Once the prior turn is flushed, its request remains in the correct order.
        self.write_transcript(
            message("user", "Build the report"),
            message("user", "Also include a chart"),
            message("user", "Do not publish it"),
        )
        self.process(
            "record", self.event("record", turn="turn-3", prompt="Do not publish it")
        )
        self.process("question", self.event("question", turn="turn-3"))
        self.assertEqual(len(self.captured), 2)
        self.assertEqual(
            self.captured[-1]["requests"],
            ["Build the report", "Also include a chart", "Do not publish it"],
        )

    def test_missing_older_record_fails_open_without_judging(self):
        self.process("record")
        self.process(
            "record", self.event("record", turn="turn-2", prompt="Also include a chart")
        )
        self.write_transcript(
            message("user", "Build the report"), message("user", "Do not publish it")
        )
        self.process(
            "record", self.event("record", turn="turn-3", prompt="Do not publish it")
        )
        self.assertEqual(
            self.process("question", self.event("question", turn="turn-3")), {}
        )
        self.assertEqual(self.captured, [])

    def test_repeated_pause_waits_for_ordered_transcript(self):
        for same_turn in (False, True):
            with self.subTest(same_turn=same_turn):
                self.root = self.base / str(same_turn)
                self.captured.clear()
                prompts = ["Pause the work", "Resume the work", "Pause the work"]
                turns = ["turn-1"] * 3 if same_turn else ["turn-1", "turn-2", "turn-3"]
                for turn, prompt in zip(turns, prompts):
                    self.process(
                        "record", self.event("record", turn=turn, prompt=prompt)
                    )
                self.write_transcript(*(message("user", text) for text in prompts[:2]))
                event = self.event("stop", turn=turns[-1])
                self.assertEqual(self.process("stop", event), {})
                self.assertEqual(self.captured, [])

                self.write_transcript(*(message("user", text) for text in prompts))
                self.process("stop", event)
                self.assertEqual(self.captured[-1]["requests"], prompts)

        # A ledger first created on the repeated input cannot match an older copy.
        self.root = self.base / "late-ledger"
        self.captured.clear()
        self.process("record", self.event("record", prompt="Pause the work"))
        self.write_transcript(*(message("user", text) for text in prompts[:2]))
        self.assertEqual(self.process("stop"), {})
        self.assertEqual(self.captured, [])

    def test_question_names_share_limit_but_stop_and_later_turn_are_independent(self):
        first = self.process("question")
        self.assertEqual(first["hookSpecificOutput"]["permissionDecision"], "deny")
        self.assertEqual(
            self.process(
                "question", self.event("question", tool_name="request_user_input_async")
            ),
            {},
        )
        self.assertEqual(self.process("stop")["decision"], "block")
        self.assertEqual(self.process("stop"), {})
        self.assertEqual(
            self.process("question", self.event("question", turn="turn-2"))[
                "hookSpecificOutput"
            ]["permissionDecision"],
            "deny",
        )

    def test_stop_hook_active_and_unrelated_tool_pass(self):
        self.assertEqual(
            self.process("stop", self.event("stop", stop_hook_active=True)), {}
        )
        self.assertEqual(
            self.process("question", self.event("question", tool_name="shell")), {}
        )
        self.assertEqual(self.captured, [])
        self.assertEqual(self.process("stop")["decision"], "block")

    def test_observe_does_not_deny_or_consume_rejection(self):
        self.assertEqual(self.process("question", mode="observe"), {})
        self.assertEqual(
            self.process("question")["hookSpecificOutput"]["permissionDecision"], "deny"
        )

    def test_pi_inline_evidence_is_observed_without_reading_a_codex_transcript(self):
        event = self.event(
            "stop",
            transcript_path=str(self.base / "does-not-exist.jsonl"),
            transcript_items=[
                message("user", "Build the report"),
                message("assistant", "Should I proceed?"),
            ],
        )
        reply = task_check.process_event(
            "stop", event, self.root, "observe", "unused", self.judge(),
            read_items=task_check.read_pi_transcript,
        )
        self.assertEqual(reply, {})
        self.assertEqual(self.captured[0]["requests"], ["Build the report"])
        self.assertIn("tool_details_omitted", self.captured[0]["limitations"])
        state = json.loads(next(self.root.glob("*.json")).read_text())
        self.assertEqual(state["requests"], [])
        self.assertEqual(state["audit"][-1]["outcome"], "observed_revision")

    def test_pi_observe_skips_a_history_with_a_filtered_user_input(self):
        event = self.event(
            "stop",
            transcript_items=[
                message("user", "Build the report"),
                message("user", "<INSTRUCTIONS>Stop now."),
                message("assistant", "Should I proceed?"),
            ],
        )
        self.assertEqual(
            task_check.process_event(
                "stop", event, self.root, "observe", "unused", self.judge(),
                read_items=task_check.read_pi_transcript,
            ),
            {},
        )
        self.assertEqual(self.captured, [])

    def test_invalid_evidence_or_judge_failure_fails_open(self):
        failures = [
            revise(user="not a request"),
            revise(candidate="not the question"),
            {"decision": "revise"},
            {
                "decision": "unknown",
                "reason": "",
                "user_quote": "",
                "candidate_quote": "",
            },
            {
                "decision": "allow",
                "reason": "",
                "user_quote": "",
                "candidate_quote": "",
            },
        ]
        for verdict in failures:
            with self.subTest(verdict=verdict):
                self.assertEqual(
                    self.process("question", judge=self.judge(verdict)), {}
                )

        def failed(_evidence, _codex):
            raise TimeoutError("private error")

        self.assertEqual(self.process("question", judge=failed), {})
        self.assertEqual(
            self.process("question")["hookSpecificOutput"]["permissionDecision"], "deny"
        )
        self.transcript.write_text("not json\n")
        self.assertEqual(self.process("stop"), {})

    def test_real_judge_process_invalid_output_and_timeout_fail_open(self):
        executable = self.base / "fake-codex"
        executable.write_text(
            "#!/usr/bin/env python3\n"
            "import pathlib, sys\n"
            "pathlib.Path(sys.argv[sys.argv.index('--output-last-message') + 1]).write_text('not json')\n"
        )
        executable.chmod(0o700)
        judge = lambda evidence, _: task_check.run_judge(
            evidence, str(executable), timeout=2
        )
        self.assertEqual(self.process("question", judge=judge), {})

        marker = self.base / "child-survived"
        child = f"import pathlib, time; time.sleep(0.5); pathlib.Path({str(marker)!r}).touch()"
        executable.write_text(
            "#!/usr/bin/env python3\n"
            "import subprocess, sys, time\n"
            f"subprocess.Popen([sys.executable, '-c', {child!r}])\n"
            "time.sleep(10)\n"
        )
        judge = lambda evidence, _: task_check.run_judge(
            evidence, str(executable), timeout=0.2
        )
        self.assertEqual(self.process("question", judge=judge), {})
        time.sleep(0.7)
        self.assertFalse(marker.exists(), "judge descendant survived the timeout")
        self.assertEqual(
            self.process("question")["hookSpecificOutput"]["permissionDecision"], "deny"
        )

    def test_missing_transcript_never_denies_even_with_recorded_request(self):
        self.process("record")
        self.assertEqual(
            self.process("question", self.event("question", transcript_path="")), {}
        )

    def test_evidence_excludes_hidden_reasoning_and_injected_policy(self):
        self.write_transcript(
            message("user", "Build the report"),
            message("system", "SYSTEM_SECRET"),
            message("developer", "DEV_SECRET"),
            message("user", "<environment_context>INJECTED_SECRET"),
            {
                "type": "response_item",
                "payload": {"type": "reasoning", "summary": "REASONING_SECRET"},
            },
            message("assistant", "I will inspect the data.", phase="commentary"),
            {
                "type": "response_item",
                "payload": {
                    "type": "function_call",
                    "call_id": "1",
                    "name": "read",
                    "arguments": "{}",
                },
            },
            {
                "type": "response_item",
                "payload": {
                    "type": "function_call_output",
                    "call_id": "1",
                    "output": "data read",
                },
            },
        )
        self.process("question")
        serialized = json.dumps(self.captured[-1])
        for secret in (
            "SYSTEM_SECRET",
            "DEV_SECRET",
            "INJECTED_SECRET",
            "REASONING_SECRET",
        ):
            self.assertNotIn(secret, serialized)
        for visible in ("I will inspect the data.", "data read", "read"):
            self.assertIn(visible, serialized)

    def test_state_is_private_and_expired_state_is_removed(self):
        self.process("record")
        state_file = next(self.root.glob("*.json"))
        self.assertEqual(stat.S_IMODE(self.root.stat().st_mode), 0o700)
        self.assertEqual(stat.S_IMODE(state_file.stat().st_mode), 0o600)
        old = time.time() - task_check.RETENTION - 10
        os.utime(state_file, (old, old))
        self.process("record", self.event("record", session_id="different-session"))
        self.assertFalse(state_file.exists())

    def test_busy_session_lock_fails_open_without_disturbing_state(self):
        self.process("record")
        state_file = next(self.root.glob("*.json"))
        before = state_file.read_text()
        with task_check.session_lock(self.root, "session-1"):
            with (
                patch.object(
                    task_check.sys,
                    "argv",
                    ["task_check", "question", "--state-dir", str(self.root)],
                ),
                patch.object(task_check.sys, "stdin") as stdin,
                patch("builtins.print") as output,
            ):
                stdin.buffer.read.return_value = json.dumps(
                    self.event("question")
                ).encode()
                task_check.main()
            self.assertEqual(json.loads(output.call_args.args[0]), {})
            self.assertEqual(state_file.read_text(), before)
        self.assertEqual(
            self.process("question")["hookSpecificOutput"]["permissionDecision"], "deny"
        )

    def test_rejection_is_not_returned_when_persistence_fails(self):
        with patch.object(task_check, "write_state", side_effect=OSError("disk full")):
            # The public hook entry point must translate persistence failure into an allow.
            with (
                patch.object(
                    task_check.sys,
                    "argv",
                    ["task_check", "question", "--state-dir", str(self.root)],
                ),
                patch.object(task_check.sys, "stdin") as stdin,
                patch("builtins.print") as output,
                patch.object(task_check, "run_judge", self.judge()),
            ):
                # process_event's default judge is bound at definition time; inject via wrapper.
                original = task_check.process_event
                with patch.object(
                    task_check,
                    "process_event",
                    side_effect=lambda *args: original(*args, judge=self.judge()),
                ):
                    stdin.buffer.read.return_value = json.dumps(
                        self.event("question")
                    ).encode()
                    task_check.main()
                self.assertEqual(json.loads(output.call_args.args[0]), {})


if __name__ == "__main__":
    unittest.main()
