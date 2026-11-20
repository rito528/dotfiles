import { realpath } from "node:fs/promises";
import { isAbsolute, relative, resolve, sep } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const tools = new Set(["read", "grep", "find", "ls"]);
// The built-in tools normalize these spaces to ASCII after the hook.
const reinterpretedSpaces = /[\u00A0\u2000-\u200A\u202F\u205F\u3000]/;

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event, ctx) => {
    if (!tools.has(event.toolName)) return { block: true, reason: "Read-only subagent." };
    const requestedPath = event.input.path ?? ".";
    if (typeof requestedPath !== "string") {
      return { block: true, reason: "Provide a path in the current working directory." };
    }

    try {
      const root = await realpath(ctx.cwd);
      const target = await realpath(resolve(root, requestedPath));
      const within = relative(root, target);
      if (
        !reinterpretedSpaces.test(target) &&
        !isAbsolute(within) &&
        !within.split(sep).some((part) => part === ".." || part === ".git")
      ) {
        event.input.path = target;
        return;
      }
    } catch {
      // Unresolvable paths are outside the supported tool inputs.
    }

    return { block: true, reason: "Use an existing path within the current working directory." };
  });
}
