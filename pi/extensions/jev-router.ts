// Virtual `opencode-go/auto` model; routing rationale and benchmarks live in docs/decisions/jev-router.md.
import { uuidv7, type Message } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext, ModelRoute, ModelRouteRequest } from "@earendil-works/pi-coding-agent";
import { convertToLlm, serializeConversation } from "@earendil-works/pi-coding-agent";

const PROVIDER = "opencode-go" as const;

const STATUS_KEY = "jev-route";

let turnSessionLevel: string | undefined;

const MUSE = "muse-spark-1.3-contributor";
const MIMO_PRO = "mimo-v2.6-pro";
const DEEPSEEK = "deepseek-v4.1-flash";
const GLM_FLASH = "glm-5.3-flash";

const SHORT: Record<string, string> = {
	[MUSE]: "muse-1.3",
	[MIMO_PRO]: "mimo-2.6-pro",
	[DEEPSEEK]: "deepseek-v4.1",
	[GLM_FLASH]: "glm-5.3-flash",
};

const LEGACY_MIMO = "mimo-v2.6-flash";

type TargetId = typeof MUSE | typeof MIMO_PRO | typeof DEEPSEEK | typeof GLM_FLASH;

interface JevRouterState {
	target: TargetId;
	complexity: string;
	taskKind: string;
	probs?: Record<string, number>;
}

type Req = ModelRouteRequest<JevRouterState>;

function statusLabel(id: string, level: string, sessionLevel?: string): string {
	const base = SHORT[id] ?? id;
	const from = LEVELS.indexOf(sessionLevel as ThinkingLevel);
	const to = LEVELS.indexOf(level as ThinkingLevel);
	const delta = from < 0 || to < 0 || to === from ? "" : to > from ? "↑" : "↓";
	return `${base} [${level}${delta}]`;
}

export function routeTo(
	req: Req,
	ctx: ExtensionContext,
	id: TargetId,
	state?: JevRouterState,
	floor?: ThinkingLevel,
	ceiling?: ThinkingLevel,
): ModelRoute<JevRouterState> {
	const model = ctx.modelRegistry.find(PROVIDER, id);
	if (!model) throw new Error(`Model ${PROVIDER}/${id} not in catalog — check opencode-go auth / models-store.json`);
	const ui = (ctx as unknown as { ui?: { setStatus?: (k: string, v: string | undefined) => void } }).ui;
	let level = req.thinkingLevel;
	if (floor && LEVELS.indexOf(level as ThinkingLevel) < LEVELS.indexOf(floor)) level = floor;
	else if (ceiling && LEVELS.indexOf(level as ThinkingLevel) > LEVELS.indexOf(ceiling)) level = ceiling;
	level = snapToModel(level as ThinkingLevel, model as { thinkingLevelMap?: Record<string, unknown> });
	turnSessionLevel = req.thinkingLevel;
	try {
		ui?.setStatus?.(STATUS_KEY, statusLabel(id, level, req.thinkingLevel));
	} catch {}
	return { model, thinkingLevel: level, state };
}

function lastUserText(messages: readonly Message[]): string {
	const last = messages.filter((m) => m.role === "user").at(-1);
	if (!last?.content) return "";
	if (typeof last.content === "string") return last.content;
	return last.content
		.filter((b): b is { type: "text"; text: string } => b.type === "text")
		.map((b) => b.text)
		.join("\n");
}

