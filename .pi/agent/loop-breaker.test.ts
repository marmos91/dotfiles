/**
 * Runnable checks for the loop-breaker extension.
 *
 * The detector is also validated against every recorded session log:
 * 811 files, 31 length-stops, 31 flagged, 0 misses, 0 false positives.
 *
 *   node --test .pi/agent/loop-breaker.test.ts
 */

import assert from "node:assert/strict";
import { test } from "node:test";
import loopBreaker, { isDegenerateLengthStop } from "./extensions/loop-breaker.ts";

// ---------------------------------------------------------------- detector

const thinking = { type: "thinking", thinking: "Let me write. Now. Writing. ".repeat(50) };
const text = { type: "text", text: "Here is the answer." };
const blankText = { type: "text", text: "   \n  " };
const toolCall = { type: "toolCall", id: "t1", name: "bash", arguments: {} };

const msg = (stopReason: string, content: unknown[]) => ({ role: "assistant", stopReason, content });

test("detects the measured collapse: length stop, thinking only", () => {
	assert.equal(isDegenerateLengthStop(msg("length", [thinking])), true);
});

test("treats whitespace-only text as no answer", () => {
	assert.equal(isDegenerateLengthStop(msg("length", [thinking, blankText])), true);
});

test("ignores a length stop that produced an answer", () => {
	assert.equal(isDegenerateLengthStop(msg("length", [thinking, text])), false);
});

test("ignores ordinary completions", () => {
	assert.equal(isDegenerateLengthStop(msg("stop", [thinking])), false);
	assert.equal(isDegenerateLengthStop(msg("toolUse", [thinking, toolCall])), false);
});

test("ignores non-assistant and malformed messages", () => {
	assert.equal(isDegenerateLengthStop({ role: "user", content: [thinking], stopReason: "length" }), false);
	assert.equal(isDegenerateLengthStop(undefined), false);
	assert.equal(isDegenerateLengthStop(msg("length", [])), false);
});

// ----------------------------------------------------------------- handler

function harness(thinkingLevel = "high") {
	const handlers: Record<string, (e: any, c: any) => any> = {};
	const notes: string[] = [];
	const entries: { t: string; d: any }[] = [];
	const pi: any = {
		on: (ev: string, h: (e: any, c: any) => any) => {
			handlers[ev] = h;
		},
		appendEntry: (t: string, d: any) => entries.push({ t, d }),
	};
	let level = thinkingLevel;
	const ctx: any = {
		hasUI: true,
		ui: { notify: (m: string) => notes.push(m) },
		getThinkingLevel: () => level,
		setThinkingLevel: (l: string) => {
			level = l;
		},
	};
	loopBreaker(pi);
	return {
		fire: (m: any) => handlers.turn_end({ message: m, messageEntryId: "e1" }, ctx),
		entries,
		level: () => level,
	};
}

const loop = { role: "assistant", stopReason: "length", content: [{ type: "thinking", thinking: "Let me write. ".repeat(100) }] };
const ok = { role: "assistant", stopReason: "stop", content: [{ type: "text", text: "done" }] };

test("retries the collapse, dropping the degenerate entry from context", () => {
	const h = harness();
	const r = h.fire(loop);
	assert.equal(r.continue, true);
	assert.equal(r.entries.length, 2);
	const edit = r.entries.find((e: any) => e.type === "context_edit");
	assert.deepEqual(edit, { type: "context_edit", targetId: "e1", replacement: null });
	assert.equal(r.entries.find((e: any) => e.type === "custom_message").display, false);
	assert.equal(h.level(), "high", "does not lower thinking on the first retry");
});

test("a clean turn re-arms the retry budget", () => {
	const h = harness();
	h.fire(loop);
	h.fire(ok);
	h.fire(loop);
	assert.equal(h.entries.filter((e) => e.d.action === "retry").length, 2);
});

test("after repeated collapses it turns thinking off instead of re-asking", () => {
	const h = harness("high");
	h.fire(loop);
	h.fire(loop); // exhaust the retry budget
	const r = h.fire(loop); // third collapse escalates
	assert.equal(h.level(), "off");
	assert.equal(r.continue, true, "still continues so the thinking-off retry actually runs");
	assert.equal(r.entries, undefined, "escalation does not re-drop entries");
	assert.equal(h.entries.at(-1)?.d.action, "thinking-off");
});

test("stops retrying once thinking is already off", () => {
	const h = harness("off");
	h.fire(loop);
	h.fire(loop);
	assert.equal(h.fire(loop), undefined, "no continuation is requested at the bottom of the ladder");
	assert.equal(h.level(), "off");
});

test("ignores ordinary messages entirely", () => {
	const h = harness();
	assert.equal(h.fire(ok), undefined);
	assert.equal(h.entries.length, 0);
});
