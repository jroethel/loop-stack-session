# Brief: tracker-item tokens in doc filenames

## Outcome

A person or agent scanning `docs/` can map any brief, plan, handoff, or review to its tracker item, and go from an item number back to its docs, without opening the tracker.
The presupposition in the proposal - that "R4" behaves like "I6" - is rejected: roadmap section numbers reorder, so roadmap items need a stable `R<n>` decoupled from list position, whereas GitHub issue numbers (`B`/`I`) are already stable.

## End artifact

This is doctrine tooling; the first real deliverable it unblocks is the next doc created after it lands, which carries its token and is greppable by item from day one.

## Done looks like

New docs are named `<date>.<token(s)>.<slug>.md`, for example `2026-08-22.I6.config-landscape.md`.
`ls docs/briefs | grep '\.I6\.'` returns every brief for issue 6.
A doc whose item is not logged yet stays `<date>.<slug>.md` and gains its token when the item is created.

## Assets and options

| Asset                        | Implied option                          | Decision                                     |
| ---                          | ---                                     | ---                                          |
| GitHub issues (Issues lane)  | `I<n>` token, stable number             | Chosen                                       |
| GitHub issues (`idea` lane)  | `B<n>` token, same namespace as I       | Chosen; letter marks the lane the number hides|
| ROADMAP.md numbered sections | `R<n>` token                            | Chosen, but needs a stable assigned ID       |
| Existing `YYYY-MM-DD-` docs  | rename retroactively                     | Declined - new docs only                     |
| docs/reviews batch reviews   | include in the convention               | Chosen                                       |

## Approach

Chosen: the linkage lives in the filename itself, `<date>.<tokens>.<slug>.md`, documented in `config/conventions.md` and enforced by a lint check.
Considered and rejected: a sidecar index or doc front-matter (keeps date+slug names but is invisible in a directory listing, failing the at-a-glance goal), and tracker-side linking only (zero filename change but requires opening the tracker to map either direction).
Rationale: the outcome is filesystem-visible association, which only the filename carries; the other two solve linkage without visibility.

## Success criteria

- A logged-item doc filename matches `^\d{4}-\d{2}-\d{2}(\.[BIR]\d+)+\.[a-z0-9-]+\.md$` `[executed-check]`
- Listing all docs for a token, and reading the token off a filename, are each one grep `[executed-check]`
- Each roadmap item carries a unique `R<n>` that a reorder does not change `[executed-check]`
- `config/conventions.md` states the pattern as the single source of truth `[executed-check]`
- A freshly created brief, plan, handoff, or review for a known item lands with the token `[executed-check]`

## Seams

1. The filename grammar, defined in `config/conventions.md` - everything else depends on it.
2. The stable roadmap `R<n>` mechanism - independent of the doc-naming changes.
3. The doc-creating skills and generators emit the token (brainstorm, plan, handoff, review).
4. A lint check flags non-conforming new docs; existing docs are exempt.

## Known vs guessed

- Verified: current naming is uniform `YYYY-MM-DD-<slug>.md`; Issues and Backlog share one GitHub number space; roadmap items are reorderable numbered sections.
- Believed-unchecked: exactly which scripts and skills build handoff and review filenames - not yet grepped.
- Guessed: none load-bearing.

## Parking lot

None raised.

## Out of scope

Renaming existing or archived docs; changing tracker backends or issue numbering; tokens on root ALL-CAPS or config files.

## Open questions for planning

- How stable roadmap `R<n>` IDs are stored (inline tag versus manifest) and assigned (monotonic, never reused).
- Multi-token spelling for a doc spanning items: separate segments (`.I6.I7.`) versus joined (`.I6-I7.`) - recommend separate, parsed as leading segments matching `[BIR]\d+`.
- Which generators build handoff and review names, and where each constructs the string.
- Extend `scripts/lifecycle-lint.sh` with a filename-conformance class versus a standalone check.
- The rename-on-log trigger for a doc created before its item existed.
- Reconcile the existing `-batch-review` review suffix with the new slug segment.
