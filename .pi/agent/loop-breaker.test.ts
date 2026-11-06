/**
 * Runnable checks for the loop-breaker extension.
 *
 * The fixtures are synthetic: a collapsed message is a `thinking` block of
 * repeated text with no visible output, and a clean one carries text or a tool
 * call. They are not a replay of recorded sessions.
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
	// A length stop's tool calls are failed, not executed, but their error
	// tool-results are still persisted, so the message cannot be dropped.
	assert.equal(isDegenerateLengthStop(msg("length", [thinking, toolCall])), false);
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
	const commands: Record<string, (a: string, c: any) => any> = {};
	let level = thinkingLevel;
	const pi: any = {
		on: (ev: string, h: (e: any, c: any) => any) => {
			handlers[ev] = h;
		},
		appendEntry: (t: string, d: any) => entries.push({ t, d }),
		registerCommand: (n: string, o: any) => {
			commands[n] = o.handler;
		},
		getThinkingLevel: () => level,
		setThinkingLevel: (l: string) => {
			const previousLevel = level;
			level = l;
			// Mirrors agent-session: the event is emitted asynchronously.
			handlers.thinking_level_select?.({ level, previousLevel }, ctx);
		},
	};
	const ctx: any = {
		hasUI: true,
		ui: { notify: (m: string) => notes.push(m) },
		thinkingLevel,
	};
	loopBreaker(pi);
	return {
		fire: (m: any, proposed: any[] = []) =>
			handlers.turn_end({ message: m, messageEntryId: "e1", entries: proposed }, ctx),
		start: (reason = "startup") => handlers.session_start({ type: "session_start", reason }, ctx),
		select: (l: string) => {
			const previousLevel = level;
			level = l;
			handlers.thinking_level_select({ level, previousLevel }, ctx);
		},
		command: (n: string) => commands[n],
		notes,
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
	assert.equal(r.entries.length, 2, "the degenerate message must not be replayed on the escalation retry");
	assert.ok(r.entries.some((e: any) => e.type === "context_edit" && e.targetId === "e1"));
	assert.ok(r.entries.some((e: any) => e.type === "custom_message" && e.customType === "loop-breaker"));
	assert.equal(h.entries.at(-1)?.d.action, "thinking-off");
});

test("a clean turn restores the thinking level after escalation", () => {
	const h = harness("high");
	h.fire(loop);
	h.fire(loop);
	h.fire(loop); // escalate
	assert.equal(h.level(), "off");

	h.fire(ok);
	assert.equal(h.level(), "high", "the level the user chose must come back");
	assert.deepEqual(h.entries.at(-1)?.d, { action: "thinking-restore", level: "high" });
	assert.ok(h.notes.some((n) => n.includes("restored")));
});

test("a user level change mid-collapse wins over the pending restore", () => {
	const h = harness("high");
	h.fire(loop);
	h.fire(loop);
	h.fire(loop); // escalate to off
	assert.equal(h.level(), "off");

	h.select("xhigh"); // user overrides while the collapse is being retried
	h.fire(ok);
	assert.equal(h.level(), "xhigh", "the user's choice must not be clobbered back to high");
	assert.ok(!h.entries.some((e) => e.d.action === "thinking-restore"));
});

test("keeps entries proposed by earlier turn_end handlers", () => {
	const earlier = { type: "custom_message", customType: "other-extension", content: "keep me" };
	const h = harness();
	const r = h.fire(loop, [earlier]);
	assert.deepEqual(r.entries[0], earlier, "a previously-registered handler's entry must survive");

	h.fire(loop);
	const escalated = h.fire(loop, [earlier]);
	assert.deepEqual(escalated.entries[0], earlier, "the escalation retry must not drop it either");
	assert.equal(escalated.entries.length, 3);
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

// ------------------------------------------------------------------- wiring

test("records a load marker carrying the session_start reason", () => {
	const h = harness("high");
	h.start("reload");
	assert.deepEqual(h.entries.at(-1)?.d, { action: "loaded", reason: "reload", thinking: "high" });
	assert.ok(h.notes.some((n) => n.includes("reload")), "notifies the user that it is active");
});

test("registers a status command", () => {
	const h = harness();
	assert.equal(typeof h.command("loop-breaker"), "function");
	h.command("loop-breaker")("", { hasUI: true, ui: { notify: (m: string) => h.notes.push(m) } });
	assert.ok(h.notes.some((n) => n.includes("active")), "command reports active state");
});
