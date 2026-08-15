# Molt drift ledger

The repo's harness-drift ledger, written by /loop-molt (see `skills/loop-molt/`).
One entry per audited artifact per audit, appended - never rewritten.
Each entry records the harness snapshot the audit was run against, so the next audit diffs from a known point instead of re-researching from zero.

Per-entry shape:

```
## YYYY-MM-DD - <artifact path>
- Harness snapshot: <date + what was probed/scanned>
- Deleted: <bin> N (...), <bin> N (...)
- Kept as policy: N (invariant each protects)
- Premises: <verified / rewritten in place / re-confirmed as constraint>
- Constraints re-confirmed: <list>
```

<!-- entries below, newest last -->

## 2026-08-15 - skills/handoff/SKILL.md
- Harness snapshot: 2026-08-15, thin refresh (Claude Code current, Opus 4.8); no live probe - smoke run validating /loop-molt on a lean 21-line artifact.
- Deleted: none this pass (subtraction test not run; a smoke run does not edit a shared artifact).
- Candidates flagged for a real audit: choreography x2 - the "reference by path, don't duplicate" line and the "if the user passed arguments, treat as focus" line (both are judgment a frontier model applies unprompted); each needs the subtraction test + owner review before removal.
- Kept as policy: 4 - purpose/outcome contract; repo-placement convention (harness does not know config/repo-state.md unprompted); required suggested-skills section; redaction/safety invariant.
- Premises: none classified expired, so the constraint-register ASK gate had nothing to confirm this pass.
- Constraints re-confirmed: none contested (smoke run).
- Verdict: handoff is near "done molting" - lean, mostly policy; two cheap choreography candidates remain for the next real pass.

