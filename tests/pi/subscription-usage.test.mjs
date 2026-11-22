import assert from "node:assert/strict";
import { test } from "node:test";
import { formatUsage } from "../../config/pi/subscription-usage.ts";

const isoReset = (date) => date.toISOString();

test("usage labels follow window duration and percentages stay within bounds", () => {
  assert.equal(formatUsage({
    primary: { usedPercent: 105, windowDurationMins: 300, resetsAt: 0 },
    secondary: { usedPercent: -5, windowDurationMins: 10080, resetsAt: NaN },
  }, isoReset), "Codex subscription: 5h 0% left (resets 1970-01-01T00:00:00.000Z) · 7d 100% left");
});

test("an absent primary window does not relabel the secondary window", () => {
  assert.equal(formatUsage({
    secondary: { usedPercent: 42, windowDurationMins: null, resetsAt: null },
  }, isoReset), "Codex subscription: secondary 58% left");
});
