import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

export function installQuestionTool(pi: ExtensionAPI) {
  pi.registerTool({
    name: "request_user_input",
    label: "Ask the user",
    description: "Ask one short question when the answer affects the work. Wait for the answer or cancellation.",
    parameters: Type.Object({
      question: Type.String({ minLength: 1, maxLength: 2_000 }),
    }),
    async execute(_id, { question }, signal, _update, ctx) {
      if (!ctx.hasUI) throw new Error("Interactive input is not available in this session.");
      const answer = await ctx.ui.input(question, undefined, { signal });
      return {
        content: [{ type: "text", text: answer === undefined ? "The user cancelled the question." : answer }],
        details: { cancelled: answer === undefined },
      };
    },
  });
}
