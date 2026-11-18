"""Opt-in integration against the installed CLI, using only a loopback provider."""

import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import unittest


SOURCE = Path(__file__).resolve().parents[2] / "config/codex/task-check/task_check.py"
spec = importlib.util.spec_from_file_location("task_check_isolation", SOURCE)
task_check = importlib.util.module_from_spec(spec)
spec.loader.exec_module(task_check)


def sse(items, number):
    response_id = f"test-{number}"
    events = [{"type": "response.created", "response": {"id": response_id}}]
    events += [{"type": "response.output_item.done", "item": item} for item in items]
    events += [
        {
            "type": "response.completed",
            "response": {
                "id": response_id,
                "usage": {"input_tokens": 0, "output_tokens": 0, "total_tokens": 0},
            },
        }
    ]
    return "".join(
        f"event: {event['type']}\ndata: {json.dumps(event)}\n\n" for event in events
    ).encode()


@unittest.skipUnless(
    os.environ.get("CODEX_TASK_CHECK_CODEX"),
    "set CODEX_TASK_CHECK_CODEX for CLI integration",
)
class CliIsolationTest(unittest.TestCase):
    def test_real_hook_inputs_reach_record_question_and_stop_checks(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            records = directory / "events.jsonl"
            hook = directory / "hook.py"
            hook.write_text(
                "import importlib.util, json, pathlib, sys\n"
                f"spec = importlib.util.spec_from_file_location('task_check', {str(SOURCE)!r})\n"
                "module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module)\n"
                "event = json.load(sys.stdin)\n"
                "kind = {'UserPromptSubmit': 'record', 'PreToolUse': 'question', 'Stop': 'stop'}[event['hook_event_name']]\n"
                "evidence_log = []\n"
                "def judge(evidence, codex):\n"
                "    evidence_log.append(evidence)\n"
                "    quote = 'Synthetic question?' if kind == 'question' else 'First ending'\n"
                "    return {'decision': 'revise', 'reason': 'SYNTHETIC_CONTINUE', 'user_quote': 'Synthetic request', 'candidate_quote': quote}\n"
                f"reply = module.process_event(kind, event, pathlib.Path({str(directory / 'hook-state')!r}), 'enforce', 'unused', judge)\n"
                f"with pathlib.Path({str(records)!r}).open('a') as output:\n"
                "    output.write(json.dumps({'event': event, 'evidence': evidence_log, 'reply': reply}) + '\\n')\n"
                "print(json.dumps(reply))\n"
            )
            requests = []

            class Handler(BaseHTTPRequestHandler):
                def log_message(self, *args):
                    pass

                def do_POST(self):
                    data = json.loads(
                        self.rfile.read(int(self.headers["Content-Length"]))
                    )
                    requests.append(data)
                    if len(requests) == 1:
                        item = {
                            "type": "function_call",
                            "call_id": "question-call",
                            "name": "request_user_input",
                            "arguments": json.dumps(
                                {
                                    "questions": [
                                        {
                                            "header": "Test",
                                            "id": "test",
                                            "question": "Synthetic question?",
                                            "options": [
                                                {
                                                    "label": "A",
                                                    "description": "Option A",
                                                },
                                                {
                                                    "label": "B",
                                                    "description": "Option B",
                                                },
                                            ],
                                        }
                                    ]
                                }
                            ),
                        }
                    else:
                        text = "First ending" if len(requests) == 2 else "Final ending"
                        item = {
                            "type": "message",
                            "role": "assistant",
                            "id": f"message-{len(requests)}",
                            "phase": "final_answer",
                            "content": [{"type": "output_text", "text": text}],
                        }
                    body = sse([item], len(requests))
                    self.send_response(200)
                    self.send_header("Content-Type", "text/event-stream")
                    self.send_header("Content-Length", str(len(body)))
                    self.end_headers()
                    self.wfile.write(body)

            server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
            threading.Thread(target=server.serve_forever, daemon=True).start()
            hook_config = (
                f'=[{{hooks=[{{type="command",command="python3 {hook}",timeout=5}}]}}]'
            )
            settings = [
                'model_provider="task_check_test"',
                'model="gpt-6.2-sol"',
                'model_providers.task_check_test.name="Local test"',
                f'model_providers.task_check_test.base_url="http://127.0.0.1:{server.server_port}/v1"',
                'model_providers.task_check_test.wire_api="responses"',
                "model_providers.task_check_test.requires_openai_auth=false",
                "model_providers.task_check_test.supports_websockets=false",
                "features.plugins=false",
                "features.apps=false",
                "features.shell_snapshot=false",
                "features.default_mode_request_user_input=true",
                f'sqlite_home="{directory / "state"}"',
                f'log_dir="{directory / "logs"}"',
            ] + [
                f"hooks.{name}{hook_config}"
                for name in ("UserPromptSubmit", "PreToolUse", "Stop")
            ]
            command = [
                os.environ["CODEX_TASK_CHECK_CODEX"],
                "exec",
                "--ignore-user-config",
                "--skip-git-repo-check",
                "--json",
                "--dangerously-bypass-hook-trust",
                "-C",
                str(directory),
            ]
            for setting in settings:
                command.extend(["-c", setting])
            command.append("Synthetic request: build the report.")
            try:
                result = subprocess.run(
                    command, text=True, capture_output=True, timeout=45
                )
            finally:
                server.shutdown()
                server.server_close()
                if records.exists():
                    for line in records.read_text().splitlines():
                        event = json.loads(line)["event"]
                        session_id = event.get("session_id", "")
                        transcript = event.get("transcript_path")
                        if transcript and session_id:
                            path = Path(transcript)
                            # Only delete the rollout uniquely identified by this synthetic session.
                            if (
                                "sessions" in path.parts
                                and path.name.startswith("rollout-")
                                and path.name.endswith(f"-{session_id}.jsonl")
                            ):
                                path.unlink(missing_ok=True)
            self.assertEqual(result.returncode, 0, result.stderr[-3000:])
            self.assertTrue(records.exists(), result.stderr[-3000:])
            events = [json.loads(line) for line in records.read_text().splitlines()]
            by_kind = {
                name: [
                    entry
                    for entry in events
                    if entry["event"]["hook_event_name"] == name
                ]
                for name in ("UserPromptSubmit", "PreToolUse", "Stop")
            }
            self.assertTrue(all(by_kind.values()), events)
            self.assertTrue(
                all(
                    entry["event"].get("transcript_path")
                    for entry in events
                    if entry["event"]["hook_event_name"] != "UserPromptSubmit"
                ),
                events,
            )
            for entry in events:
                for key in ("session_id", "turn_id"):
                    self.assertTrue(entry["event"].get(key), (key, entry))
            self.assertTrue(
                all(
                    entry["event"]["session_id"] == events[0]["event"]["session_id"]
                    and entry["event"]["turn_id"] == events[0]["event"]["turn_id"]
                    for entry in events
                )
            )
            question = by_kind["PreToolUse"][0]
            self.assertIn("Synthetic request", question["evidence"][0]["requests"][0])
            self.assertEqual(
                question["reply"]["hookSpecificOutput"]["permissionDecision"], "deny"
            )
            stops = by_kind["Stop"]
            self.assertGreaterEqual(len(stops), 2)
            self.assertIn("Synthetic request", stops[0]["evidence"][0]["requests"][0])
            self.assertEqual(stops[0]["reply"]["decision"], "block")
            self.assertEqual(stops[-1]["reply"], {})
            self.assertGreaterEqual(len(requests), 3)
            self.assertIn("SYNTHETIC_CONTINUE", json.dumps(requests[1]))
            self.assertIn("SYNTHETIC_CONTINUE", json.dumps(requests[2]))
            self.assertIn("Final ending", result.stdout)

    def test_no_tools_and_unsolicited_calls_cannot_run(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            marker = directory / "must-not-exist"
            requests = []
            verdict = {
                "decision": "allow",
                "reason": "検証用の応答",
                "user_quote": "",
                "candidate_quote": "",
            }

            class Handler(BaseHTTPRequestHandler):
                def log_message(self, *args):
                    pass

                def do_POST(self):
                    data = json.loads(
                        self.rfile.read(int(self.headers["Content-Length"]))
                    )
                    requests.append(data)
                    if len(requests) == 1:
                        items = [
                            {
                                "type": "function_call",
                                "call_id": "forbidden-exec",
                                "name": "exec_command",
                                "arguments": json.dumps({"cmd": f"touch {marker}"}),
                            },
                            {
                                "type": "custom_tool_call",
                                "call_id": "forbidden-patch",
                                "name": "apply_patch",
                                "input": f"*** Begin Patch\n*** Add File: {marker}\n+bad\n*** End Patch",
                            },
                        ]
                    else:
                        items = [
                            {
                                "type": "message",
                                "role": "assistant",
                                "id": "final",
                                "content": [
                                    {"type": "output_text", "text": json.dumps(verdict)}
                                ],
                            }
                        ]
                    body = sse(items, len(requests))
                    self.send_response(200)
                    self.send_header("Content-Type", "text/event-stream")
                    self.send_header("Content-Length", str(len(body)))
                    self.end_headers()
                    self.wfile.write(body)

            server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
            threading.Thread(target=server.serve_forever, daemon=True).start()
            settings = [
                'model_provider="task_check_test"',
                'model_providers.task_check_test.name="Local test"',
                f'model_providers.task_check_test.base_url="http://127.0.0.1:{server.server_port}/v1"',
                'model_providers.task_check_test.wire_api="responses"',
                "model_providers.task_check_test.requires_openai_auth=false",
                "model_providers.task_check_test.supports_websockets=false",
            ]
            try:
                result = subprocess.run(
                    task_check.judge_command(
                        os.environ["CODEX_TASK_CHECK_CODEX"], directory, settings
                    ),
                    input="Synthetic test evidence only.",
                    text=True,
                    capture_output=True,
                    timeout=30,
                )
            finally:
                server.shutdown()
                server.server_close()
            self.assertEqual(result.returncode, 0, result.stderr[-3000:])
            self.assertGreaterEqual(len(requests), 2)
            self.assertTrue(all(not request.get("tools") for request in requests))
            self.assertFalse(marker.exists())
            outputs = [
                item
                for item in requests[1]["input"]
                if item.get("type")
                in {"function_call_output", "custom_tool_call_output"}
            ]
            self.assertEqual(len(outputs), 2)
            self.assertTrue(
                all("unsupported" in str(item["output"]) for item in outputs)
            )
            self.assertEqual(
                json.loads((directory / "verdict.json").read_text()), verdict
            )


if __name__ == "__main__":
    unittest.main()
