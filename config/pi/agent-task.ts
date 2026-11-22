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

function taskGuidelines(task: ReturnType<typeof currentTask>): string[] {
  return [
    ...(task?.goal ? [
      `User-provided completion criteria for this task: ${JSON.stringify(task.goal)}. Check completed work against these criteria when reporting progress.`,
    ] : []),
    "Use rg (ripgrep) to search text from the shell. Pi's grep tool also uses ripgrep.",
    ...(task ? [
      `Current task: ${JSON.stringify(task.name)}. Keep previews, reports, and validation logs in ${JSON.stringify(task.artifacts)}. Use file names that describe the contents.`,
    ] : []),
  ];
}

export default function (pi: ExtensionAPI) {
  pi.on("before_agent_start", (event, ctx) => {
    event.systemPromptOptions.promptGuidelines = [
      ...(event.systemPromptOptions.promptGuidelines ?? []),
      ...taskGuidelines(currentTask(ctx.cwd)),
    ];
  });

  pi.on("session_start", (_event, ctx) => {
    const task = currentTask(ctx.cwd);
    if (ctx.hasUI) {
      const label = task ? `Task: ${task.name}${task.goal ? " (goal set)" : ""}` : undefined;
      ctx.ui.setStatus("agent-task", label);
    }
  });
}
