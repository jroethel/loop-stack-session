# Loop-Stack: Consolidated Recommendations (Final)

Date: 2026-08-15.
Memo-ized 2026-08-16 from `~/create/pcs/2026-08-15-consolidated-recommendations.md` (moved, not copied; this copy is canonical).
It is the second measurement axis for molt constraint re-derivation (owner ruling 2026-08-16; see `docs/molt-ledger.md`).
This document supersedes the recommendation trail in `2026-08-14-loop-stack-vs-research-evaluation.md` (verdict, addenda, and iterations; now archived with the cycle-1 kickoff prompt in `~/create/pcs/archive/`); that file remains the evidence record, this one states current positions only.
Companion artifact: the molt protocol, vendored canonically at `skills/loop-molt/references/protocol.md` (the pcs `harness-drift-audit-protocol.md` is the historical draft).

Citation keys: P1-P14 / C1-C8 = loop-stack `principles.md`; research files by name from `research/`; [session] = verified first-hand in the 2026-08-14/15 evaluation session; [unverified] = labeled dependency.

## 0. Standing constraints (owner-declared, never re-litigate)

- `/workflows` is off deliberately: it burned tokens and conflicted with ringer (README line 6; Jeremy 2026-08-15).
- Portability is a requirement: harnesses and models must run outside Claude Code (Jeremy 2026-08-15; premium Anthropic access ending, self-manual).
- Consequence: ringer is the spine; native Claude Code primitives are the optional Anthropic-only lane, never the architecture.

## 1. Verdict (unchanged since 2026-08-14)

The verification core is durable and in places ahead of the research; the delivery layer should shrink.
Scorecard vs the corpus's consolidated ideal: 7 strong, 4 partial, 5 gap - every strong in the verification-and-state layer, every gap in the delivery layer.
The research's strongest trend is the harness absorbing plumbing: 80%+ of Claude Code's system prompt deleted with no eval loss, `/ultraplan` removed, todo tools off by default (`claude-code-agent-evolution-90-days.md`, `claude-code-90day-agentic-evolution-2026-08-14.md`) [unverified against live changelog].
Restated after the plumbing-vs-policy analysis: in July loop-drive supplied plumbing and policy; the harness has since eaten the plumbing, and policy is what remains [session: native parallel background fan-out with notifications ran unprompted in this very session, no loop-stack skill involved].

## 2. Keep: the durable concepts

| Concept                                    | Loop-stack source | Research support                                  |
|--------------------------------------------|-------------------|---------------------------------------------------|
| Executed checks as the only PASS           | P1, P14, C2       | "Anchors"; verification-first best practice       |
| Maker/checker in separate contexts         | P2, P3, P5        | Most cross-corroborated claim in the corpus       |
| Checkability as routing gate, DON'T BOTHER | P6, C6            | "Multi-agent unnecessary for ~95% of tasks"       |
| Local scoreboard posterior over benchmarks | P7                | Novel; nothing in the corpus has it               |
| Relaunch-not-resume, git over state file   | P11               | "ASSUME INTERRUPTION"; checkpoints recover only   |
| Gate bandwidth as binding constraint       | P12, P13          | "Reading the slop"; boundary-level supervision    |
| Artifacts-on-disk chain (briefs/plans)     | repo layout       | External state object; receipts                   |
| Mixed-provider cost lane (claude-zai)      | C5, config/ringer | Durable while the quota constraint is real        |
| Deterministic scripts over prompt logic    | tracker.sh etc.   | Manus: complexity in the sandbox, not the prompt  |

