<!-- generated: 2026-08-04T13:44:44Z -->
<!-- regenerate: scripts/gen-gate-registry.sh . -->
<!-- DO NOT EDIT -->
<!-- This registry reflects tagged gates only and is not a completeness guarantee. -->

# Gate registry

| skill | type | trigger |
|---|---|---|
| loop-brainstorm | ASK | ## Step 3 - Clarifying questions |
| loop-plan | ASK | ## Step 2 - Resolve the open questions |
| loop-which | ASK | ### 2. Ask what's actually available |
| loop-drive | STOP | Effort: cap everything at **high**; exceeding high requires an explicit ... |
| loop-drive | STOP | - **Dirty working tree**: worktrees branch from committed state only; pr... |
| loop-drive | STOP | Resolve stopped units: a small spec issue means edit the spec artifact a... |
| loop-drive | STOP | Any request to exceed the effort cap stops and asks the human. |
| loop-drive | STOP | A larger edit, or one touching multiple units, a global constraint, or a... |
| loop-drive | STOP | Any outward-facing unit (touches live consumers, publishes, or deletes t... |
| loop-drive | BATCH | If two shapes are close (roughly 60/40 or tighter), diagram both, name y... |
| loop-drive | BATCH | A spec edit confined to a single unit or criterion, leaving unchanged wh... |
| loop-drive | BATCH | This review is advisory and non-blocking - the per-unit validators alrea... |
| loop-plan | BATCH | The user picks which findings get incorporated; revise the plan; re-run ... |
| loop-brainstorm | DEFAULT | ## Steps 5-6 - The brief |
| loop-brainstorm | DEFAULT | ## Step 8 - User review gate |
| loop-brainstorm | DEFAULT | ## Step 9 - Terminal state (pinned) |
| loop-drive | DEFAULT | When the user approves execution (including the single-artifact exits fr... |
| loop-plan | DEFAULT | ## Step 6 - The Rubix review (optional) |
| loop-plan | DEFAULT | ## Step 7 - User review gate |
| loop-plan | DEFAULT | ## Step 8 - Hand off (pinned) |
| loop-which | DEFAULT | ### 5. Give the verdict |
