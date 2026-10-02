/**
 * Tests for the ask-user extension.
 *
 * Imports the extension directly. It works outside pi because every import is
 * type-only (erased by type-stripping) and the parameter schema is hand-written
 * JSON Schema rather than a TypeBox import, which is not resolvable here.
 */

import assert from "node:assert/strict";
import test from "node:test";

import askUser, { ASK_PARAMS, nonUiResult, normalizeOptions } from "./extensions/ask-user.ts";

// ------------------------------------------------------------ pure helpers

test("normalizeOptions trims, drops blanks and duplicates, and caps the list", () => {
	assert.deepEqual(normalizeOptions(["  a  ", "b"]), ["a", "b"]);
	assert.deepEqual(normalizeOptions(["a", "a", "b"]), ["a", "b"]);
	assert.deepEqual(normalizeOptions(["a", "", "   ", "b"]), ["a", "b"]);
	assert.deepEqual(normalizeOptions(["1", "2", "3", "4", "5", "6", "7", "8"]).length, 6);
});

test("normalizeOptions rejects anything that is not two distinct strings", () => {
	assert.deepEqual(normalizeOptions(undefined), []);
	assert.deepEqual(normalizeOptions("a,b"), []);
	assert.deepEqual(normalizeOptions([1, 2]), []);
	assert.deepEqual(normalizeOptions(["only"]), [], "one option is not a question");
	assert.deepEqual(normalizeOptions(["a", "a"]), [], "duplicates collapse to one option");
});

test("nonUiResult names the question and every option, and points at plain text", () => {
	const s = nonUiResult("Ship it?", ["Yes", "No"]);
	assert.ok(s.includes("Ship it?"));
	assert.ok(s.includes("1. Yes"));
	assert.ok(s.includes("2. No"));
	assert.ok(s.includes("plain text"), "must tell the model what to do instead");
});

// ------------------------------------------------------------ wiring

function harness({ hasUI = true, choice }: { hasUI?: boolean; choice?: string | undefined } = {}) {
	const notes: string[] = [];
	const registered: any[] = [];
	const selects: { title: string; options: string[] }[] = [];

	const pi: any = {
		registerTool: (t: any) => registered.push(t),
	};
	const ctx: any = {
		hasUI,
		ui: {
			notify: (m: string) => notes.push(m),
			select: async (title: string, options: string[]) => {
				selects.push({ title, options });
				return choice;
			},
		},
	};

	askUser(pi);
	const tool = registered[0];
	return {
		tool,
		notes,
		selects,
		run: (params: any) => tool.execute("call-1", params, undefined, undefined, ctx),
	};
}

test("registers exactly one ask_user tool, marked sequential", () => {
	const h = harness();
	assert.equal(h.tool.name, "ask_user");
	assert.equal(h.tool.executionMode, "sequential", "two dialogs must not race for the terminal");
	assert.ok(h.tool.promptSnippet, "without a snippet the tool is hidden from the system prompt");
});

test("the schema stays valid JSON Schema, since typebox is not importable here", () => {
	assert.equal(ASK_PARAMS.type, "object");
	assert.deepEqual(ASK_PARAMS.required, ["question", "options"]);
	assert.equal(ASK_PARAMS.additionalProperties, false);
	assert.equal(ASK_PARAMS.properties.options.minItems, 2);
	assert.equal(ASK_PARAMS.properties.options.maxItems, 6);
});

test("a valid question prompts and returns the chosen option", async () => {
	const h = harness({ choice: "Use Postgres" });
	const r = await h.run({ question: "Which store?", options: ["Use Postgres", "Use SQLite"] });
	assert.equal(r.details.choice, "Use Postgres");
	assert.ok(r.content[0].text.includes("Use Postgres"));
	assert.equal(h.selects.length, 1);
	assert.deepEqual(h.selects[0].options, ["Use Postgres", "Use SQLite"]);
});

test("header is prefixed onto the dialog title", async () => {
	const h = harness({ choice: "a" });
	await h.run({ question: "Which?", options: ["a", "b"], header: "Storage" });
	assert.ok(h.selects[0].title.startsWith("Storage"), "header should label the question");
	assert.ok(h.selects[0].title.includes("Which?"));
});

test("a dismissed dialog reports the dismissal instead of inventing an answer", async () => {
	const h = harness({ choice: undefined });
	const r = await h.run({ question: "Which?", options: ["a", "b"] });
	assert.equal(r.details.dismissed, true);
	assert.equal(r.details.choice, undefined);
	assert.ok(r.content[0].text.toLowerCase().includes("dismissed"));
});

test("headless mode never opens a dialog and tells the model to ask in plain text", async () => {
	const h = harness({ hasUI: false, choice: "should never be used" });
	const r = await h.run({ question: "Which?", options: ["a", "b"] });
	assert.equal(h.selects.length, 0, "must not call select without a UI");
	assert.equal(r.details.prompted, false);
	assert.equal(r.details.reason, "no_ui");
	assert.ok(r.content[0].text.includes("plain text"));
});

test("an empty question is an error, not a prompt", async () => {
	const h = harness();
	const r = await h.run({ question: "   ", options: ["a", "b"] });
	assert.equal(r.isError, true);
	assert.equal(h.selects.length, 0);
});

test("fewer than two usable options is an error, not a prompt", async () => {
	const h = harness();
	const r = await h.run({ question: "Which?", options: ["only"] });
	assert.equal(r.isError, true);
	assert.equal(r.details.error, "insufficient_options");
	assert.equal(h.selects.length, 0, "a one-option question must not reach the user");
});