Detail on the two novel ones:
P6/DON'T BOTHER formalizes earlier and better than anything in the corpus the finding that most work should not enter a swarm ("don't draw a 40-node graph before you've watched the agent solve the task once", `graph-loop-stack-harness-engineering-use-cases-benefits-raw.md`).
P7's promotion ladder (untested -> probation -> proven) plus "numbers are not portable between users" goes beyond the corpus's per-role routing advice (Ten Principles #7, `claude-code-agent-evolution-90-days.md`).

## 3. Substrate doctrine

- Ringer is the wave-scale substrate everywhere and the only substrate for external engines (constraint 0).
- The native lane exists inside loop-drive as an optional Anthropic-only transport: `/goal` (or a verification subagent) per checkable single-lane unit, parallel background subagents for fan-out, the session as the one brain (P5, C3).
- `/goal` is a unit-level primitive, the native equivalent of one ringer task (spec + check + retry), not of a manifest; per the corpus it is standalone and does not require `/workflows` (`graph-engineering-vs-loop-engineering-claude-comparison.md`: "built into Claude Code - no extra tooling") [unverified live; cheap check: run `/goal` in a scratch repo with /workflows off].
- `loop-plan`'s executor-agnostic plan is the keystone artifact of portability, not process overhead.
- The abstraction, stated fully: the external substrate is P4 (opus-plans/sonnet-executes) generalized to any worker engine, and it holds ONLY because the executed check (P1) replaces the trust opus+sonnet places in Sonnet, and the scoreboard posterior (P7) re-earns trust per engine locally.
  Frontier judgment + any worker + executed check + local evidence ledger; drop the last two and it breaks on the first weak engine.
  The moat is the ledger, not the skills.
- Retracted from the original evaluation: "dissolve the native substrate into /goal and Routines" (reversed by constraint 0) and "let auto-memory absorb P10's evolve move" (auto-memory is Claude-Code-local; portable learning stays in files: MODEL-NOTES, scoreboard, docs).

## 4. /workflows: keep it off (verified 2026-08-15)

Verdict: the disable is warranted, on corrected grounds.
Evidence base [session, two research agents 2026-08-15]: live CLI check (v2.1.204 installed, `disableWorkflows: true` in settings.json), official workflows/agents/prompt-caching docs, changelog, GitHub issues #66023 and #65971, and the loop-stack repo's historical record.

1. **Quota exposure is the load-bearing reason.** Workflow subagents inherit the parent session's model with no auto-downgrade and no cost confirmation (46 Opus 4.8 agents, ~2.99M tokens in 18 minutes, GitHub #66023); auto-trigger footguns exist (casual "workflow" mention spawned a persistent supervisor daemon, #65971; ultracode auto-planning produced an accidental 100+ agent spawn that drained a full allowance in ~15 minutes); all tokens land on the Anthropic quota, the binding constraint.
   `disableWorkflows: true` is a perimeter control, the research's boundary-supervision pattern applied.
2. **Corrected: redundancy, not conflict.** The earlier "two-brains conflict" reason is retracted: the workflow runtime is deterministic JavaScript with no LLM judgment loop - muscle-not-brain, like ringer.
   The true relationship is duplication: it covers ringer's fan-out role for Anthropic-only scope while lacking external engines, executed checks, the scoreboard, and cross-session durability; no documented conflict with external orchestrators exists.
3. **Portability stands.** Claude-Code-only by definition.
4. **New fact, strengthening Section 7:** workflows die on session exit (resume is within-session only, per workflows.md), so the "detached durable pipeline" C1 mourned was never on offer from /workflows; cross-session pipeline durability comes only from background agent sessions (Anthropic-only) or the tracker control plane (portable).
5. **Historical record corrected.** The token-burn rationale is documented five times in the repo but never quantified, and the decision was assumed, not tested (the session's RED-GREEN testing validated the replacement, not the disable); the "conflicting with ringer" recollection has no evidentiary basis and is contradicted by the timeline (disabled by 2026-07-10, before ringer entered at Exchange 2); the only recorded ringer "conflict" was the model-routing question, resolved "Do they interfere? No - the lanes are disjoint" (model-routing-ringer-notes.local.md:131,184); the primary decision record (~/.claude/plans/i-turned-workflows-off-cosmic-quill.md) was deleted.
   The conclusion survives because community evidence independently supplies what the record lacks.
   Jeremy's clarification (2026-08-15): the recorded "burned too many tokens" was always the quota-exposure mechanism, experienced but not quantified or mechanized at the time - consistent with, and now corroborated by, the documented evidence above; the precise framing is exposure (accidental 10-100x spend scaling), not passive drain.

Legitimate re-enable niche (deliberate, occasional, never the routine): a large Anthropic-only fan-out (codebase-wide audit, 20+ parallel agents) with models pinned cheap in the script (`await agent(p, {model: 'claude-haiku-4'})` or `CLAUDE_CODE_SUBAGENT_MODEL`), ultracode off, and the script reviewed before approval; the v2.1.218 cache stagger makes same-model fan-outs cheaper than in July.
Ringer covers the same shape on engines that never touch the quota, so the case stays thin.

## 5. Structural changes to the stack (remove / fold / slim)

1. Fold frontier-sandwich into loop-drive as a human-paced output mode; the README itself calls them "two halves of one compile step".
2. Shrink loop-which to the literal front door: the One-Minute Test as the first question, before brainstorm/plan spend (C6 says front door; the shipped chain has it third; "if you could describe the diff in one sentence, skip the plan", `claude-code-90day-agentic-evolution-2026-08-14.md`).
3. Dedup to one home + pointers: the routing-chain narrative currently in 4+ places (loop-drive, ringer-substrate, frontier-sandwich, loop-which, wayfinder, model-benchmarks.md; backlog #18 names the seam), ringer footguns (keep only `ringer-substrate.md`), graduation logic (keep only `brief-pipeline.md`).
   Research basis: the dedup shift, `progressive-disclosure-context-methods-claude-raw-v3.md`.
4. Slim skill prose by test-by-subtraction: delete a block, run the existing gate tests plus one real task, keep the deletion if nothing degrades.
   Per-line criterion: "would removing this cause a mistake? If not, cut it" (`claude-code-90day-agentic-evolution-2026-08-14.md`); evidence deletion is safe: the 80% system-prompt result.
   Fairness note [session inventory]: skills cost ~100 tokens each at rest via progressive disclosure, so install count is nearly free; the real costs are invocation-time prose, drift across duplicated copies, and maintenance.
5. The native lane of loop-drive becomes a policy sheet riding native mechanics.
   Policy = what the harness will not impose unprompted [session-derived list]: dependency-derived waves with exclusive file ownership, checks-or-stall per unit, separated fresh-context validator (never fixes, independent rerun, pass/fail/spec-problem), per-unit cost routing (Sonnet default, promotion criteria), risk-classed gates, run-state a NEW session can pick up.
   Plumbing = delete: prose re-describing decomposition, fan-out, background execution, notifications.
6. Landing zone: roughly half the skill prose; 11 skills to ~7.

| Step          | Skill / mechanism                                            | Change                      |
|---------------|--------------------------------------------------------------|-----------------------------|
| Triage        | One-Minute Test as the literal first question                | loop-which shrinks, moves   |
| Shape         | loop-brainstorm / loop-improve                               | Keep, slim the choreography |
| Plan          | loop-plan (executor-agnostic)                                | Keep - the keystone         |
| Compile+drive | loop-drive, ringer primary, native as Anthropic-only lane    | Absorbs frontier-sandwich   |
| Verify        | Executed checks + loop-review                                | Keep, add check custody     |
| Control plane | tracker.sh + wayfinder + handoff + Open Engine statuses      | Promoted to the spine       |
| Cross-cutting | loop-auto knob; ASK/STOP as hooks on the CC side             | Prose gates become hooks    |

Shaping capability note: brainstorm/improve survive on capability, not just form - up-front question generation is exactly the taste work that fails P6's checkability gate and stays in the frontier-plus-human lane where premium spend belongs (P4).
The harness deleted execution scaffolding (todo lists, /ultraplan), not intent shaping; nothing native generates the questions that make work land closer to what is wanted.

## 6. Additions (what the research says is missing)

1. **Gates as hooks.** Implement ASK and STOP gate classes as PreToolUse hooks (exit 2 blocks) keyed off the chain-state knob and protected paths; BATCH and DEFAULT stay prose.
   Basis: instructions get ~70% adherence, "a deterministic PreToolUse hook (exit 2) is the only real guarantee" (Ten Principles #5, `claude-code-agent-evolution-90-days.md`); closes backlog #28.
   Caveat: hooks guarantee only the Claude Code side; ringer-side enforcement is check custody plus sandbox config - guarantee-class gates need both homes.
2. **Context map index.** Extend `config/repo-state.md` with ~20 lines of pure pointers: current plans, decision log, standards, quality grades, key design docs, plus a staleness guard (the gen-mirrors disclosure-header pattern is the in-repo template).
   Basis: the one context layer Claude Code does not provide natively, and "silent staleness" as its named failure mode (`agent_context_files_steer_long_projects.md`, source-triggered by the Nate B. Jones Snipd episode "AI Agent Context Files: How to Steer Long Projects", 2026-08-12 [session: verified by grep, line 3]; that file also contains the corpus's own loop-stack gap analysis: three of four layers present, context map missing).
3. **Check custody rule.** Acceptance-check scripts live outside every worker's file ownership; a worker diff touching a check file is an automatic scope violation.
   One sentence in loop-drive plus a lint if ringer supports it.
   Basis: METR found o3 reward-hacked past a loop's success criterion in 21 of 21 runs (`graph-engineering-vs-loop-engineering-claude-comparison.md`); the check is the attack surface, and P14 covers check quality but not check custody.
4. **Session-hygiene reference** (a reference file, not a skill): /clear between tasks, /compact while cache warm, two-failed-corrections-then-/clear-and-rewrite, quarantine heavy reading in subagents, @-mention over Read.
   Basis: "everything in the conversation gets sent again on every turn" (`claude-code-90day-agentic-evolution-2026-08-14.md`); quality drops past ~50% window, hallucinations past ~70% (`progressive-context-switching-implementation-claude-code-raw.md`).
   Point the managed CLAUDE.md block at it rather than growing the block.
5. **Native /goal as a third transport** in loop-drive for Anthropic-only, single-lane, executably-checkable units (Section 3 detail).
6. **Fix the known defects**: actually gitignore `docs/chain-state.md`; apply the 2026-08-10 memo's gitlab-mode fixes (both from the repo's own `docs/memos/2026-08-10-to-loop-stack.md`).

## 7. Control plane: adopt Open Engine's shape

The deepest architectural change: the spine moves from "a session that must stay alive" to "a tracker that outlives sessions."
C1's admitted cost was "no detached durable pipeline"; Open Engine's tracker-as-control-plane fills it portably and token-free (`nate-jones-open-engine-loop-graph-harness-context-analysis.md`).

Already owned (~70%): `tracker.sh` (github/gitlab/local seam), wayfinder's decision tickets, handoff's receipts, wayfinder's one-ticket-per-session rule (independently converged with Open Engine's queue-runner stop rule).
To add: the status vocabulary as tracker labels (Todo / Working / Needs Input / Review / Done), claim locks (move + `AGENT CLAIMED` + re-read to avoid the race), a queue-runner prompt processing at most one eligible ticket per run, run-state moved onto tickets so a dead session's work is claimable rather than resumable, boundary-first rules on outward-facing actions.

The marriage that beats both parents: Open Engine externalizes verification to the human (`AGENT DONE` is exactly the self-report P2 forbids, per the research file's own critique), while loop-stack has executed checks but a session-bound pipeline.
Open Engine's control plane + loop-stack's executed checks = the portable ideal.

## 8. Molt: the reusable self-improvement mechanism

Full protocol: `harness-drift-audit-protocol.md`; summary of final positions after iteration:

- **What it is:** a repeatable audit of any instruction prose (skills, CLAUDE.md blocks, manuals, run-books) against a dated snapshot of current harness capability.
  One-line test per block: "would the harness or a current frontier model do this unprompted, today?" - correct-but-native is still deletable.
- **Four bins:** PLUMBING (harness does it -> delete or one pointer), POLICY (discipline the harness won't impose -> keep, sharpen to outcomes), PREMISE (verify by second route; deliberate constraints labeled and never re-litigated), CHOREOGRAPHY (judgment-covered step-by-step -> delete via subtraction).
- **Constraint register first:** ask the owner which choices are deliberate before classifying any premise as expired - encoded from this session's C1 lesson, where a deliberate constraint misread as stale flipped three recommendations.
- **Research is inside the audit, not a prerequisite:** thin refresh (changelog + one live probe, minutes) for single artifacts; deep refresh (a pcs-corpus-style pull) only for whole-stack recalibrations or model-generation changes; the drift ledger lets later audits diff from the last snapshot.
- **Principles sheet is an accelerator, not a prerequisite:** with one (loop-stack's P1-P14), POLICY = traces to a principle; without one, name the invariant each POLICY block protects (unnameable invariant = choreography in disguise), and the first audit emits the collected invariants as a starter principles sheet.
- **Subtraction test needs checks:** loop-stack's gate tests are the model; checkless artifacts use the weaker fallback (delete, run one real task, compare).
- **Wiring - one implementation, two entry points:** a thin standalone skill owns the audit (suggested name `/loop-molt`, invocable on any artifact regardless of what else is running); `/loop-improve --focus harness-drift` delegates with a one-line pointer, never a second copy.
- **Placement - third audit in the family:** improve audits the product, molt audits the instruction prose, P10's evolve move audits the run logs; molt exists because the other two never catch harness drift (nothing fails when the harness absorbs plumbing - the "silent staleness" mode).
- **Workflow:** small findings applied inline via subtraction with a drift ledger line, same session; structural findings converge through the shared `brief-pipeline.md` into a brief and ride the normal chain (/loop-plan -> /loop-which -> /loop-drive -> /loop-review) - the stack improves itself through its own front door.
- **Steady state:** artifacts converge to policy sheets; an artifact deleting nothing two cycles running is done molting; one that only grows has never been audited.

## 9. Suggested execution order

1. Fix the known defects and add the check custody sentence (minutes; Section 6.3, 6.6).
2. Build `/loop-molt` from the protocol file and run it on loop-stack itself; its structural findings ARE the brief for Sections 5.1-5.5 (fold, dedup, slim, policy sheet), so the slimming work rides the normal chain instead of being hand-planned.
3. Control plane build (Section 7) as its own brief - it is the deepest change and unblocks retiring session-bound run-state.
4. Hooks, context map, session-hygiene reference (Sections 6.1, 6.2, 6.4) - independent, small, can ride as one wave.
5. /goal transport (Section 6.5) after its cheap existence check.

## 10. Risks and unverified dependencies

- The native-capability claims (/goal, Routines, background/fork defaults, auto-memory, the 80% deletion) rest on the two 90-day research files, not on a live changelog check; if misreported, Sections 3 and 5.5 weaken proportionally while Sections 2, 6.1-6.3, 7, and 8 stand regardless.
  Cheapest falsification: `/help` or the changelog for `/goal` and Routines.
- The repo inventory and 9 of 13 research digests were produced by fresh-context subagents [session, secondhand]; principles.md, README.md, the graph brief, the loop-vs-graph comparison, and the Snipd-trigger grep were first-hand.
- The corpus flags several of its own framings PLAUSIBLE/UNVERIFIED (four-layer memory model, the diamond, exact 70%/60% figures); only cross-corroborated claims were load-bearing here.
- ~~Current /workflows behavior is unverified~~ - resolved 2026-08-15 by direct research (Section 4); the disable stands on evidence, with the two-brains reason retracted and the ringer-conflict recollection corrected.
