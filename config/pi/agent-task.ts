import { realpathSync } from "node:fs";
import { isAbsolute } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function currentTask(cwd: string) {
  const {
    AGENT_TASK_NAME: name,
    AGENT_TASK_ROOT: root,
    AGENT_TASK_ARTIFACTS: artifacts,
    AGENT_TASK_GOAL: goal,
  } = process.env;
  if (!name || !root || !artifacts || !isAbsolute(root) || !isAbsolute(artifacts)) {
    return undefined;
  }

  // Pi can switch sessions while staying in the same OS process.
  try {
    return realpathSync(cwd) === root ? { name, artifacts, goal } : undefined;
  } catch {
    return undefined;
  }
}

export default function (pi: ExtensionAPI) {
  pi.on("before_agent_start", (event, ctx) => {
    const goal = currentTask(ctx.cwd)?.goal;
    if (goal) {
      event.systemPromptOptions.promptGuidelines = [
        ...(event.systemPromptOptions.promptGuidelines ?? []),
        `User-provided completion criteria for this task: ${JSON.stringify(goal)}. Check completed work against these criteria when reporting progress.`,
      ];
    }
  });

  pi.on("session_start", (_event, ctx) => {
    const task = currentTask(ctx.cwd);
    if (ctx.hasUI) {
      const label = task ? `Task: ${task.name}${task.goal ? " (goal set)" : ""}` : undefined;
      ctx.ui.setStatus("agent-task", label);
    }
  });

  pi.on("before_agent_start", (event, ctx) => {
    const task = currentTask(ctx.cwd);
    if (!task) return;
    return {
      systemPrompt: [
        event.systemPrompt,
        `Current task: ${JSON.stringify(task.name)}`,
        `Keep task artifacts that the user may reopen (previews, reports, and validation logs) in ${JSON.stringify(task.artifacts)}. Use file names that describe the contents.`,
      ].join("\n\n"),
    };
  });
}
