# Brief: unified model routing across loop-drive's substrates

Date: decisions recorded 2026-07-18; brief written 2026-07-19.
Source prompt: `model-routing-brainstorm-prompt.md` (settled facts there are binding and not restated in full here).
Next stage: /loop-plan.

## Outcome

One evidence-first model-choice procedure for every unit of a loop-drive run, with substrate demoted from a per-wave choice to a per-unit derived transport attribute.
Riders: the /loop-setup verdict (no skill; grow install.sh's doctor) and the #65-as-routing-integrity-layer PR framing (capture-only).
Presupposition verdict: the original "native vs mixed-provider substrates" framing is rejected as fake (settled fact); the candidate direction from the prompt survived pressure-testing intact, sharpened by the five recorded decisions below.

## End artifact

Rewritten loop-drive Steps 0 and 2 plus consistency touches, the benchmark prior file created (it is currently a dangling pointer - verified 2026-07-18), a grown install.sh doctor, and the PR framing note for #65.
The capability unblocked: execution at scale with validation at scale - brute-force parallel waves at higher quota burn when wanted, low-babysit long runs, and routing evidence that is auditable and self-correcting.

## Done looks like

- `/loop-drive <plan>` emits a routing table where every unit row shows: task_type, the model with its evidence tier (integrity-gated scoreboard posterior, else benchmark prior, else orchestrator pin with reason), and transport as a derived column (session tools or continuation -> Agent tool; ringer absent -> Agent tool degraded mode; else ringer).
- A wave can mix transports: its ringer units pack into one manifest (`./ringer.py lint <manifest> && ./ringer.py run <manifest>`), its native units launch as parallel Agent calls, both meet at the same gate.
- `bash install.sh` prints doctor lines covering the routing prerequisites: engine blocks parse, zai-token present, `~/.ringer/` writable, `./ringer.py demo` hint.
- Native gates write mandatory dated MODEL-NOTES receipts; no native scoreboard rows.
- Until #65 lands, the routing step applies the jq exclusion overlay from AMENDMENTS-PENDING Section C before trusting any posterior; after, it reads the Amended column.

## The five recorded decisions

1. Wave vs unit: transport is a per-unit derived attribute; each wave's ringer units pack into one manifest and native units launch as parallel Agent calls; the wave stays the gate boundary.
2. Ladder home: split by kind - the promotion triggers (architecture-defining, math/reasoning-heavy, risk concentration) become the orchestrator-pin criteria in Step 2; Anthropic capability expectations become benchmark prior rows.
3. Native evidence: mandatory dated MODEL-NOTES receipts at native gates; no scoreboard rows (native verdicts are validator judgment, not executed checks, and would need their own amendment machinery).
4. Evidence integrity: an explicit integrity-gate step in the routing procedure - check MODEL-NOTES and pending amendments before trusting a posterior; interim jq overlay, post-patch Amended column; the same read-before-trust discipline covers native receipts.
5. /loop-setup: no skill; grow install.sh's existing doctor section, with loop-drive Step 0's runtime capability probe handling the per-run side.

## Assets and options

| Asset                                    | Implied option                                                            | Verdict                              |
|------------------------------------------|----------------------------------------------------------------------------|---------------------------------------|
| Ringer scoreboard + `models` CLI         | Evidence source of record (posterior tier)                                 | Chosen                                |
| Benchmark prior file (`model-benchmarks.md`) | Prior tier; must be created, with Anthropic + GLM rows                   | Chosen                                |
| Sonnet/Opus promotion ladder             | Demote: triggers -> Step 2 pin criteria; expectations -> prior rows        | Chosen (demoted)                      |
| claude-zai lane (z.ai flat plan)         | Default execution engine via evidence, standing default preserved          | Chosen                                |
| Agent tool enum (sonnet/opus/haiku/fable) | Native transport roster; Fable never a worker                             | Chosen (as transport)                 |
| MODEL-NOTES                              | Mandatory native-gate receipts + integrity read                            | Chosen                                |
| jq overlay (AMENDMENTS-PENDING §C)       | Interim integrity gate                                                     | Chosen until #65                      |
| #65 amend + Amended column               | Post-patch integrity gate; PR framed as routing integrity layer, Nate quote | Chosen (capture-only)                 |
| install.sh doctor section                | Grows to cover routing prerequisites                                       | Chosen                                |
| Open Brain/Skills/Engine vocabulary      | Organizing principle: procedure -> Skills, preferences -> Brain, evidence -> Engine | Chosen                       |
| Managed CLAUDE.md block                  | One-line touch-up to match unified language                                | Chosen (small)                        |
| /loop-setup as a skill                   | Guided setup conversation                                                  | Declined                              |
| Standalone loop-doctor script            | Rerunnable doctor outside install.sh                                       | Declined                              |
| Ringer ingest command for native rows    | Upstream patch to record external outcomes                                 | Declined (parked)                     |
| Shared `references/routing.md`           | Procedure extracted for multi-skill reuse                                  | Declined until a second consumer exists |

## Approach

Chosen: A - unified-chain rewrite.
Steps 0 and 2 are rewritten around one procedure: integrity-gated scoreboard posterior for the task_type, else benchmark prior, else orchestrator pin (design / math / risk / taste, reason recorded in the evidence column).
Step 0 loses substrate-per-wave and gains the runtime capability probe; Step 2 derives transport per unit and packs each wave's ringer units into one manifest; Steps 3-7 get consistency touches for mixed waves.
Considered and declined: B - surgical amendment (keeps the ladder as a live mechanism, the exact P7 route-by-vibes the settled facts convicted; two rulebooks keep drifting) and C - shared routing reference file (loop-which only needs availability, which it already reads from `config.toml`; a pointer with one real consumer is indirection, not reuse).

## Success criteria

- `[executed-check]` The ladder-as-mechanism is gone: `grep -c "keep the Sonnet-default / Opus-promotion ladder" skills/loop-drive/SKILL.md` returns 0, and Step 2 contains the posterior/prior/pin chain with the integrity gate step.
- `[executed-check]` Transport is derived per unit: Step 0 no longer says substrates are "chosen per wave"; the routing-table schema in Step 2, Step 6 item 2, and `references/example-output-plan.md` all carry a transport column, and the example shows one wave mixing transports.
- `[executed-check]` The benchmark prior file exists at `~/.claude/skills/fable-sandwich/references/model-benchmarks.md` (the path loop-which already names), with rows for sonnet, opus, haiku, and glm-5.2 at minimum.
- `[executed-check]` `bash install.sh` on this machine exits 0 and prints doctor lines for: engine blocks parse, zai-token presence, `~/.ringer/` writability, `./ringer.py demo` hint.
- `[executed-check]` The integrity gate is procedural text: Step 2 instructs checking pending amendments / MODEL-NOTES before trusting a posterior, naming the interim overlay and the post-patch Amended column.
- `[executed-check]` Native receipts are mandatory: Step 5's distill step says MUST (not "when a run taught you") for dated MODEL-NOTES lines from native gates.
- `[executed-check]` The stm-nav lesson lines landed 2026-07-17/18 survive the rewrite (verdict discipline, run-JSON-is-truth, FAIL attribution, check-rules pointer).
- `[executed-check]` The PR framing note exists and contains Nate's appeals-process quote.
- `[judgment]` A fresh session compiling a sample plan applies the chain without asking which substrate to use and without inventing a second rulebook.
  (Reformulation attempted: the example-plan grep above captures the artifact side; this tag survives because skill-following behavior is only observable in a live compile.)

## Seams

Blast-radius order:

1. Step 2 unified routing procedure - defines the chain, pin criteria, integrity gate, and evidence column vocabulary; everything else consumes its language.
2. Step 0 rewrite - capability probe, per-unit transport derivation, routing of single-artifact exits.
3. Consistency touches - Steps 3-7, `references/example-output-plan.md`, `ringer-substrate.md`, `native-orchestration.md` (mixed-wave gates, watch points, dashboard).
4. Benchmark prior file creation - independent.
5. install.sh doctor growth - independent.
6. Managed CLAUDE.md block touch-up - follows 1-2.
7. #65 PR framing note - independent, capture-only.

## Known vs guessed

Verified (2026-07-18 session):

- The four wired engines in `~/.config/ringer/config.toml` (codex, claude, claude-zai, opencode).
- install.sh's existing non-fatal doctor section (step 4).
- Current Step 0/2 text, including the per-wave substrate language.
- The amendment design and pending-data files (`fixing-agent-errors.md` here; canonical on the work PC).
- The benchmark prior file does NOT exist at the path loop-which names.
- `~/.claude/skills/fable-sandwich/` is a plain directory, not a symlink into this repo - the benchmark file currently has no repo-managed home.
- The Agent tool enum is sonnet/opus/haiku/fable.

Believed, unchecked:

- The ringer skill's check-writing section still carries the four stm-nav rules (memory says so, not re-read).
- `AMENDMENTS-PENDING.md` on the work PC matches the copy in `fixing-agent-errors.md` here.

Guessed, with what breaks if wrong:

- Mixed-wave gate cost (two watch surfaces) stays manageable; if wrong, packing degrades gracefully toward same-transport waves.
- glm-5.2's amended posterior recovers enough to stay the typing default; if wrong, the prior/pin tiers absorb it and nothing breaks.

## Parking lot

- Dollar cost ledger with burn-rate projection (pre-parked in the prompt).
- Quota-aware pause/resume scheduling (pre-parked).
- Long-running streams / autoresearch layer (pre-parked).
- Ringer ingest command for native evidence rows (declined at decision 3; revive as an upstream proposal if the MODEL-NOTES-only receipt proves too thin).
- Standalone rerunnable loop-doctor script (declined at decision 5; revive if doctor checks are wanted outside install runs).
- Shared `references/routing.md` (approach C; revive when loop-plan or loop-which needs the full procedure).
- Per-attempt amendment support for the two borderline stm-nav rows (Jeremy's call, only if #65 ever supports it).

## Out of scope

- The #65 patch implementation itself - owned and specced in `~/repos/ringer/docs/AMENDMENT-ROWS.md`; only its routing implications and PR framing are here.
- Modifying the Agent tool's model set (separate investigation flagged 2026-07-17).
- Any change to ringer.py or its config schema.
- Rewrites of loop-plan, loop-which, or fable-sandwich beyond the named touch-ups.
- Executing any loop run; this brief specs skill text, not a run.

## Open questions for planning

- Exact routing-table column set and ordering (transport, evidence tier, pin reason) across Step 2, Step 6, and the example plan.
- Whether Step 0's ONE AGENT / single-wave exits get the full derivation or a one-line simplification.
- How the doctor parses `config.toml` (grep vs python tomllib) and whether it should live before or after the install steps.
- Where the PR framing note lives (ringer repo docs, this repo, or the issue thread directly).
- Whether loop-which gets a one-line vocabulary alignment beyond its existing ground-truth-config paragraph.
- Benchmark prior file format: table schema, and whether ringer-substrate.md's "untested/probation/proven" ladder language should reference it explicitly.
- Where the benchmark file's canonical source lives: bring fable-sandwich under this repo's install model, or leave it unmanaged and accept the doctrine exception.
