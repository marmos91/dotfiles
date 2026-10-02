/**
 * Ask User Extension
 *
 * Registers an `ask_user` tool that pauses the turn and prompts for a choice
 * between discrete options — the structured-question equivalent of Claude
 * Code's AskUserQuestion, which pi has no built-in for.
 *
 * Deliberately narrow. It is for decisions with a small set of discrete
 * answers, where guessing wrong wastes real work. Everything else stays plain
 * text at the end of a turn, which is pi's native pattern and lets the user
 * answer freely rather than pick from a list.
 *
 * The `parameters` schema is written as a plain JSON Schema object rather than
 * a TypeBox `Type.Object(...)`. TypeBox schemas *are* JSON Schema, so this is
 * the same wire format with no import — which matters because `typebox` is a
 * pi-internal dependency and is not resolvable from ~/.pi/agent, so importing
 * it would make this file untestable outside pi.
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

/** More than this and a terminal selector stops being a choice and starts being a menu. */
const MAX_OPTIONS = 6;

/**
 * Trim, drop blanks and duplicates, and cap the list.
 * Returns [] when fewer than two usable options remain, since a one-option
 * question is not a question.
 */
export function normalizeOptions(raw: unknown): string[] {
	if (!Array.isArray(raw)) return [];
	const seen = new Set<string>();
	const out: string[] = [];
	for (const item of raw) {
		if (typeof item !== "string") continue;
		const trimmed = item.trim();
		if (!trimmed || seen.has(trimmed)) continue;
		seen.add(trimmed);
		out.push(trimmed);
		if (out.length >= MAX_OPTIONS) break;
	}
	return out.length >= 2 ? out : [];
}

/**
 * What to return when no interactive UI is attached (print, rpc, json, or a
 * subagent). Returning a result instead of awaiting a dialog is what keeps
 * headless runs from deadlocking on a prompt nobody can see.
 */
export function nonUiResult(question: string, options: string[]): string {
	return [
		`Cannot prompt: no interactive UI is attached to this session.`,
		`Question was: ${question}`,
		`Options were: ${options.map((o, i) => `${i + 1}. ${o}`).join("  ")}`,
		`Ask this in plain text at the end of your turn instead, and let the user answer freely.`,
	].join("\n");
}

export const ASK_PARAMS = {
	type: "object",
	properties: {
		question: {
			type: "string",
			description: "The decision to put to the user. One sentence, ending in a question mark.",
		},
		options: {
			type: "array",
			items: { type: "string" },
			minItems: 2,
			maxItems: MAX_OPTIONS,
			description:
				"Two to six mutually exclusive answers. Each must be self-contained, since the user sees only these strings and not the surrounding conversation.",
		},
		header: {
			type: "string",
			description: "Optional short label for the question, shown above the options.",
		},
	},
	required: ["question", "options"],
	additionalProperties: false,
} as const;

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "ask_user",
		label: "Ask user",
		description:
			"Pause and ask the user to choose one of a few discrete options. Blocks until they answer. Use only for decisions with a small set of discrete answers, or when the user explicitly asks to be prompted. Do NOT use it to ask for confirmation, for open-ended questions, or for anything answerable from the repository.",
		promptSnippet:
			"Ask the user to choose between discrete options when a decision has a small, closed set of answers",
		promptGuidelines: [
			"Use ask_user only when the user explicitly asks to be prompted, or when a decision has a small set of discrete options and choosing wrong would waste significant work.",
			"Otherwise, ask in plain text at the end of the turn — that is pi's normal pattern and lets the user answer freely.",
			"Never use ask_user for confirmation or permission; those are the harness's job, not a question.",
		],
		parameters: ASK_PARAMS,
		// One dialog at a time: two concurrent prompts would fight over the terminal.
		executionMode: "sequential",
		async execute(_toolCallId, params, signal, _onUpdate, ctx: ExtensionContext) {
			const question = String(params.question ?? "").trim();
			const options = normalizeOptions(params.options);

			if (!question) {
				return {
					content: [{ type: "text", text: "ask_user called with no question." }],
					details: { error: "empty_question" },
					isError: true,
				};
			}
			if (options.length === 0) {
				return {
					content: [
						{
							type: "text",
							text: `ask_user needs at least two distinct options; got ${JSON.stringify(params.options)}.`,
						},
					],
					details: { error: "insufficient_options" },
					isError: true,
				};
			}

			// Headless: answer with instructions instead of blocking on a dialog
			// that cannot be shown.
			if (!ctx.hasUI) {
				return {
					content: [{ type: "text", text: nonUiResult(question, options) }],
					details: { prompted: false, reason: "no_ui" },
				};
			}

			const title = params.header ? `${params.header}\n${question}` : question;
			const choice = await ctx.ui.select(title, options, { signal });

			if (choice === undefined) {
				return {
					content: [{ type: "text", text: "The user dismissed the question without choosing." }],
					details: { prompted: true, dismissed: true },
				};
			}

			return {
				content: [{ type: "text", text: `User selected: ${choice}` }],
				details: { prompted: true, choice },
			};
		},
	});
}
