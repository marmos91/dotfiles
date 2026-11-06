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

test("normalizeOptions strips ESC sequences and control characters", () => {
	assert.deepEqual(normalizeOptions(["\x1b[31mRed\x1b[0m", "\x1b]52;c;aGk=\x07Blue"]), ["Red", "Blue"]);
	assert.deepEqual(normalizeOptions(["a\x00b", "c"]), ["ab", "c"]);
	assert.deepEqual(normalizeOptions(["\x1b[31m\x1b[0m", "b"]), [], "a fully stripped option is a blank option");
});

test("nonUiResult names the question and every option, and points at plain text", () => {
	const s = nonUiResult("Ship it?", ["Yes", "No"]);
	assert.ok(s.includes("Ship it?"));
	assert.ok(s.includes("1. Yes"));
	assert.ok(s.includes("2. No"));
	assert.ok(s.includes("plain text"), "must tell the model what to do instead");
});

// ------------------------------------------------------------ wiring

function harness(
	{
		hasUI = true,
		choice,
		signal,
	}: { hasUI?: boolean; choice?: string | undefined; signal?: AbortSignal } = {},
) {
	const registered: any[] = [];
	const selects: { title: string; options: string[] }[] = [];

	const pi: any = {
		registerTool: (t: any) => registered.push(t),
	};
	const ctx: any = {
		hasUI,
		ui: {
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
		registered,
		selects,
		run: (params: any) => tool.execute("call-1", params, signal, undefined, ctx),
	};
}

test("registers exactly one ask_user tool, marked sequential", () => {
	const h = harness();
	assert.equal(h.registered.length, 1, "a second registration would shadow the first");
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
	for (const [name, prop] of Object.entries(ASK_PARAMS.properties)) {
		assert.equal(typeof prop, "object", `${name} must be an object schema`);
		assert.ok("type" in prop, `${name} must declare a type`);
	}
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

test("an aborted signal is an error, not a dismissal", async () => {
	const h = harness({ choice: undefined, signal: AbortSignal.abort() });
	const r = await h.run({ question: "Which?", options: ["a", "b"] });
	assert.equal(r.isError, true, "an abort must be visible to the caller");
	assert.equal(r.details.aborted, true);
	assert.equal(r.details.dismissed, undefined);
	assert.ok(!r.content[0].text.toLowerCase().includes("dismissed"), "the user never saw the question");
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

test("escape sequences never reach the dialog, the result, or the headless text", async () => {
	const evil = { header: "H\x1b]0;spoof\x07", question: "Deploy\x1b[2J?", options: ["Ok\x1b]52;c;aGk=\x07", "No\x1b[2J"] };
	const h = harness({ choice: "Ok" });
	const r = await h.run(evil);
	assert.deepEqual(h.selects[0], { title: "H\nDeploy?", options: ["Ok", "No"] });
	assert.equal(r.content[0].text, "User selected: Ok");

	const headless = await harness({ hasUI: false }).run(evil);
	assert.doesNotMatch(headless.content[0].text, /[\x1b\x07]/);
	assert.ok(headless.content[0].text.includes("Deploy?"));
});
