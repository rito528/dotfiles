import assert from "node:assert/strict";
import { mkdtemp, mkdir, realpath, rm, symlink, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import readOnly from "../../config/pi/subagent/read-only.ts";

test("the subagent can read only inside the checkout through read-only tools", async (t) => {
  const fixture = await realpath(await mkdtemp(join(tmpdir(), "pi-subagent-")));
  t.after(() => rm(fixture, { recursive: true, force: true }));
  const cwd = join(fixture, "checkout");
  await mkdir(cwd);
  const nearbyFile = join(fixture, "outside.txt");
  await writeFile(nearbyFile, "outside the checkout");
  await writeFile(join(cwd, "inside.txt"), "inside the checkout");
  await symlink(nearbyFile, join(cwd, "outside-link.txt"));

  let onToolCall;
  readOnly({ on: (_event, handler) => { onToolCall = handler; } });
  const call = (toolName, path) => onToolCall({ toolName, input: { path } }, { cwd });
  assert.equal(await call("read", "inside.txt"), undefined);
  assert.equal((await call("write", "inside.txt")).block, true);
  assert.equal((await call("read", "../outside.txt")).block, true);
  assert.equal((await call("read", "outside-link.txt")).block, true);

  // Pi would turn the non-breaking space into ASCII and open the other path.
  await writeFile(join(cwd, "lookalike\u00a0path"), "inside the checkout");
  await symlink(nearbyFile, join(cwd, "lookalike path"));
  assert.equal((await call("read", "lookalike\u00a0path")).block, true);
});
