# Batch review - setup-lint-vendor run

Run: one-task ringer manifest (`setup-lint-vendor-20260818T053924Z`), autonomy auto (session), orchestrator Fable; follows the user's "go ahead" on vendoring `lifecycle-lint.sh` into loop-setup.

## Gate journal

1. BATCH - routed as a one-task ringer manifest on the standing engine pin (claude-zai glm-5.2, sonnet on any 529 - none occurred; PASS attempt 1, 97s).
   Rationale: same shape as the context-map run; four fully-specified verbatim edits with executed checks.
   Reversal: `git revert 16f11ac`.
2. DEFAULT - template-version bumped 2 to 3 so existing repos get the assented re-render offer carrying rule 1a; this repo's `repo-state.md` synced to 3 in the same change to avoid a spurious offer here.
   Rationale: `reconcile_config` only offers on version mismatch; without the bump the template edit reaches nobody.
   Reversal: part of the same revert.
3. STOP-class miss, orchestrator-owned (recorded honestly): the custody check ran only three loop-setup suites, so the two gitlab suites' hardcoded `template-version 2` assertions failed at the gate's full-suite run - AND the gate's `&&` chain piped through `tail`, masking the non-zero exit, so a red suite reached a commit before being caught on the printed tally. Fixed forward inline: both assertions now derive the expected version from the template (never pinned), suite re-run 46/46 with the exit code captured plainly, test fixes amended into the single commit.
   Rationale: worker blameless (its four edits were exact); both defects were orchestrator check-authoring gaps.
   Reversal: n/a - the lesson lines land in MODEL-NOTES; the amended commit is atomic and green.

## Evidence

- Worker patch: exactly the four owned files; diff-read clean against the spec's verbatim blocks.
- Distribution test now proves install + content match + assented drift restore for `lifecycle-lint.sh`.
- Final: `tests/run.sh` exit 0 (46/46), `lifecycle-lint.sh .` exit 0, commit `16f11ac`.
