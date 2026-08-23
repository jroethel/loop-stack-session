# Lifecycle-lint "done" gate - handoff

Jeremy gave feedback: after declaring a chain/run "done" twice in an unrelated repo session, he still had to ask "roadmap #11 need to be closed? docs archived?" - the tooling to catch this (`scripts/lifecycle-lint.sh`, the archive/graduation rules) already existed, it just never ran at the "done" moment, only at handoff.

Fix in progress: a new doctrine rule (6) in `config/conventions.md`/`.template.md`'s Archive and graduation rules section - declaring a task/run/chain "done" runs `scripts/lifecycle-lint.sh .` first and resolves what it clearly implies, asking only on genuine ambiguity. `template-version` bumped 4 -> 5 so `/loop-setup`'s reconcile offer will carry this to every other loop-stack-conforming repo (including the one the original feedback came from) on its next run. `scripts/lifecycle-lint.sh`'s header comment updated to name the new trigger point.

## What happened, and the collision

Mid-session, a **second live session on this same repo reverted these 5 uncommitted edits** (working tree reset to HEAD for those files, no commit, no stash - the harness flagged it as an external change). Reapplied the edits and staged them (`git add`) rather than committing immediately, to reduce collision risk.

The other session was mid-plan for a follow-on generation (template-version 6, filename grammar) touching the same 5 files. Coordinated by hand through the human relaying messages between sessions (the gap that prompted issue #45 below). Its recap flagged one real blocker: `tests/loop-setup/reconcile.sh:81` hardcoded `template-version: 4` in an assertion, which fails the instant this change bumps the version to 5. Verified: full suite was 47/48 before the fix.

Fix applied: added `TPL`/`TV` (derived from `config/repo-state.template.md`, same pattern as `tests/loop-setup/docs-gitlab.sh:84-85`) and replaced the hardcoded `template-version: 4` assertion with the dynamic `$TV`. `bash tests/run.sh` now reports 48/48. Landed and committed alongside the doctrine change.

## Status: committed

All 7 files (5 doctrine-change files + this handoff + the reconcile.sh test fix) committed together. Verified before commit:
- `bash tests/run.sh` - 48/48
- `bash scripts/lifecycle-lint.sh .` - exit 0
- `diff config/conventions.md config/conventions.template.md` - identical (invariant preserved)

## Remaining, separate from this work

A target roll to push template-version 5 (and whatever the other session's generation-6 lands as) out to already-set-up repos - same shape as `docs/handoffs/2026-08-20-config-v4-target-roll.md`, so existing repos get the reconcile offer next time `/loop-setup` runs there. Deliberately not done in this session - scope was the doctrine fix itself, not the propagation sweep. The other session's own target roll was already planned to happen later regardless, and may carry both generations at once.

## Filed alongside this

The collision itself is worth solving generally - filed as backlog idea **[#45](https://github.com/jroethel/loop-stack-session/issues/45)**: session coordination (check-before-modify, and a way to communicate action ownership between concurrent sessions on the same repo), extending the existing `tracker.sh claim`/`AGENT STATUS` receipt pattern from tickets to arbitrary files/actions. Design not started - parking-lot idea only. `BACKLOG.md`/`ISSUES.md`/`WAYFINDER.md` mirrors regenerated to reflect it (first two are gitignored in this repo, so they won't show in `git status`).

## Suggested skills

- `loop-setup` - for the eventual template-version-5 target roll to other repos.
- `loop-auto` - if the session-coordination idea (#45) gets picked up, it's adjacent to the existing claim-receipt/gate-class machinery loop-auto and loop-drive already define.
