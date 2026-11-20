import assert from "node:assert/strict";
import { test } from "node:test";
import { installObserver } from "../../config/pi/task-check/observe.ts";

function fixture(finish = (done) => done()) {
  const handlers = new Map();
  const calls = [];
  const branch = [];
  const ctx = {
    sessionManager: {
      getBranch: () => branch,
      getSessionId: () => "test-session",
      getSessionFile: () => "/test/session.jsonl",
    },
  };
  installObserver({ on: (name, callback) => handlers.set(name, callback) }, "/test/checker",
    (checker, kind, payload, done) => {
      calls.push({ checker, kind, payload });
      finish(done);
    });
  const emit = (name, event = {}) => handlers.get(name)(event, ctx);
  const message = (id, role, content, extra = {}) =>
    branch.push({ id, type: "message", message: { role, content, ...extra } });
  const input = (id, prompt, source = "interactive") => {
    emit("input", { text: prompt, source });
    emit("before_agent_start", { messageType: "user", prompt });
    message(id, "user", prompt);
  };
  emit("session_start");
  return { branch, calls, emit, input, message };
}

test("Pi records each question and final response once and omits internal and tool data", () => {
  const { calls, emit, input, message, branch } = fixture();
  input("user", "Write the report.");
  message("system", "system", "system instructions");
  message("action", "assistant", [
    { type: "thinking", thinking: "internal reasoning" },
    { type: "toolCall", id: "read", name: "read", arguments: { path: "private-file" } },
  ]);
  message("result", "toolResult", [{ type: "text", text: "private output" }], { toolCallId: "read", isError: false });
  const question = { toolName: "request_user_input", input: { question: "Which format?" } };
  assert.equal(emit("tool_call", question), undefined);
  emit("tool_call", question);
  message("final", "assistant", [{ type: "text", text: "I drafted the report." }], { stopReason: "stop" });
  assert.equal(emit("agent_settled"), undefined);
  emit("agent_settled");

  assert.deepEqual(calls.map((call) => call.kind), ["question", "stop"]);
  const payload = calls[1].payload;
  assert.equal(payload.turn_id, "user");
  const serialized = JSON.stringify(payload);
  assert.match(serialized, /Write the report/);
  assert.match(serialized, /I drafted the report/);
  assert.match(serialized, /"isError":false/);
  assert.doesNotMatch(serialized, /internal reasoning|system instructions|custom content|private-file|private output/);
});

test("unverified, resumed, or interrupted input does not trigger observation", () => {
  const { calls, emit, input, message } = fixture();
  input("injected", "Injected prompt", "extension");
  message("first", "assistant", [{ type: "text", text: "Done." }], { stopReason: "stop" });
  emit("agent_settled");

  emit("session_start");
  input("latest", "Prepare a summary");
  message("second", "assistant", [{ type: "text", text: "Done." }], { stopReason: "stop" });
  emit("agent_settled"); // The earlier prompt did not come from observed human input.
  assert.equal(calls.length, 0);

  const interrupted = fixture();
  interrupted.input("user", "Continue the work.");
  interrupted.emit("input", { text: "Stop", source: "interactive", streamingBehavior: "steer" });
  interrupted.message("answer", "assistant", [{ type: "text", text: "Done." }], { stopReason: "stop" });
  interrupted.emit("agent_settled");
  assert.equal(interrupted.calls.length, 0);
});

test("an aborted turn is never checked and its request is retained for a later turn", () => {
  const { calls, emit, input, message } = fixture();
  input("previous", "Prepare a report");
  message("aborted", "assistant", [{ type: "text", text: "Working." }], { stopReason: "aborted" });
  emit("agent_settled", { aborted: true });
  assert.equal(calls.length, 0);
  input("new", "Continue the report");
  message("final", "assistant", [{ type: "text", text: "Done." }], { stopReason: "stop" });
  emit("agent_settled");
  assert.equal(calls[0].payload.turn_id, "new");
  assert.match(JSON.stringify(calls[0].payload), /Prepare a report/);
});

test("extension-authored messages invalidate the current observation", () => {
  const { calls, branch, emit, input, message } = fixture();
  input("user", "Explain the report.");
  branch.push({ id: "injected", type: "custom_message", content: "unverified input" });
  message("answer", "assistant", [{ type: "text", text: "Unverified answer." }], { stopReason: "stop" });
  emit("agent_settled");
  assert.equal(calls.length, 0);
});

test("finish is queued behind a question and neither hook waits for the checker", () => {
  const completions = [];
  const { calls, emit, input, message } = fixture((done) => completions.push(done));
  input("user", "Explain the report.");
  const question = { question: "Which report?" };
  question.unrelatedData = question;
  assert.equal(emit("tool_call", { toolName: "request_user_input", input: question }), undefined);
  message("answer", "assistant", [{ type: "text", text: "Here is the report." }], { stopReason: "stop" });
  assert.equal(emit("agent_settled"), undefined);
  assert.deepEqual(calls.map((call) => call.kind), ["question"]);
  assert.deepEqual(calls[0].payload.tool_input, { question: "Which report?" });
  completions.shift()();
  assert.deepEqual(calls.map((call) => call.kind), ["question", "stop"]);
  completions.shift()();
});
