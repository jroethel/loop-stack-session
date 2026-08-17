# Handoff: #34 context-map shape, traced and settled (pre-brainstorm)

Date: 2026-08-17.
Session purpose: understand #34 before brainstorming it; no build work done.
Outcome: shape, scope, consumer, and write policy are settled below; #34 is ready for `/loop-brainstorm` whenever it is pulled.

## Provenance (verified this session, file:line)

- Origin: `docs/memos/2026-08-15-pcs-consolidated-recommendations.md:103` (Section 6 item 2) - "~20 lines of pure pointers... plus a staleness guard."
- Research basis: `~/create/research/research/agent_context_files_steer_long_projects.md` - the four-layer model (stable instructions / current state / context map / history); the map was loop-stack's one gap.
- Refinement: `~/create/research/2026-08-16-snipd-context-files-loop-stack-check.md` - decision records are distributed across four homes (briefs' Approach sections, batch journals, molt ledger, DECISION lines), so the index must say where decisions live.
- Already landed: minimal `## Context map` section in `config/repo-state.md` (2 pointers: pcs memo, research corpus).
  #34 = grow it to the full ~20-line index.

## Shape, scope, consumer

- Pure pointer index, never content.
  Verified model: OpenAI's ~100-line AGENTS.md entry point (plans, decision logs, design docs, quality grades).
- Per-repo; lives in `config/repo-state.md`.
- Consumer: any agent orienting in the repo, not just loop skills.
  Failure modes it prevents: "paste everything into the prompt" and silent staleness.
- External sources (Obsidian vaults, QMD) hook in as pointer lines with a retrieval verb (e.g. "query via `qmd search ...`").
  Pointer lines ARE the hook mechanism; no multi-map architecture, no plugin registry.
  A cross-repo knowledge layer, if ever wanted, is a separate backlog item, not #34.

## Candidates evaluated and rejected (all read this session)

| Candidate                              | Why not #34                                                       |
| ---                                    | ---                                                               |
| Graphify-Labs/graphify                 | AST-derived code graph; maps what IS derivable from the repo.     |
|                                        | #34 indexes non-derivable memory. YC platform upsell, heavy dep.  |
| cytostack/openwolf                     | Layer-2 middleware (7 lifecycle hooks, .wolf/ brain); fights the  |
|                                        | tracker-as-spine control plane; AGPL. Harness will eat this.      |
| mattpocock domain-modeling skill       | Changes what the index points AT (ADRs), not the index. See #36.  |
| github/awesome-copilot context-map     | Name collision: per-task ephemeral impact map (files to modify,   |
|                                        | deps, tests). loop-plan already owns that function.               |

Pattern: everything shipping as "context map" in the wild maps code, regenerable by tooling.
#34's layer cannot be generated; that is exactly why every team builds it by hand.

## Side finding: decision E was half-shipped (grep-verified)

Decision E (2026-08-02) absorbed domain modeling into loop-brainstorm.
Landed: glossary challenge + optional scenario stress-test (`skills/loop-brainstorm/SKILL.md:80-88`).
Never landed: CONTEXT.md inline updates and ADR discipline (zero grep hits in loop-brainstorm and loop-plan).
Filed as #36 this session; comment added to #34.
Coupling to #34 is exactly one line: if ADRs land, the decision-records line collapses from four homes to `docs/adr/`.
No ordering constraint; the Snipd check ruled the current distribution defensible at this scale.

## Write policy (recommended, for the brainstorm to ratify)

- What earns a line: the durability test - a fresh agent needs it AND cannot derive it from code or git.
  Index homes, not files ("batch reviews: docs/reviews/" is one line forever); individual files only when singular landmarks.
  Additions are rare by construction: a new KIND of artifact, or a new singular load-bearing doc.
- When: the existing verbose gates - brief commit, handoff close, molt close, archive/graduation.
  Same precedent as parking-lot graduation (automatic at brief-commit) and mirror regen (at handoff, no hooks, no daemons).
  The verbose-announcement rule extends one clause: announce the map line added, moved, or deleted.
  Archive/graduation: the pointer moves or dies with the pointee.
- How: one line in `## Context map`, shape "what - where - why it matters".
  Date only on pointers that can rot (external paths, snapshots); in-repo lane pointers need none.
  Moves are rewritten in place (molt premise rule), never appended corrections.
  Optional lint class-e (every in-repo pointer resolves, one `test -e` loop): HOLD until a pointer actually rots once.

## Resume prompt

Pull #34 off the backlog (explicit, announced - scope rule), run `/loop-brainstorm` with this handoff as the input brief-seed.
The brainstorm's open questions are only: ratify the write policy above, pick the ~20 lines' initial contents, and decide whether any external pointer (Obsidian/QMD) earns a line now or waits.
