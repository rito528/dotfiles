import { realpathSync } from "node:fs";
import { isAbsolute } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function currentTask(cwd: string) {
  const {
    AGENT_TASK_NAME: name,
    AGENT_TASK_ROOT: root,
    AGENT_TASK_ARTIFACTS: artifacts,
  } = process.env;
  if (!name || !root || !artifacts || !isAbsolute(root) || !isAbsolute(artifacts)) {
    return undefined;
  }

  // Pi can switch sessions while staying in the same OS process.
  try {
    return realpathSync(cwd) === root ? { name, artifacts } : undefined;
  } catch {
    return undefined;
  }
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    const task = currentTask(ctx.cwd);
    if (ctx.hasUI) {
      ctx.ui.setStatus("agent-task", task ? `Task: ${task.name}` : undefined);
    }
  });

  pi.on("before_agent_start", (event, ctx) => {
    const task = currentTask(ctx.cwd);
    const guidelines = event.systemPromptOptions.promptGuidelines ?? [];
    event.systemPromptOptions.promptGuidelines = [
      ...guidelines,
      "Use rg (ripgrep) to search text from the shell. Pi's grep tool also uses ripgrep.",
    ];
    if (task) {
      event.systemPromptOptions.promptGuidelines.push(
        `Current task: ${JSON.stringify(task.name)}. Keep previews, reports, and validation logs in ${JSON.stringify(task.artifacts)}. Use file names that describe the contents.`,
      );
    }
  });
}
