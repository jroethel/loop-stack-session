# Repo State Convention Brief (seam B)

Date: 2026-08-02.
Source: seam B of `docs/2026-08-02-settled-decisions-and-sequence.md`, the setup findings in `docs/2026-07-20-mattpocock-comparison-dump.md`, and this session's brainstorm.

## Outcome

After any break - an hour or a month - three questions are answerable in any conforming repo from standard locations alone: where did I leave off, what is next (roadmap plus open issues), and what is left (backlog).
Presupposition tested: "file-based is simplest" held for roadmap but failed for issues and backlog - Jeremy's own file conventions (two competing ones in pokemine alone) rotted for lack of curation; the split-by-lane approach won.

## End artifact

This repo's own state stood up the day the convention ships: `config/repo-state.md` declared, live parked items (loop-review brief parking lot, ledger loose ends) graduated to labeled gh issues, mirrors generated.
This unblocks the build wave concretely: wayfinder's map-and-tickets machinery needs the tracker to exist.

## Done looks like

In a conforming repo:

- Open `config/repo-state.md` and see where every lane lives, with the exact commands inline.
- Open `ISSUES.md` and `BACKLOG.md` mirrors whose headers state generation time and the regen command.
- Run the documented cross-repo backlog command: `gh search issues --owner jroethel --label idea --state open`.
- Run `/handoff`: the handoff doc lands at the declared repo location and the mirrors refresh in the same pass.
- Start a fresh session that orients from the standard locations alone.

Outside any repo, `/handoff` behaves exactly as today (OS temp dir).

## Assets and options

| Asset                                    | Option implied                                | Verdict                        |
|------------------------------------------|-----------------------------------------------|--------------------------------|
| Matt's setup skill (read in full)        | Fork as the loop-setup skeleton               | Chosen                         |
| gh CLI + GitHub remotes                  | Issues + backlog live on gh issues            | Chosen                         |
| File mirrors (`ISSUES.md`, `BACKLOG.md`) | Disclosed read-only snapshots in the repo     | Chosen                         |
| Matt's local-markdown tracker            | Fallback for repos without a remote           | Chosen                         |
| handoff skill (his copy of Matt's)       | Converge to one location-aware handoff        | Chosen (folded this session)   |
| Matt's five triage-state labels          | Workflow states for a triage skill            | Declined - no consumer         |
| Obsidian vault + obsidian-cli            | Vault-based cross-repo backlog                | Declined                       |
| Existing sprawl files (whats_next etc.)  | Mass migration now                            | Declined - migrate as touched  |

## Approach

Chosen: split by lane nature, declared per repo in one config file.

- Roadmap (planned, ordered): a file in the repo beside `docs/briefs/` and `docs/plans/` - narrative and ordering matter, churn is low, and it versions with the code it plans.
- Issues (bugs, fixes, minor refactorings): gh issues - `fixes #N` in a commit closes them with zero curation, which is exactly where files rot.
- Backlog (ideas to revisit): gh issues with the `idea` label - graduation is one `gh issue create`, bodies hold verbatim parking-lot prose, and the cross-repo view is a stock `gh search`.
- Archive: completed or superseded briefs and plans move to `docs/archive/`, keeping the working dirs live-only.
- Where I left off: the converged handoff doc at the declared repo location.
- The contract: `config/repo-state.md` declares all of the above per repo, with a one-line pointer in the repo's CLAUDE.md; repos without a GitHub remote fall back to Matt's local-markdown tracker for the gh lanes.
- Naming rationale (amended 2026-08-02 during the seam C session): the file is named for what it declares - the repo's state map - after `config/agents.md` proved misreadable as stack-behavior config; loop-stack behavior config, if it ever exists, is a separate file and currently a parked concern.

Label scheme: one load-bearing label - `idea` marks the backlog lane; unlabeled (optionally garnished `bug`/`refactor`) is the issues lane; roadmap is a file and needs no label.
Wayfinder's ticket-type labels arrive with wayfinder and layer on top; they do not change the lane scheme.

Mirror truth rule: gh is the single source of truth; mirrors are read-only snapshots whose headers disclose staleness, regenerated at handoff time or on demand - no hooks, no daemons.

Archive rules (recorded at decision time):

- A plan is done when (a) all items are complete - archive automatically - or (b) the remaining items are cleanly rewritten into a surviving plan - archive offered.
- A brief archives when its plan archives; they travel together.
- Abandoned work archives only when offered and accepted.
- Parking-lot graduation is automatic at brief-commit time.
- Every archive or graduation action is verbose: announce each moved file and each created issue with its number.

Alternatives considered: all-files (rots without curation, no free cross-repo view, cross-repo needs new tooling) and all-gh (roadmap needs ordering and narrative; duplicates the briefs/plans record into a second source of truth).

## Success criteria

- `config/repo-state.md` exists in this repo and names every lane home, the mirror regen command, the handoff location, and the archive rules `[executed-check]`
- The live parked items exist as labeled issues on this repo's GitHub `[executed-check]`
- Both mirrors exist with generation timestamp and regen command in their headers `[executed-check]`
- The cross-repo backlog command returns this repo's `idea` issues `[executed-check]`
- loop-setup runs in a bare repo with zero loop-stack conventions and produces a valid config `[executed-check]`
- `/handoff` in a conforming repo writes to the declared location and refreshes both mirrors; outside any repo it still writes to the OS temp dir `[executed-check]`
- A fresh session answers the three return-from-break questions citing only standard locations `[judgment]` - reformulation attempted; the resolvability half is covered by the config check above, and the tag survives only for briefing quality

## Seams

Blast-radius order:

1. The convention itself plus the `config/repo-state.md` format (the loop-setup fork).
2. Graduation rule: parking lot to labeled issues at brief-commit time.
3. Mirror generation.
4. Handoff convergence (location-aware write plus mirror refresh).
5. Archive rules.
6. This repo's live-item migration (the end artifact).

## Known vs guessed

- Verified: this repo's GitHub remote, gh CLI installed, Matt's setup skill structure (read in full this session), the sprawl inventory (pokemine x2, vaultwise, substack-scraper).
- Believed-unchecked: most `~/create` repos have GitHub remotes.
- Guessed: `gh search issues` covers his private repos under current auth.
  If wrong, the cross-repo view falls back to a per-repo loop - degraded, not broken.

## Parking lot

- Mass migration of the existing sprawl files (pokemine, vaultwise, substack-scraper); each repo migrates when next touched.
- Triage-state labels (Matt's five) if a triage-like skill ever lands.
- Wayfinder ticket-type labels; they arrive with seam J in the build wave.
- Seam C's pause/resume state format; B guarantees the home exists, C designs what lives there.

## Out of scope

- Chain autonomy (seam C).
- Skill-body edits applying this convention (build wave), including the handoff and loop-brainstorm deltas.
- Obsidian integration.
- Any always-running sync daemon or git hook.

## Open questions for planning

- Exact `config/repo-state.md` schema and the CLAUDE.md pointer wording.
- Whether the converged handoff moves under loop-stack repo management (install.sh symlink) or stays a hand-copied skill.
- Mirror file format details (header wording, item fields, sort order).
- Roadmap file name and its relationship to `docs/plans/` ordering.
- Exact issue body template for graduated parking-lot items (source brief link, restart context).
- Where handoff docs live in-repo (fixed name for latest vs dated directory).
