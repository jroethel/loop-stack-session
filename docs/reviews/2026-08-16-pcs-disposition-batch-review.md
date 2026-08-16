# Batch review: pcs disposition pass (2026-08-16)

Gate journal for the BATCH-gated pcs disposition pass (autonomy knob: auto).
Each BATCH entry is a decision auto-taken for the human, to accept or reverse at the end-of-chain checkpoint.

## Entries

1. **BATCH - memo destination and semantics.**
   Decision: `~/create/pcs/2026-08-15-consolidated-recommendations.md` moved (not copied) to `docs/memos/2026-08-15-pcs-consolidated-recommendations.md`, with a provenance block inserted after the Date line; the repo copy is canonical.
   Rationale: single-home-plus-pointers is a register constraint; a copy would leave two live homes. Filename keeps the original date per the docs/memos naming convention (`2026-08-10-to-loop-stack.md`).
   Reversal: `git rm` the memo and `mv` it back to `~/create/pcs/`.

2. **BATCH - archive location for the evaluation doc and kickoff prompt.**
   Decision: archived within pcs at `~/create/pcs/archive/` (not the repo's `docs/archive/`).
   Rationale: both are pcs working artifacts that never lived in the repo; the repo archive lane holds moved repo work. The memo's provenance block and the context map point at the location.
   Reversal: `mv` the two files back up one level (or into `docs/archive/` if the repo lane is preferred).

3. **Record - protocol vendoring confirmed (no action).**
   `skills/loop-molt/references/protocol.md` exists in the repo with the canonical-vendored header ("Vendored 2026-08-15 ... This copy is canonical; the pcs copy is the historical draft"); the installed `~/.claude/skills/loop-molt` resolves through `~/.agents/skills/loop-molt`. The pcs draft (`harness-drift-audit-protocol.md`) was left in place, not archived - Jeremy named only the evaluation doc and kickoff prompt for archiving; archiving the draft too is a one-command tidy if wanted.
   Reversal: n/a - no change made.

4. **BATCH - context map shape.**
   Decision: added a minimal `## Context map` section to `config/repo-state.md` carrying the pcs pointers (memo, protocol, ledger, research corpus), not the full ~20-line pointer index from recommendations Section 6.2.
   Rationale: the named task was "add the pcs pointer to the context map"; the full 6.2 index is queued future work (execution-order item 4) and building it here would be silent scope expansion.
   Reversal: `git revert`, or grow the section into the full index when 6.2 lands.

5. **ASK (pending) - the `~/create/pcs/` rename.**
   Surfaced, not decided, per instruction: `~/create/research/` does not exist; the corpus lives at `~/create/pcs/research/`, so the rename in question is of `~/create/pcs/` itself. Owner decides; the context-map line notes the pending decision and must be updated to match the outcome.
