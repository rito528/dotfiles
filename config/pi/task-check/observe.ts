import { spawn } from "node:child_process";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

type Branch = ReturnType<ExtensionContext["sessionManager"]["getBranch"]>;
type Check = "question" | "stop";
type Payload = Record<string, unknown>;

const questionTools = new Set(["request_user_input", "request_user_input_async"]);

function text(content: unknown): string | undefined {
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return;
  const lines = content
    .filter((block) => block.type === "text" && typeof block.text === "string")
    .map((block) => block.text);
  return lines.length ? lines.join("\n") : undefined;
}

function lastUser(branch: Branch) {
  return branch.findLast((node) => node.type === "message" && node.message.role === "user");
}

function response(payload: Payload) {
  return { type: "response_item", payload };
}

function branchItems(branch: Branch, humanInputs: Map<string, string>) {
  const items: Payload[] = [];
  let includeResponses = false;
  for (const node of branch) {
    if (node.type === "custom_message" || node.type === "context_edit") {
      includeResponses = false;
    }
    if (node.type === "compaction") {
      items.push({ type: "compacted" });
    }
    if (node.type !== "message") continue;
    const message = node.message;
    if (message.role === "user") {
      const input = humanInputs.get(node.id);
      if (!input || input !== text(message.content)) return;
      items.push(response({ type: "message", role: "user", content: input }));
      includeResponses = true;
    } else if (includeResponses && message.role === "assistant") {
      const output = text(message.content);
      if (output) items.push(response({ type: "message", role: "assistant", content: output }));
      for (const block of message.content) {
        if (block.type === "toolCall") {
          items.push(response({ type: "function_call", call_id: block.id, name: block.name }));
        }
      }
    } else if (includeResponses && message.role === "toolResult") {
      items.push(response({ type: "function_call_output", call_id: message.toolCallId, output: {
        isError: message.isError,
      } }));
    }
  }
  return includeResponses ? items : undefined;
}

function submit(command: string, kind: Check, payload: Payload, onClose: () => void) {
  const data = JSON.stringify(payload);
  if (Buffer.byteLength(data) > 256_000) {
    onClose();
    return;
  }
  const child = spawn(command, [kind, "--pi-observe"], { stdio: ["pipe", "ignore", "ignore"] });
  const timeout = setTimeout(() => child.kill(), 40_000);
  timeout.unref();
  child.once("error", () => { /* Audit failures must not affect the Pi session. */ });
  child.once("close", () => {
    clearTimeout(timeout);
    onClose();
  });
  child.stdin.on("error", () => { /* The checker may have exited before reading stdin. */ });
  child.stdin.end(data);
  child.unref();
}

export function installObserver(pi: ExtensionAPI, checker: string, dispatch = submit) {
  if (process.env.PI_TASK_CHECK === "off") return;

  const humanInputs = new Map<string, string>();
  let pending: { raw: string; previousUser?: string } | undefined;
  let active: typeof pending;
  const observed = new Set<Check>();
  const queue: Array<{ kind: Check; payload: Payload }> = [];
  let inFlight = false;

  function dispatchNext() {
    if (inFlight) return;
    const item = queue.shift();
    if (!item) return;
    inFlight = true;
    const done = () => {
      inFlight = false;
      dispatchNext();
    };
    try {
      dispatch(checker, item.kind, item.payload, done);
    } catch {
      done();
    }
  }

  function attestInput(branch: Branch) {
    const user = lastUser(branch);
    if (
      !active || !user || user.type !== "message" || user.message.role !== "user" ||
      user.id === active.previousUser || text(user.message.content) !== active.raw
    ) return;
    humanInputs.set(user.id, active.raw);
    return user;
  }

  pi.on("session_start", () => {
    pending = undefined;
    active = undefined;
    humanInputs.clear();
    observed.clear();
    queue.length = 0;
  });

  pi.on("session_shutdown", () => {
    queue.length = 0;
  });

  pi.on("input", (event, ctx) => {
    const branch = ctx.sessionManager.getBranch();
    attestInput(branch);
    pending = undefined;
    active = undefined;
    if (
      (event.source !== "interactive" && event.source !== "rpc") ||
      event.streamingBehavior || event.images?.length || !event.text.trim() ||
      /^\s*\//.test(event.text)
    ) return;

    pending = { raw: event.text, previousUser: lastUser(branch)?.id };
  });

  pi.on("before_agent_start", (event) => {
    active = event.messageType === "user" && event.prompt === pending?.raw
      ? pending
      : undefined;
    pending = undefined;
    observed.clear();
  });

  function observe(kind: Check, fields: Payload, ctx: ExtensionContext, branch: Branch) {
    const user = attestInput(branch);
    if (!user || !ctx.sessionManager.getSessionFile() || observed.has(kind) || queue.length >= 4) return;
    const items = branchItems(branch, humanInputs);
    if (!items) return;
    observed.add(kind);
    queue.push({ kind, payload: {
      ...fields,
      session_id: ctx.sessionManager.getSessionId(),
      turn_id: user.id,
      transcript_items: items,
    } });
    dispatchNext();
  }

  pi.on("tool_call", (event, ctx) => {
    // A failure in a tool_call hook would otherwise stop the question.
    try {
      if (
        questionTools.has(event.toolName) && !event.parentToolCallId &&
        typeof event.input.question === "string"
      ) {
        observe("question", {
          hook_event_name: "PreToolUse",
          tool_name: event.toolName,
          tool_input: { question: event.input.question },
        }, ctx, ctx.sessionManager.getBranch());
      }
    } catch {
      // Observation must leave the original question alone.
    }
  });

  // This notification fires once Pi has settled, even when the user aborts.
  pi.on("agent_settled", (event, ctx) => {
    const branch = ctx.sessionManager.getBranch();
    attestInput(branch);
    if (!event.aborted) {
      const lastMessage = branch.findLast((node) => node.type === "message");
      if (lastMessage?.type === "message" && lastMessage.message.role === "assistant") {
        const answer = text(lastMessage.message.content);
        if (answer && lastMessage.message.stopReason === "stop") {
          observe("stop", { hook_event_name: "Stop", last_assistant_message: answer }, ctx, branch);
        }
      }
    }
    active = undefined;
  });
}
