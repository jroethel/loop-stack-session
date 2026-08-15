# Executable probe log - slim/fold/dedup drive (Tasks 4, 6, 7)

Recorded outputs of the per-commit executable probes (Rubix B4), so a later bisect can localize any
shaping/compile degradation to the commit that introduced it, not only to Task 14's human checkpoint.
Each probe was dispatched to a fresh-context down-tiered (sonnet) subagent that read the slimmed
artifact and ran it non-interactively on a toy input.

## Task 4 - brainstorm front door on "add a --dry-run flag to tracker.sh"

Confirms the slim kept the shaping lane: a triage verdict, then a shaped brief skeleton
(Outcome / Done / Success criteria with checkability tags / Seams).

```
One-Minute Test verdict: ONE AGENT
Reason: one clear goal (add a --dry-run flag to scripts/tracker.sh that reports intended file
writes / gh/glab calls without executing them) requiring a repo file edit and a runnable check,
inspectable by one person in a single pass.

Outcome
tracker.sh gains a --dry-run flag so a user can preview what a subcommand (create, set-state) would
do - which issue file it would write, what frontmatter it would change, which gh/glab call it would
make - without any of those side effects actually happening.

Done looks like
Running scripts/tracker.sh <subcommand> --dry-run [args] prints the planned action(s) to stdout and
exits 0, with no issue file created or modified, no local_set_state write, and no gh/glab network
call made. Running the same command without --dry-run behaves exactly as today.

Success criteria
- --dry-run on a create-style call prints the would-be file path and next issue number, and no file
  is written under the issues directory afterward. [executed-check]
- --dry-run on a set-state-style call prints the target file and the state transition, and the file's
  state:/updated: frontmatter is byte-identical before and after. [executed-check]
- --dry-run never calls gh_guard/glab_guard or any gh/glab command. [executed-check]
- Output is unambiguous enough that a user trusts the preview matches real behavior. [judgment]

Seams
- Flag parsing/plumbing (recognize --dry-run, thread it through the case dispatch) is independently
  checkable from the per-subcommand preview logic.
- Each subcommand's dry-run preview (local_create, local_set_state, the gh/glab-backed paths) is its
  own checkable piece, since each guards a different side effect.

Assumption flagged (conservative, autonomous mode): scope limited to the local subcommands already in
scripts/tracker.sh; no new subcommands or remote-API dry-run semantics beyond "don't call gh/glab".
```
