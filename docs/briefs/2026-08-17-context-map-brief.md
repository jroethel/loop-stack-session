# Brief: context map full index (#34)

Date: 2026-08-17.
Input seed: `docs/handoffs/2026-08-17-context-map-34-shape.md`.
Policy audited pre-ratification by a blinded Rubix review (cold-craft lens, grounded in `~/create/research/research/`); all 7 findings incorporated, F3 modified.

## Outcome

A fresh agent orienting in this repo reaches every piece of non-derivable memory through one ~20-line pointer index, governed by a full lifecycle policy (add, refresh, prune, delete) so the index stays trustworthy across months of sessions.
Presupposition verdicts: the handoff's shape/scope/consumer held; its write policy was missing the lifecycle back half (user-spotted, independently confirmed by the blinded review); its settled home (`config/repo-state.md` section) was overridden this session - see Approach.

## End artifact

`config/context-map.md`: the index plus its lifecycle policy as header prose, shipped in a single edit session when the plan executes.
Unblocks: fresh-agent orientation without "paste everything into the prompt", and gives loop-molt a reviewable per-line target.

## Done looks like

- `config/context-map.md` exists: policy header plus ~17 lines, each shaped "what - where-or-how-to-retrieve - why it matters".
- The 2 existing `## Context map` lines in `config/repo-state.md` migrate there; repo-state.md keeps a one-line pointer (it is the definitive list of convention files).
- `scripts/lifecycle-lint.sh .` gains class-e (every in-repo pointer resolves) and exits 0.
- Project `CLAUDE.md` names the context map as the repo's orientation index.
- Usage: read `config/context-map.md`, reach any indexed artifact; the QMD line's verb (e.g. `qmd search "<topic>"`) reaches the research corpus.

## Assets and options

| Asset                                     | Option implied            | Verdict                            |
| ---                                       | ---                       | ---                                |
| `config/repo-state.md ## Context map`     | Home for the index        | Declined - coupling test failed    |
| `config/context-map.md`                   | Home for the index        | Chosen; repo-state keeps pointer   |
| Four decision-record homes                | One index line naming all | Chosen; collapses if #36 lands     |
| OpenAI ~100-line AGENTS.md                | Structural model          | Shape reference only, no line      |
| QMD over `~/create/research`              | Retrieval-verb line       | Chosen (verified reachable)        |
| Obsidian vaults                           | Retrieval-verb line       | Declined - wrong layer for repo    |
| Raw transcripts (fixing-agent-errors etc) | Index lines               | Chosen as transient, dated         |
| Model-routing notes                       | Index lines               | Chosen, durable-operational        |
| `gate-registry.md`, mirrors               | Index lines               | Declined - regenerable             |
| `triage-loop-run-state.md`                | Index line                | Declined - ephemeral run state     |
| Lanes-table homes                         | Index lines               | Declined - declared in repo-state  |
| Auto-memory `MEMORY.md`                   | Overlapping index         | Boundary sentence, never indexed   |

## Approach

Index structure - chosen A (flat list, decay via dating); considered B (grouped by kind), C (separate root CONTEXT.md, pre-rejected last session).
Rationale: the load-bearing "why" clause does grouping's job at ~17 lines without its maintenance surface; molt consumes uniform lines.

Home - chosen `config/context-map.md`; considered the handoff-settled `repo-state.md` section.
Rationale: the coupling test failed both ways (scripts consume repo-state.md without the map; an orienting agent consumes the map without the lanes schema), and repo-state.md is already schema-dense (#38 filed for its refactor).
Links: repo-state.md one-line pointer, and the project CLAUDE.md names both.

The ratified lifecycle policy (the handoff policy plus user amendments plus Rubix findings 1-6):

- Add: the durability test - a fresh agent needs it AND cannot derive it from code or git; homes over files; additions rare by construction.
- Line shape: "what - where-or-how-to-retrieve - why it matters"; the why clause is load-bearing (molt reads it to keep or retire the line without opening the pointee).
- Dating as decay: in-repo durable lines undated; anything leaving the repo (external path, retrieval verb, snapshot) dated; transient lines (raw transcripts) dated and expected to die at a molt or archive pass; machinery-supporting operational notes count as durable.
- Refresh: touching a pointee (edit, supersede, move) revalidates its line's where and why in the same change.
- Write gates: brief commit, handoff close, molt close, archive/graduation; verbose announce of every line added, moved, or deleted.
- Prune: the map is an explicit molt-close target - removal test per line, plus a staleness look at dated external lines; no retrieval verbs execute in lint.
- Delete: the pointer moves or dies with the pointee (archive/graduation).
- Boundary: the map holds repo-committed pointers to in-repo artifacts and external corpora; per-user operating lessons live in auto-memory `MEMORY.md`, never here.
- Lint class-e ships now (not held): every in-repo pointer resolves, one `test -e` loop in `lifecycle-lint.sh`.

## Success criteria

- Class-e lint: every in-repo pointer in the map resolves; `scripts/lifecycle-lint.sh .` exit 0. `[executed-check]`
- Every index line carries the three clauses of the line shape (grep-able separator count). `[executed-check]`
- Every pointer leaving the repo carries a date; no in-repo durable line does (grep-able). `[executed-check]`
- The QMD line's retrieval verb, run verbatim, returns a hit from the research corpus. `[executed-check]`
- Project `CLAUDE.md` names the context map; `config/repo-state.md` points at it. `[executed-check]`
- Each why clause lets molt keep or retire the line without opening the pointee - reformulation attempted (clause-presence grep loses the intent); stays `[judgment]`, human checkpoint.
- Policy text covers all four lifecycle moments (add, refresh, prune, delete) adequately - presence is grep-able but adequacy is the point. `[judgment]`

## Seams

1. Policy prose (everything else conforms to it) - ratified above, worded at plan time.
2. The ~17 index lines in `config/context-map.md`.
3. The two link edits: repo-state.md pointer (replacing its `## Context map` section) and the project CLAUDE.md line.
4. Class-e in `scripts/lifecycle-lint.sh`.

## Known vs guessed

- Verified this session: current section = 2 lines; every candidate file read or peeked; `lifecycle-lint.sh` LINT-class output contract (exit 0 clean, 1 on findings); `qmd search` reaches the corpus (86% hit on the context-files doc); no cross-repo item in BACKLOG.md.
- Believed-unchecked: the qmd `pcs` collection tracks the renamed `~/create/research` path for future re-index (the verified hit may serve stale content); plan verifies.
- Guessed: ~17 lines holds after wording; soft target, nothing breaks at 20.

## Parking lot

- Archive-candidacy review of the raw transcript root files at a future archive pass
  Restart context: `fixing-agent-errors.md` and `model-routing-ringer-notes.{local,remote}.md` are raw pasted transcripts at repo root; indexed as transient lines by #34; decide archive vs keep at the next molt or archive gate.
- Cross-repo knowledge layer above per-repo context maps
  Restart context: named in the 2026-08-17 handoff as explicitly not-#34; no backlog issue exists yet; would federate per-repo maps or a shared QMD layer.

## Out of scope

Global `~/.claude/CLAUDE.md`; Obsidian; multi-map architecture or plugin registry; ADR discipline (#36); the config-landscape refactor (#38, filed this session); executing retrieval verbs inside lint; archiving any file this brief mentions.

## Open questions for planning

- Exact QMD line wording and whether the `pcs` collection gets renamed or re-pointed.
- Class-e insertion point in `lifecycle-lint.sh` and its LINT-line message shape.
- Date format for rot-prone lines (YYYY-MM vs YYYY-MM-DD).