const HARD_PATTERN =
	/\b(debug|race|deadlock|segfault|flaky|regression|architecture?|architectural|design|migrat\w*|trade-?offs?|optimi[sz]\w*|performance|refactor|root cause|why (?:does|is|doesn't|do))\b/i;

const RANK: Record<TargetId, number> = {
	[DEEPSEEK]: 1,
	[GLM_FLASH]: 2,
	[MUSE]: 3,
	[MIMO_PRO]: 0,
};

export interface RouteSignals {
	prompt: string;
	vision: boolean;
	codeFences: number;
	paths: number;
	toolErrors: number;
	edits: boolean;
}

export function readSignals(messages: readonly Message[], prompt: string): RouteSignals {
	const lastUser = messages.findLastIndex((m) => m.role === "user");
	const tail = lastUser >= 0 ? messages.slice(lastUser + 1) : [];
	const toolResults = tail.filter((m) => m.role === "toolResult");

	const lastUserMessage = messages[lastUser];
	const vision =
		Array.isArray(lastUserMessage?.content) &&
		lastUserMessage.content.some((b) => (b as { type?: string }).type === "image");

	return {
		prompt,
		vision,
		codeFences: (prompt.match(/```/g) ?? []).length >> 1,
		paths: new Set(prompt.match(/[~.]?\/?(?:[\w.-]+\/)+[\w.-]+/g) ?? []).size,
		toolErrors: toolResults.filter((m) => m.isError).length,
		edits: tail.some((m) => m.role === "toolResult" && !m.isError && (m.toolName === "edit" || m.toolName === "write")),
	};
}

function looksHard(signals: RouteSignals): boolean {
	return (
		signals.codeFences >= 2 ||
		signals.paths >= 3 ||
		(signals.prompt.length > 1200 && HARD_PATTERN.test(signals.prompt)) ||
		(HARD_PATTERN.test(signals.prompt) && signals.paths >= 2)
	);
}

export function pickTarget(taskKind: string, probs: Record<string, number>, signals: RouteSignals): TargetId {
	const taskRaw = taskKind.toLowerCase();
	const task = (probs[taskRaw] ?? 1) >= 0.4 ? taskRaw : "coding";

	// deepseek leaks tool calls as text, so it only gets turns where no tool work is expected.
	const textWork = (task === "chat" || task === "generation") && signals.toolErrors === 0 && !signals.edits;

	if (signals.vision) return GLM_FLASH;

	if (textWork) return DEEPSEEK;

	if (task === "reasoning") return GLM_FLASH;

	return MUSE;
}

const LEVELS = ["low", "medium", "high", "xhigh", "max"] as const;
export type ThinkingLevel = (typeof LEVELS)[number];

function snapToModel(level: ThinkingLevel, model: { thinkingLevelMap?: Record<string, unknown> }): ThinkingLevel {
	const map = model?.thinkingLevelMap;
	if (!map) return level;
	const supported = LEVELS.filter((l) => map[l] !== null && map[l] !== undefined);
	if (supported.length === 0 || supported.includes(level)) return level;
	const target = LEVELS.indexOf(level);
	let best: ThinkingLevel = supported[0]!;
	let bestDistance = Number.POSITIVE_INFINITY;
	for (const candidate of supported) {
		const distance = Math.abs(LEVELS.indexOf(candidate) - target);
		if (distance < bestDistance || (distance === bestDistance && LEVELS.indexOf(candidate) < LEVELS.indexOf(best))) {
			best = candidate;
			bestDistance = distance;
		}
	}
	return best;
}

export function effortBand(
	taskKind: string,
	complexity: string,
	probs: Record<string, number>,
	signals: RouteSignals,
): { floor?: ThinkingLevel; ceiling?: ThinkingLevel } {
	const c = complexity.toLowerCase();
	const level = (probs[c] ?? 1) >= 0.45 ? c : "standard";
	const taskRaw = taskKind.toLowerCase();
	const task = (probs[taskRaw] ?? 1) >= 0.4 ? taskRaw : "coding";

	if (looksHard(signals) || signals.toolErrors >= 2) return { floor: "xhigh" };

	switch (task) {
		case "chat":
		case "generation":
			if (level === "complex") return task === "chat" ? { floor: "high", ceiling: "xhigh" } : { floor: "high" };
			if (level === "trivial") return { floor: "low", ceiling: "low" };
			return { floor: task === "chat" ? "low" : "medium", ceiling: "medium" };
		case "reasoning":
			if (level === "complex") return { floor: "xhigh" };
			if (level === "trivial") return { floor: "medium", ceiling: "medium" };
			return { floor: "high" };
		default: {
			if (level === "complex") return { floor: "xhigh" };
			if (level === "trivial") return { floor: "low", ceiling: "low" };
			return { ceiling: "high" };
		}
	}
}

export function reconcile(previous: TargetId, next: TargetId, signals: RouteSignals): TargetId {
	if (previous === next) return next;
	if (signals.vision) return GLM_FLASH;
	if (previous === DEEPSEEK) return next;
	if (next === DEEPSEEK) return DEEPSEEK;
	if (signals.edits && previous === MIMO_PRO) return MUSE;
	if (RANK[next] > RANK[previous]) return next;
	return previous;
}

async function classifyText(
	prompt: string,
	ctx: ExtensionContext,
	signal?: AbortSignal,
): Promise<{ complexity: string; taskKind: string; probs: Record<string, number> } | null> {
	const jev = ctx.modelRegistry.findOfType("classifier", "typesafe", "jev-latest");
	if (!jev) return null;
	if (!prompt.trim()) return null;

	const result = await ctx.modelRegistry.classify(
		jev,
		{
			state: { prompt },
			questions: {
				complexity: {
					type: "choice",
					instructions:
						"How demanding is the software engineering work requested in `prompt` for the cheapest capable model?",
					criteria: {
						trivial: "Quick Q&A, summarization, single-line fix, or low-stakes lookup — any flash model can do it",
						standard: "Ordinary feature, bug fix, single-file edit, or routine code review",
						complex:
							"Subtle design, cross-cutting change, hard debugging, multi-file architecture, or high-risk migration",
					},
				},
				task_kind: {
					type: "choice",
					instructions: "What kind of work dominates `prompt`?",
					criteria: {
						chat: "Conversational Q&A, explanation, or summarization with no code generation",
						coding: "Agentic coding with tool calls (read/edit/bash/test)",
						reasoning: "Deep reasoning, planning, or trade-off analysis before coding",
						generation: "Bulk code/content generation expecting very long output (>50k tokens)",
					},
				},
			},
		},
		{ signal },
	);

	if (result.stopReason !== "stop") return null;

	const cAns = result.answers.complexity;
	const tAns = result.answers.task_kind;
	if (cAns?.type !== "choice" || tAns?.type !== "choice") return null;

	let complexity = "standard";
	let maxP = -1;
	for (const [k, v] of Object.entries(cAns.probabilities)) {
		if ((v ?? 0) > maxP) {
			maxP = v ?? 0;
			complexity = k;
		}
	}
	let taskKind = "coding";
	maxP = -1;
	for (const [k, v] of Object.entries(tAns.probabilities)) {
		if ((v ?? 0) > maxP) {
			maxP = v ?? 0;
			taskKind = k;
		}
	}

	const probs: Record<string, number> = {
		...(cAns.probabilities as Record<string, number>),
		...(tAns.probabilities as Record<string, number>),
	};

	return { complexity, taskKind, probs };
}

async function classifyWithJev(
	req: Req,
	ctx: ExtensionContext,
): Promise<{
	target: TargetId;
	effort: { floor?: ThinkingLevel; ceiling?: ThinkingLevel };
	complexity: string;
	taskKind: string;
	probs: Record<string, number>;
	signals: RouteSignals;
} | null> {
	const raw = lastUserText(req.messages);
	const prompt = raw.slice(0, 16_000);
	const classified = await classifyText(prompt, ctx, req.signal);
	if (!classified) return null;
	const signals = readSignals(req.messages, raw);
	return {
		...classified,
		target: pickTarget(classified.taskKind, classified.probs, signals),
		effort: effortBand(classified.taskKind, classified.complexity, classified.probs, signals),
		signals,
	};
}

export function pickSummarizer(complexity: string, taskKind: string): TargetId {
	if (complexity.toLowerCase() === "complex") return MIMO_PRO;
	if (taskKind.toLowerCase().includes("reasoning")) return GLM_FLASH;
	return MUSE;
}

function sampleForClassification(full: string, budget = 16_000): string {
	if (full.length <= budget) return full;
	const half = Math.floor(budget / 2);
	return `${full.slice(0, half)}\n\n[... middle truncated for classification ...]\n\n${full.slice(-half)}`;
}

function asStringSet(v: unknown): Set<string> {
	if (v instanceof Set) return new Set([...v].filter((x): x is string => typeof x === "string"));
	if (Array.isArray(v)) return new Set(v.filter((x): x is string => typeof x === "string"));
	return new Set();
}

function formatFileSuffix(readFiles: string[], modifiedFiles: string[]): string {
	const sections: string[] = [];
	if (readFiles.length > 0) sections.push(`<read-files>\n${readFiles.join("\n")}\n</read-files>`);
	if (modifiedFiles.length > 0) sections.push(`<modified-files>\n${modifiedFiles.join("\n")}\n</modified-files>`);
	if (sections.length === 0) return "";
	return `\n\n${sections.join("\n\n")}`;
}

const SUMMARY_FORMAT = `## Goal
[What is the user trying to accomplish? Can be multiple items if the session covers different tasks.]

## Constraints & Preferences
- [Any constraints, preferences, or requirements mentioned by user]
- [Or "(none)" if none were mentioned]

## Progress
### Done
- [x] [Completed tasks/changes]

### In Progress
- [ ] [Current work]

### Blocked
- [Issues preventing progress, if any]

## Key Decisions
- **[Decision]**: [Brief rationale]

## Next Steps
1. [Ordered list of what should happen next]

## Critical Context
- [Any data, examples, or references needed to continue]
- [Or "(none)" if not applicable]

Keep each section concise. Preserve exact file paths, function names, and error messages.`;

const SUMMARY_SYSTEM_PROMPT =
	"You are a context summarization assistant. Read the conversation and produce a structured summary in the exact format requested. " +
	"Do NOT continue the conversation. Do NOT respond to any questions in it. ONLY output the structured summary.";

const TRIAGE_SECTION = "jev-triage";
const TRIAGE_STATUS_KEY = "jev-triage";

type TriageRole = "scout" | "researcher" | "worker" | "reviewer" | "oracle";

const TRIAGE_GUIDANCE: Record<TriageRole, string> = {
	scout:
		'Delegation authorized for this run: dispatch recon with the subagent tool — subagent({ agent: "scout", task: "<bounded recon objective + expected report>" }) — then implement from its findings. If it proves single-file, do it directly.',
	researcher:
		'Delegation authorized for this run: delegate the investigation with the subagent tool — subagent({ agent: "researcher", task: "<questions + expected synthesis>", async: true }) — then synthesize the findings. If it\'s answerable from visible context, answer directly.',
	worker:
		'Delegation authorized for this run: hand the work package to the subagent tool — subagent({ agent: "worker", task: "<bounded objective + acceptance criteria>", async: true }) — while you hold the plan. If it proves single-file, do it directly.',
	reviewer:
		'Delegation authorized for this run: after implementing, have the change verified with the subagent tool — subagent({ agent: "reviewer", task: "<what to verify>" }).',
	oracle:
		'Delegation authorized for this run: consult a second opinion before implementing with the subagent tool — subagent({ agent: "oracle", task: "<decision + options considered>" }).',
};

async function classifyTriage(
	prompt: string,
	ctx: ExtensionContext,
): Promise<{ scope: string; action: string; actionP: number } | null> {
	const jev = ctx.modelRegistry.findOfType("classifier", "typesafe", "jev-latest");
	if (!jev) return null;
	if (!prompt.trim()) return null;

	const result = await ctx.modelRegistry.classify(
		jev,
		{
			state: { prompt },
			questions: {
				scope: {
					type: "choice",
					instructions: "How wide is the work described in `prompt`?",
					criteria: {
						focused: "Single file, single lookup, or a question about already-visible code",
						multi: "Several files but one thread of work",
						broad: "Repo-wide exploration, many unknowns, or parallel lines of inquiry",
					},
				},
				action: {
					type: "choice",
					instructions: "What shape of work does `prompt` ask for?",
					criteria: {
						answer: "Q&A, explanation, or review of visible code — answerable inline",
						explore: "Reconnaissance across the codebase before acting",
						implement: "Multi-step code changes across files",
						review: "A change wanting verification or a second opinion",
					},
				},
			},
		},
		{},
	);

	if (result.stopReason !== "stop") return null;
	const sAns = result.answers.scope;
	const aAns = result.answers.action;
	if (sAns?.type !== "choice" || aAns?.type !== "choice") return null;

	let scope = "focused";
	let maxP = -1;
	for (const [k, v] of Object.entries(sAns.probabilities)) {
		if ((v ?? 0) > maxP) {
			maxP = v ?? 0;
			scope = k;
		}
	}
	let action = "answer";
	let actionP = -1;
	for (const [k, v] of Object.entries(aAns.probabilities)) {
		if ((v ?? 0) > actionP) {
			actionP = v ?? 0;
			action = k;
		}
	}

	return { scope, action, actionP };
}

function triageVerdict(scope: string, action: string, actionP: number): TriageRole | null {
	if (actionP < 0.6) return null;
	switch (action) {
		case "answer":
			return scope === "focused" ? null : "researcher";
		case "explore":
			return "scout";
		case "implement":
			return scope === "focused" ? null : "worker";
		case "review":
			if (scope === "focused") return null;
			return scope === "broad" ? "oracle" : "reviewer";
		default:
			return null;
	}
}

export default function (pi: ExtensionAPI) {
	const def = {
		provider: "jev",
		id: "auto",
		name: "Auto <Jev>",
		thinkingLevels: ["low", "medium", "high", "xhigh", "max"] as const,
		contextWindow: 1_048_576,
		maxTokens: 131_072,
		async route(req: Req, ctx: ExtensionContext): Promise<ModelRoute<JevRouterState>> {
			if (req.reason === "direct") return routeTo(req, ctx, MUSE);

			const sticky = req.failed ?? req.previous;
			if (req.reason !== "user" && sticky) {
				const rawId = sticky.model.id as string;
				const id = (rawId === LEGACY_MIMO ? MUSE : rawId) as TargetId;
				const known: TargetId[] = [MUSE, MIMO_PRO, DEEPSEEK, GLM_FLASH];
				if (sticky.model.provider === PROVIDER && known.includes(id)) {
					return routeTo(req, ctx, id, req.state);
				}
			}

			const prevTarget: TargetId | undefined = req.state?.target
				? (req.state.target as string) === LEGACY_MIMO
					? MUSE
					: req.state.target
				: undefined;

			const classified = await classifyWithJev(req, ctx).catch(() => null);
			if (classified) {
				const target = prevTarget ? reconcile(prevTarget, classified.target, classified.signals) : classified.target;
				const state: JevRouterState = {
					target,
					complexity: classified.complexity,
					taskKind: classified.taskKind,
					probs: classified.probs,
				};
				return routeTo(req, ctx, target, state, classified.effort.floor, classified.effort.ceiling);
			}

			if (prevTarget) {
				const state: JevRouterState = {
					target: prevTarget,
					complexity: req.state?.complexity ?? "standard",
					taskKind: req.state?.taskKind ?? "coding",
				};
				return routeTo(req, ctx, prevTarget, state);
			}

			return routeTo(req, ctx, MUSE, { target: MUSE, complexity: "standard", taskKind: "coding" });
		},
	};

	pi.registerVirtualModel(def);

	pi.registerVirtualModel({ ...def, provider: PROVIDER });

	pi.on("session_before_compact", async (event, ctx) => {
		try {
			const { preparation, branchEntries, customInstructions, signal } = event;
			const allMessages = [...(preparation.messagesToSummarize ?? []), ...(preparation.turnPrefixMessages ?? [])];
			if (allMessages.length === 0) return undefined;

			const conversationText = serializeConversation(convertToLlm(allMessages));
			if (!conversationText.trim()) return undefined;

			let summarizer: TargetId = MUSE;
			const classified = await classifyText(sampleForClassification(conversationText), ctx, signal).catch(() => null);
			if (classified) summarizer = pickSummarizer(classified.complexity, classified.taskKind);

			const model = ctx.modelRegistry.find(PROVIDER, summarizer);
			if (!model) return undefined;

			ctx.ui.notify(
				`Jev compaction: summarizing ${allMessages.length} messages with ${SHORT[summarizer] ?? summarizer}…`,
				"info",
			);

			const reserve = preparation.settings?.reserveTokens || 16384;
			const maxTokens = Math.min(Math.floor(0.8 * reserve), model.maxTokens > 0 ? model.maxTokens : 8192);

			let promptText = `<conversation>\n${conversationText}\n</conversation>\n\n`;
			if (preparation.previousSummary) {
				promptText +=
					`Update the existing structured summary below with new information. RULES:\n` +
					`- PRESERVE all existing information from the previous summary\n` +
					`- ADD new progress, decisions, and context from the new messages\n` +
					`- UPDATE the Progress section: move items from "In Progress" to "Done" when completed\n` +
					`- UPDATE "Next Steps" based on what was accomplished\n` +
					`- PRESERVE exact file paths, function names, and error messages\n\n` +
					`<previous-summary>\n${preparation.previousSummary}\n</previous-summary>\n\n`;
			} else {
				promptText += `Create a structured context checkpoint summary that another LLM will use to continue the work.\n\n`;
			}
			promptText += `Use this EXACT format:\n\n${SUMMARY_FORMAT}`;
			if (customInstructions) promptText += `\n\nAdditional focus: ${customInstructions}`;

			const response = await ctx.modelRegistry.complete(
				model,
				{
					systemPrompt: SUMMARY_SYSTEM_PROMPT,
					messages: [
						{
							role: "user" as const,
							content: [{ type: "text" as const, text: promptText }],
							timestamp: Date.now(),
						},
					],
				},
				{
					maxTokens,
					signal,
					cacheRetention: "none",
					sessionId: uuidv7(),
					reasoning: "low",
				},
			);

			if (!response || response.stopReason !== "stop") return undefined;
			if (response.content.some((b) => b.type === "toolCall")) return undefined;
			const summary = response.content
				.filter((b): b is { type: "text"; text: string } => b.type === "text")
				.map((b) => b.text)
				.join("\n");
			if (!summary.trim()) return undefined;

			const fileOps = preparation.fileOps as unknown as
				| { read?: unknown; written?: unknown; edited?: unknown }
				| undefined;
			const read = asStringSet(fileOps?.read);
			const modified = new Set([...asStringSet(fileOps?.written), ...asStringSet(fileOps?.edited)]);
			for (let i = branchEntries.length - 1; i >= 0; i--) {
				const e = branchEntries[i] as unknown as {
					type?: string;
					details?: { readFiles?: unknown; modifiedFiles?: unknown };
				};
				if (e?.type === "compaction" && e.details) {
					for (const f of asStringSet(e.details.readFiles)) read.add(f);
					for (const f of asStringSet(e.details.modifiedFiles)) modified.add(f);
					break;
				}
			}
			const readFiles = [...read].filter((f) => !modified.has(f)).sort();
			const modifiedFiles = [...modified].sort();

			return {
				compaction: {
					summary: summary + formatFileSuffix(readFiles, modifiedFiles),
					firstKeptEntryId: preparation.firstKeptEntryId,
					tokensBefore: preparation.tokensBefore,
					usage: response.usage,
					details: { readFiles, modifiedFiles },
				},
			};
		} catch {
			return undefined;
		}
	});

	pi.on("agent_end", async (_event, ctx) => {
		try {
			ctx.ui.setStatus(TRIAGE_STATUS_KEY, undefined);
		} catch {}
		return undefined;
	});

	pi.on("before_agent_start", async (event, ctx) => {
		try {
			if (event.messageType !== "user") return undefined;
			if (process.env.PI_SUBAGENT_CHILD === "1") return undefined;
			if (!event.systemPromptOptions.selectedTools.includes("subagent")) return undefined;
			const triaged = await classifyTriage(event.prompt.slice(0, 16_000), ctx).catch(() => null);
			const role = triaged ? triageVerdict(triaged.scope, triaged.action, triaged.actionP) : null;
			if (!role) {
				delete event.systemPromptOptions.sections[TRIAGE_SECTION];
				return undefined;
			}
			event.systemPromptOptions.sections[TRIAGE_SECTION] = TRIAGE_GUIDANCE[role];
			ctx.ui.notify(`Jev triage: ${role} fits this task — delegation guidance added.`, "info");
			try {
				ctx.ui.setStatus(TRIAGE_STATUS_KEY, role);
			} catch {}
		} catch {}
		return undefined;
	});

	pi.on("message_end", async (event, ctx) => {
		try {
			const msg = (event as { message?: { role?: string; provider?: string; model?: string } }).message;
			if (!msg || msg.role !== "assistant" || !msg.model) return undefined;
			const selected = (ctx as unknown as { model?: { provider?: string; id?: string } }).model;
			const onRouter =
				(selected?.provider === "jev" && selected?.id === "auto") ||
				(selected?.provider === PROVIDER && selected?.id === "auto");
			if (!onRouter) {
				ctx.ui.setStatus(STATUS_KEY, undefined);
				return undefined;
			}
			if (msg.provider !== PROVIDER) return undefined;
			const label = msg.model;
			const level = (event as { message?: { thinkingLevel?: string } }).message?.thinkingLevel;
			const sessionLevel =
				turnSessionLevel ?? (ctx as unknown as { getThinkingLevel?: () => string }).getThinkingLevel?.();
			ctx.ui.setStatus(STATUS_KEY, level ? statusLabel(label, level, sessionLevel) : (SHORT[label] ?? label));
		} catch {}
		return undefined;
	});
}
