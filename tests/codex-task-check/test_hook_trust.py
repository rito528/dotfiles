"""Check Home Manager's trust entries against Codex's actual hook loader."""

import copy
import json
import os
from pathlib import Path
import queue
import re
import subprocess
import tempfile
import threading
import time
import tomllib
import unittest


def toml_value(value):
    if isinstance(value, dict):
        return (
            "{"
            + ",".join(
                f"{json.dumps(key)}={toml_value(item)}" for key, item in value.items()
            )
            + "}"
        )
    if isinstance(value, list):
        return "[" + ",".join(map(toml_value, value)) + "]"
    return json.dumps(value)


def list_session_hooks(hooks):
    with tempfile.TemporaryDirectory(prefix="codex-hook-trust-") as temporary:
        command = [
            os.environ["CODEX_TASK_CHECK_CODEX"],
            "app-server",
            "-c",
            "features.plugins=false",
            "-c",
            "features.apps=false",
            "-c",
            "check_for_update_on_startup=false",
            "-c",
            f'sqlite_home="{temporary}/state"',
            "-c",
            f'log_dir="{temporary}/logs"',
            "-c",
            "hooks=" + toml_value(hooks),
        ]
        process = subprocess.Popen(
            command,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
        )
        responses = queue.Queue()

        def read_responses():
            for line in process.stdout:
                responses.put(json.loads(line))

        reader = threading.Thread(target=read_responses, daemon=True)
        reader.start()

        def call(identifier, method, params):
            process.stdin.write(
                json.dumps({"id": identifier, "method": method, "params": params})
                + "\n"
            )
            process.stdin.flush()
            deadline = time.monotonic() + 20
            while True:
                response = responses.get(timeout=max(0, deadline - time.monotonic()))
                if response.get("id") == identifier:
                    if "error" in response:
                        raise AssertionError(response["error"])
                    return response["result"]

        try:
            call(
                1,
                "initialize",
                {
                    "clientInfo": {"name": "task-check-trust-test", "version": "1"},
                    "capabilities": {"experimentalApi": True},
                },
            )
            result = call(2, "hooks/list", {"cwds": [temporary]})
            return [
                hook
                for entry in result["data"]
                for hook in entry["hooks"]
                if hook["source"] == "sessionFlags"
            ]
        finally:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)
            reader.join(timeout=5)
            process.stdin.close()
            process.stdout.close()


@unittest.skipUnless(
    os.environ.get("CODEX_TASK_CHECK_CODEX")
    and os.environ.get("CODEX_TASK_CHECK_ACTIVATION"),
    "set CODEX_TASK_CHECK_CODEX and CODEX_TASK_CHECK_ACTIVATION for trust integration",
)
class HookTrustTest(unittest.TestCase):
    def test_generated_trust_accepts_only_the_deployed_definitions(self):
        activation = Path(os.environ["CODEX_TASK_CHECK_ACTIVATION"]).read_text()
        match = re.search(
            r'install -m 644 (\S+-codex-config\.toml) "([^"]+/\.codex/config\.toml)"',
            activation,
        )
        self.assertIsNotNone(match, "Home Manager's Codex config copy was not found")
        hooks = tomllib.loads(Path(match[1]).read_text())["hooks"]
        expected_events = {"pre_tool_use", "user_prompt_submit", "stop"}
        expected_keys = {f"{match[2]}:{event}:0:0" for event in expected_events}
        self.assertEqual(set(hooks["state"]), expected_keys)
        # Session overrides have their own source identity. Only rebase that path;
        # the trust hashes under test come unchanged from the Nix-generated file.
        hooks["state"] = {
            key.replace(match[2], "/<session-flags>/config.toml", 1): value
            for key, value in hooks["state"].items()
        }
        approved = list_session_hooks(hooks)
        self.assertEqual(len(approved), 3)
        self.assertTrue(all(hook["enabled"] for hook in approved))
        for hook in approved:
            self.assertEqual(hook["trustStatus"], "trusted")
            self.assertEqual(
                hook["currentHash"], hooks["state"][hook["key"]]["trusted_hash"]
            )

        changed = copy.deepcopy(hooks)
        changed["Stop"][0]["hooks"][0]["command"] += " --mode observe"
        changed["PostToolUse"] = [{"hooks": [{"type": "command", "command": "true"}]}]
        statuses = {
            hook["eventName"]: hook["trustStatus"]
            for hook in list_session_hooks(changed)
        }
        self.assertEqual(statuses["stop"], "modified")
        self.assertEqual(statuses["postToolUse"], "untrusted")
        self.assertEqual(statuses["preToolUse"], "trusted")
        self.assertEqual(statuses["userPromptSubmit"], "trusted")


if __name__ == "__main__":
    unittest.main()
