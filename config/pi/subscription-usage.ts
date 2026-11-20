import { spawn } from "node:child_process";
import { homedir } from "node:os";
import { createInterface } from "node:readline";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type UsageWindow = {
  usedPercent: number;
  windowDurationMins: number | null;
  resetsAt: number | null;
};
type UsageLimits = { primary?: UsageWindow | null; secondary?: UsageWindow | null };

export function formatUsage(limits: UsageLimits, formatReset: (date: Date) => string): string {
  const windows = [limits.primary, limits.secondary].flatMap((window, index) => {
    if (!window || !Number.isFinite(window.usedPercent)) return [];
    const minutes = window.windowDurationMins;
    const label = !minutes ? (index === 0 ? "primary" : "secondary")
      : minutes % 1440 === 0 ? `${minutes / 1440}d`
      : minutes % 60 === 0 ? `${minutes / 60}h` : `${minutes}m`;
    const remaining = Math.max(0, Math.min(100, 100 - window.usedPercent));
    const reset = typeof window.resetsAt === "number" ? new Date(window.resetsAt * 1000) : null;
    return [`${label} ${remaining}% left${reset && Number.isFinite(reset.getTime()) ? ` (resets ${formatReset(reset)})` : ""}`];
  });
  return windows.length ? `Codex subscription: ${windows.join(" · ")}` : "Codex subscription: no limits reported";
}

export async function readUsage(codex: string, signal: AbortSignal): Promise<UsageLimits | null> {
  const child = spawn(codex, ["app-server", "--stdio"], {
    cwd: homedir(),
    stdio: ["pipe", "pipe", "ignore"],
    signal: AbortSignal.any([signal, AbortSignal.timeout(10_000)]),
  });
  // Error events (including cancellation) close the reader without logging app-server output.
  const lines = createInterface({ input: child.stdout, crlfDelay: Infinity });
  child.on("error", () => lines.close());
  child.stdin.on("error", () => lines.close());
  const send = (message: object) => child.stdin.write(`${JSON.stringify(message)}\n`);
  try {
    const responses = lines[Symbol.asyncIterator]();
    async function receive(id: number) {
      while (true) {
        const line = await responses.next();
        if (line.done) throw new Error("Codex app-server closed");
        const response = JSON.parse(line.value);
        if (response.id !== id) continue;
        if (!response.result || response.error) throw new Error("Codex app-server request failed");
        return response.result;
      }
    }
    send({ id: 1, method: "initialize", params: { clientInfo: { name: "pi_subscription_usage", version: "1" } } });
    await receive(1);
    send({ method: "initialized" });
    send({ id: 2, method: "account/read", params: { refreshToken: false } });
    const { account } = await receive(2);
    if (account?.type !== "chatgpt") return null;
    send({ id: 3, method: "account/rateLimits/read" });
    const { rateLimits } = await receive(3);
    if (!rateLimits || typeof rateLimits !== "object") throw new Error("Missing rate limits");
    return rateLimits;
  } finally {
    lines.close();
    child.stdin.end();
    child.kill();
  }
}

export function installSubscriptionUsage(pi: ExtensionAPI, codex: string) {
  let stop: (() => void) | undefined;
  pi.on("session_start", (_event, ctx) => {
    stop?.();
    if (!ctx.hasUI) return;
    const session = new AbortController();
    const resetFormat = new Intl.DateTimeFormat(undefined, {
      month: "numeric", day: "numeric", hour: "2-digit", minute: "2-digit",
    });
    const show = (text: string) => {
      if (!session.signal.aborted) ctx.ui.setStatus("codex-subscription", text);
    };
    let timer: ReturnType<typeof setTimeout>;
    async function refresh() {
      try {
        const limits = await readUsage(codex, session.signal);
        show(limits ? formatUsage(limits, (date) => resetFormat.format(date)) : "Codex subscription: ChatGPT login required");
      } catch {
        show("Codex subscription: usage unavailable");
      } finally {
        if (!session.signal.aborted) timer = setTimeout(refresh, 5 * 60_000);
      }
    }
    stop = () => {
      session.abort();
      clearTimeout(timer);
    };
    void refresh();
  });
  pi.on("session_shutdown", () => {
    stop?.();
    stop = undefined;
  });
}
