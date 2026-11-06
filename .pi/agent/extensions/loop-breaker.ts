/**
 * Loop breaker for degenerate reasoning repetition.
 *
 * DeepSeek-V4-Flash-0731 (the checkpoint Mimir serves) probabilistically
 * collapses in long tool-heavy sessions: at the point a tool call or answer
 * should be emitted it repeats a short action announcement ("Let me write.",
 * "Run.") in the reasoning channel until the whole output budget is gone,
 * returning finish_reason=length with NO visible content. Pi sees a normal
 * "length" stop, so nothing recovers it — the turn just ends.
 *
 * Signature (measured across 31 recorded occurrences, all identical):
 *   role assistant, stopReason 'length', zero visible text, thinking present.
 *
 * Response: drop the degenerate assistant entry from model context (feeding a
 * ~400k-char loop back makes recurrence more likely), then ask for exactly one
 * more request. If the same collapse survives MAX_RETRIES re-asks, turn
 * thinking off instead: re-asking the same way is what already failed, and
 * thinking-off is the mitigation reported for this checkpoint.
 *
 * thinking_token_budget is NOT used: mimir's vLLM accepts and ignores it
 * (probe: budget 2000 -> 3250 reasoning tokens), and thinking mode ignores
 * temperature/presence_penalty/frequency_penalty too. There is no config-only
 * fix, which is why this is an extension.
 *
 * The escalation target is deliberately `off` and not a step down a ladder:
 * mimir's thinkingLevelMap sends no reasoning_effort at all for `medium` and
 * `minimal`, so stepping onto those is not a reliable reduction.
 */

import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const MAX_RETRIES = 2;

/**
 * True when the message is the degenerate length-loop: the model burned its
 * entire output budget in the thinking channel and emitted no answer.
 */
export function isDegenerateLengthStop(message: unknown): boolean {
	const m = message as AssistantMessage | undefined;
	if (!m || m.role !== "assistant") return false;
	if (m.stopReason !== "length") return false;

	const blocks = Array.isArray(m.content) ? m.content : [];
	// A truncated tool call already ran, and its tool_result is persisted.
	// Dropping the assistant message that produced it would orphan that
	// result, so a length stop with a tool call is recoverable, never degenerate.
	if (blocks.some((b) => b.type === "toolCall")) return false;

	const visible = blocks.some((b) => b.type === "text" && b.text.trim().length > 0);
	const thinking = blocks.some((b) => b.type === "thinking" && b.thinking.trim().length > 0);

	return !visible && thinking;
}

/** The entries this extension proposes when it drops a degenerate message. */
function collapseEntries(messageEntryId: string) {
	return [
		{
			type: "custom_message" as const,
			customType: "loop-breaker",
			content:
				"[The previous response collapsed into a repeated reasoning loop and produced no answer. " +
				"Its content has been removed. Continue the task: either emit the next tool call or give the answer.]",
			display: false,
		},
		{ type: "context_edit" as const, targetId: messageEntryId, replacement: null },
	];
}

export default function (pi: ExtensionAPI) {
	let retries = 0;
	// Thinking level in effect before the escalation switched it off, so it can
	// be restored once the collapse clears.
	// shortcut: a session that was already persisted with level `off` cannot be
	// told apart from one this extension turned off, so restore is skipped for
	// it; upgrade by recording the pre-off level in session history.
	let restoreLevel: string | null = null;

	// Make the extension's presence verifiable. Without this there is no
	// positive signal that it loaded — the only other evidence would be a
	// collapse it happened to recover, and "nothing happened" is
	// indistinguishable from "never loaded". session_start carries
	// reason: "reload" so /reload is provable too.
	pi.on("session_start", (event, ctx) => {
		pi.appendEntry("loop-breaker", { action: "loaded", reason: event.reason, thinking: pi.getThinkingLevel() });
		if (ctx.hasUI) {
			ctx.ui.notify(`Loop breaker active (${event.reason})`, "info");
		}
	});

	pi.registerCommand("loop-breaker", {
		description: "Report loop-breaker state (retries used, current thinking level)",
		handler: async (_args, ctx) => {
			const level = pi.getThinkingLevel();
			if (ctx.hasUI) {
				ctx.ui.notify(`Loop breaker: active, retries used ${retries}/${MAX_RETRIES}, thinking ${level}`, "info");
			}
		},
	});

	pi.on("turn_end", (event, ctx) => {
		if (!isDegenerateLengthStop(event.message)) {
			// A clean turn means the collapse cleared; re-arm the retry budget
			// and give the user their thinking level back.
			retries = 0;
			if (restoreLevel) {
				const level = restoreLevel;
				restoreLevel = null;
				pi.setThinkingLevel(level);
				pi.appendEntry("loop-breaker", { action: "thinking-restore", level });
				if (ctx.hasUI) {
					ctx.ui.notify(`Reasoning collapse cleared — thinking restored to ${level}`, "info");
				}
			}
			return;
		}

		if (retries >= MAX_RETRIES) {
			// Re-asking did not help. Change the decode instead of repeating it.
			if (pi.getThinkingLevel() !== "off") {
				restoreLevel = pi.getThinkingLevel();
				pi.setThinkingLevel("off");
				retries = 0;
				pi.appendEntry("loop-breaker", { action: "thinking-off" });
				if (ctx.hasUI) {
					ctx.ui.notify("Repeated reasoning collapse — thinking turned off", "warning");
				}
				// Keep the degenerate message out of context on this retry too,
				// but keep whatever earlier handlers proposed.
				return {
					entries: [...event.entries, ...collapseEntries(event.messageEntryId)],
					continue: true,
				};
			}
			// Thinking is already off and it still collapsed: stop retrying
			// rather than spin forever. The user sees the message and decides.
			if (ctx.hasUI) {
				ctx.ui.notify("Reasoning collapse persists with thinking off — stopping retries", "error");
			}
			return;
		}

		retries += 1;
		pi.appendEntry("loop-breaker", { action: "retry", attempt: retries });

		return {
			// Omit the degenerate message from model context. It is ~400k chars
			// of repeated text; replaying it invites the same collapse.
			entries: [...event.entries, ...collapseEntries(event.messageEntryId)],
			continue: true,
		};
	});
}
