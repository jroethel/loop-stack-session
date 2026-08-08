# Batch review: audit-sweep drive phase (2026-08-08)

Gate journal for the /loop-which and /loop-drive legs of the audit-sweep chain, under `auto` (session).
Each entry: decision, rationale, reversal path.

## 1. DEFAULT - loop-which verdict taken (auto-taken)

- Decision: verdict ONE AGENT for docs/plans/2026-08-08-audit-sweep-plan.md; handed to /loop-drive with the run-card.
- Rationale: seven S-effort tasks fit one pass (the team threshold "too large for one pass" is not met); checkability is carried by executed checks, so team separation buys nothing; the step-2 availability questions were all answerable from context and the wired `~/.config/ringer/config.toml`, so the ASK gate had nothing to ask.
- Reversal: cheap - re-run /loop-which with different constraints, or execute the plan by hand; it stands alone.

## 2. BATCH - transport and model lean (auto-taken)

- Decision: single unit routed as sonnet-5 implementer on the Agent tool, opus validator (native-validator pin, high effort), task_type code-fix.
- Rationale: transport pinned to Agent tool because the deliverable is the plan's mandated seven-commit series (ringer patch-export flattens commit history) and repair rides SendMessage; with GLM ringer-only, no scoreboard posterior covers the Agent-tool roster, so the chain fell to the benchmark prior, which names sonnet-5 the default execution worker and warns Opus off quota-thin routine execution.
- Reversal: taste lean - scoped relaunch with an opus implementer (or a ringer/glm-5.2 manifest accepting a flat patch) if the sonnet run disappoints.

## 3. DEFAULT - pre-flight proceeded past an untracked editor artifact (auto-taken)

- Decision: proceeded to launch with `docs/briefs/.2026-08-08-audit-sweep-brief.md.swp` (vim swap file) untracked in the tree; left the file untouched.
- Rationale: the dirty-tree STOP invariant protects uncommitted work that a worktree launch could lose or bypass; tracked content is fully committed at `18b289a`, an untracked swap file does not enter a worktree, and deleting or committing someone's live editor artifact would be worse than noting it. If the swap file holds unsaved brief edits, they arrive as a later brief revision with journaled reversal paths; the worker executes the committed plan, not the brief.
- Reversal: cheap - if unsaved brief edits surface, re-run the affected pipeline leg from the revised brief; every downstream artifact names its source commit.

## 4. DEFAULT - Step 7 launch without the details ask (auto-taken)

- Decision: skipped the "see execution details?" AskUserQuestion, ran the dry-run pre-flight directly (tracked tree clean, gh authed, ringer probed, worktree-able), and launched wave 1.
- Rationale: the ask is DEFAULT-class; nothing selected means launch immediately, and the dashboard, dry-run results, and watch points are all recorded in `docs/plans/2026-08-08-audit-sweep-plan_loop.md` and this journal for after-the-fact review.
- Reversal: cheap - stop the run at the gate; the worktree branch preserves whatever landed.

## 5. DEFAULT - gate pass and mainline advance (auto-taken)

- Decision: opus validator passed all five criteria (independent rerun, plan conformance, scope audit, pre-existing-failure claim verified by second route, house style); merged `audit-sweep` into the integration branch, full suite went 30/30, fast-forwarded main to `efed031`, pruned the worktree and branches.
- Rationale: advancement requires a green integration branch; it was green after the gate fix below.
- Reversal: cheap - `git revert` the merge range; the pre-run base is `18b289a`.

## 6. BATCH - out-of-plan gate fix: loop-review no-spec phrase (auto-taken lean)

- Decision: the new runner exposed a pre-existing failure (`tests/loop-review/acceptance.sh:16`); root-caused to the doctor-plus trim (`42ece73`) dropping the test-guarded literal phrase "no spec available" from `skills/loop-review/SKILL.md:43`; restored the phrase in one line as commit `efed031`, outside the sweep's task scope.
- Rationale: the standing instruction is that a seen test failure gets fixed even when unrelated; the test is ground truth (it and the skill shipped together in `a23c27c`, and its behavioral layer asserts the same wording in real output); blast radius is one prose line.
- Reversal: cheap - `git revert efed031`; the suite then reports the pre-existing failure again.

## 7. DEFAULT - receipts and advisory terminal review (auto-taken)

- Decision: committed the MODEL-NOTES receipt for (sonnet-5, code-fix) in the ringer repo (`e7e4ae0`); ran the advisory `/loop-review 18b289a` with the plan as explicit spec source: Spec axis zero findings, Standards axis zero violations plus three cosmetic judgment-call smells (duplicated label-branch shape in `scripts/migrate-tracker.sh:57-70`, the `set +e`/`set -e` toggle and the redefined EXIT trap in `tests/run/acceptance.sh`), recorded here as the final checkpoint list.
- Rationale: receipts close the gate across both repos; the terminal review is advisory and non-blocking by design.
- Reversal: n/a - record-only; the smells are backlog-grade polish if ever worth doing.
