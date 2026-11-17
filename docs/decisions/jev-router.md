# Decision: jev router model selection

`pi/extensions/jev-router.ts` registers the virtual model `opencode-go/auto` (alias `jev/auto`) and routes each request to an opencode-go model using the TypeSafe Jev classifier. Capability and speed decide; cost breaks ties.

Requires `TYPESAFE_API_KEY` (via `/login → typesafe`) and an opencode-go API key. Select with `pi --model jev/auto` or `/model`.

## Evidence (20 Oct 2026)

Benchmarks from the "opencode go model league" (nahuelgenchi.com/software/opencode-go-model-league — 29 models, 8 benchmarks, blended per-request cost); Intelligence Index and output speed from Artificial Analysis; token prices from pi's `models-store.json`.

| model | int | t/s | DeepSWE | TB2.1 | SciCode | AA-LCR | AA-code | $/req |
|---|---|---|---|---|---|---|---|---|
| muse-spark-1.3-contrib | 48 | 114.5 | 75.4 | 72.3 | 58.8 | 83.0 | 54.3 | $0.00026 |
| mimo-v2.6-pro | 46 | 49.1 | 71.9 | 67.8 | 60.9 | 86.3 | – | $0.00092 |
| claude-haiku-5-5 (rejected) | 43 | 236.0 | – | – | 55.0 | 82.7 | 36.5 | $0.00078 |
| deepseek-v4.1-flash | 39 | 233.5 | 74.2 | 74.5 | 51.9 | 84.0 | – | $0.00046 |
| glm-5.3-flash | 42 | 76.2 | 63.0 | 62.9 | 51.6 | 80.0 | 71.5 | $0.00190 |
| gpt-6-luna | 38 | 122.5 | 66.6 | 73.0 | 54.6 | 83.3 | 41.1 | $0.00071 |
| kimi-k3 | 44 | 41.2 | 69.0 | 80.9 | 59.5 | 88.7 | 51.9 | $0.03060 |
| grok-4.7 | 46 | 91.5 | 71.0 | 73.4 | 57.4 | 76.7 | 56.3 | $0.01775 |

Prices per 1M tokens:

| model | in | out | cached | notes |
|---|---|---|---|---|
| muse-spark-1.3-contributor | $0.10 | $0.20 | $0.002 | 1M ctx, 131k out, vision |
| deepseek-v4.1-flash | $0.15 | $0.60 | $0.003 | 384k out, vision |
| glm-5.3-flash | $0.15 | $0.50 | $0.030 | vision |
| mimo-v2.6-pro | $0.435 | $0.87 | $0.0036 | vision, near-free cache |

## Decisions

- No model on the plan is both faster and better at coding than muse, so hard coding gets more thinking (effort floor → xhigh), not a slower model. gpt-6-luna was dropped as dominated.
- Task *kind* matters as much as complexity, so effort is a band per (kind × complexity): bulk chat/generation is clamped low, coding/reasoning raises it, structural evidence or repeated tool failures force xhigh. Clamping changes a turn's thinking level only, never the session's model or history.
- mimo-v2.6-pro is the strongest long-context model but runs at 49 t/s, so it is used for compaction summaries only.
- Stuck loops stay on muse with more effort. claude-haiku-5-5 added a fifth model and a second tool-reliability profile for no measured coding gain; deepseek leaks tool calls as text, which is exactly what a stuck, tool-driven loop cannot afford.
- gemini-4-argon leads raw benchmarks but at ~$0.028/req stays out of automatic routing.
