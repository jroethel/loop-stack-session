# Settled decisions and build sequence (2026-08-02)

Session record resuming from `docs/2026-07-20-mattpocock-comparison-dump.md` and the parking lot in `docs/briefs/2026-07-21-loop-review-brief.md`.
Decision inputs: Jeremy's annotations in `loop-skills-model-routing.xlsx` (Thoughts column, sheet 1; ACTION column, sheet 2) plus this session's discussion.
This file supersedes the dump's "Open decisions (NOT settled)" list.

## Settled

| Seam | Item                              | Decision                                                     |
|------|-----------------------------------|--------------------------------------------------------------|
| G    | loop-drive preflight/drive split  | No split; in-skill Opus compile dispatch (steps 1-4 + 6)     |
| H    | loop-plan decompose model         | Opus dispatch drafts; session Fable reviews dependency graph |
| -    | Rubix lensing                     | Opus lens A; Fable lens B on high-stakes; GLM third lens     |
| I    | Brainstorm write/review split     | No; a decisions note would just duplicate the brief          |
| E    | Domain modeling                   | Absorb into loop-brainstorm, incl. scenario stress-tests     |
| J    | Wayfinder                         | Copy Matt's, add routing hand-off; depends on B              |
| K    | Prefactors / expand-contract      | Prefactor rule in decompose; expand-contract as reference    |
| F    | Install-as-is set                 | Closed: handoff installed; grilling skipped; tdd/proto wait  |
| 5    | loop-which frontmatter trim       | Yes, in the build wave                                       |
| -    | frontier-sandwich                 | Rename from fable-sandwich; repo skill; config generalized   |

Detail on the settled items:

- G: loop-drive steps 1-4 + 6 (skeleton, model assignment proposals, hazards, prompts/checks, `_loop.md`) become one fresh-context Opus dispatch; Fable keeps step 0, pin review of the compiled output, step 5 gates, step 7 launch.
  Verify loop-drive has an explicit "start from an existing `_loop.md`" entry point; add it if missing.
- H: fresh-context Opus does decompose + draft + self-review as one bundle; session Fable reviews the dependency graph (missing depends-on edges) against the conversation before rubix.
  Rationale: the rubix symptom was builder-blindness, so put each model where its blindness is not.
- Rubix lensing: Fable lens B only on plans flagged high-stakes; GLM as cheap third lens.
  These model choices get recorded via seam D's routing home, not in skill text.
- E: glossary challenge, sharpen fuzzy terms, CONTEXT.md inline updates, ADR discipline, and scenario stress-tests as an optional probe when domain terms are load-bearing.
  Do not touch the Jeremy-maintained "Reading the user" section.
- frontier-sandwich: a one-shot skill that does what the /loop-* chain does more thoroughly; standalone, not part of the chain.
  `config/fable-sandwich/model-benchmarks.md` moves to a generalized location (decided in D) and stays single-source for both frontier-sandwich and /loop-* routing.
  The benchmark-refresh skill's write path must move with it.

## Sequence

1. **D + config relocation** (small, direct edits, no loop needed).
   Extract the three model-naming pins (loop-plan rubix, loop-drive validator, roster constraint) into a generalized routing home.
   Relocate `model-benchmarks.md` there (it is already the prior tier of the routing chain) and update benchmark-refresh plus the managed CLAUDE.md block.
   Record the new lensing and compile-dispatch model decisions there.
   Resolve the opencode loose end while touching routing (remove the wired block until the binary is installed).
   Archive `model-routing-brainstorm-prompt.md` and root `brainstorm-prompt.md` (seam L collapses into D once I is answered no).
2. **B brainstorm** (setup / per-repo state / backlog home).
   Goes before C because J (wayfinder tickets) needs a tracker home, brief parking-lot graduation needs a destination, and C's pause/resume state needs the durable home that B names.
3. **C brainstorm** (autonomy knob: run-through / pause-per-stage / quota-aware, gate typing, "run the rest from any step").
   Goes last of the discussions because its gate-typing convention must exist before the skill bodies are rewritten, or every skill gets edited twice.
4. **Build wave** (brief, then /loop-plan, then /loop-drive) applying everything at once:
   loop-plan (H, K, lensing per routing doc), loop-drive (compile dispatch, entry points, gate typing from C), loop-brainstorm (E, parking-lot graduation from B), wayfinder copy (J), loop-which trim, frontier-sandwich rename and skill add.

## Loose ends carried

- HC2 fresh-session routing check from the model-routing thread: fold into build-wave verification.
- `git push`: main is ahead of origin; push at the next session boundary.
- The xlsx and the mattpocock dump remain the raw decision record; archivable once this ledger is committed.
