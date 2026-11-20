import assert from "node:assert/strict";
import { realpathSync } from "node:fs";
import { test } from "node:test";
import install from "../../config/pi/agent-task.ts";

test("Pi sees the registered goal only in its assigned checkout", () => {
  const root = realpathSync(".");
  const saved = process.env;
  process.env = {
    ...saved,
    AGENT_TASK_NAME: "api-change",
    AGENT_TASK_ROOT: root,
    AGENT_TASK_ARTIFACTS: root + "/.work/agent-tasks/api-change",
    AGENT_TASK_GOAL: "Keep the old client working.\nVerify it with an integration test.",
  };
  try {
    const handlers = new Map();
    install({ on: (name, handler) => handlers.set(name, handler) });
    const labels = [];
    handlers.get("session_start")({}, {
      cwd: root, hasUI: true, ui: { setStatus: (_name, label) => labels.push(label) },
    });
    assert.deepEqual(labels, ["Task: api-change (goal set)"]);

    const prompt = (cwd) => {
      const event = { systemPromptOptions: {} };
      handlers.get("before_agent_start")(event, { cwd });
      return (event.systemPromptOptions.promptGuidelines ?? []).join("\n");
    };
    assert.match(prompt(root), /Keep the old client working/);
    assert.doesNotMatch(prompt("/"), /Keep the old client working/);
  } finally {
    process.env = saved;
  }
});
