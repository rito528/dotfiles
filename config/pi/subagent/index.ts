import { fileURLToPath } from "node:url";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const readOnlyExtension = fileURLToPath(new URL("./read-only.ts", import.meta.url));

function finalAnswer(output: string): string {
  let answer = "";
  for (const line of output.split("\n")) {
    if (!line.trim()) continue;
    const event = JSON.parse(line);
    const message = event.message;
    if (event.type === "message_end" && message?.role === "assistant") {
      answer = message.stopReason === "stop"
        ? message.content
            .filter((block: { type: string }) => block.type === "text")
            .map((block: { text: string }) => block.text)
            .join("\n")
        : "";
    }
  }
  if (!answer.trim()) throw new Error("Subagent did not return a final answer.");
  return answer;
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "subagent",
    label: "Read-only subagent",
    description: "Delegate an independent investigation or review to OpenAI. Give it a self-contained task; it has no parent conversation, editing tools, shell, or MCP tools. Its grep tool uses ripgrep.",
    parameters: Type.Object({
      task: Type.String({ minLength: 1, maxLength: 12_000 }),
    }),
    async execute(_id, { task }, signal, _onUpdate, ctx) {
      if (ctx.model?.provider !== "openai") {
        throw new Error("Select an OpenAI model in Pi before using the subagent.");
      }

      // Home Manager deploys the standalone binary, so use the running Pi version.
      const result = await pi.exec(process.execPath, [
        "--mode", "json", "--no-session", "--offline", "--no-extensions", "--no-mcp",
        "--no-skills", "--no-context-files", "--no-approve",
        "--extension", readOnlyExtension,
        "--tools", "read,grep,find,ls",
        "--provider", "openai", "--model", ctx.model.id,
        "--append-system-prompt",
        "You are an independent, read-only reviewer. Prefer grep (ripgrep) to search file contents. Return findings with file and line references.",
        "--", `Independent investigation request:\n${task}`,
      ], { cwd: ctx.cwd, signal, timeout: 180_000, maxBuffer: 2 * 1024 * 1024 });

      if (result.code !== 0 || result.truncated || result.killed) {
        throw new Error("Subagent did not complete. Check the OpenAI login or try a smaller task.");
      }
      return { content: [{ type: "text", text: finalAnswer(result.stdout) }], details: {} };
    },
  });
}
