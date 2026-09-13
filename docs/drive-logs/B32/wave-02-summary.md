# Wave 2 summary - B32 jrit-loop port

Date: 2026-09-13.
Units: U03 (T3 CI checks), glm-5.3, ringer claude-zai, code-feature.

## Results

| Unit | Implementer | Acceptance | Validator | Repairs |
| --- | --- | --- | --- | --- |
| U03 | pass, attempt 2 (run `jrit-loop-port-20260913T163906Z-p1132977`) | rerun by validator on the validation worktree, exit 0 | spec-problem, artifact merged, plan defect escalated | 1 (check bug, not worker) |

Merged to main as `CI: structure, budget, version drift, secrets, and consumer checks plus the push workflow`; `bash ci/run-all.sh` on main exit 0; tag `b32-w3-base` cut and pushed.

## Attempt-1 attribution: ORCHESTRATOR CHECK BUG

The check assumed a `TASKDIR` env var ringer never sets; `set -u` killed it before the patch export.
Worker output was correct; the retry's one-line fix to the check was audited byte-for-byte (a TASKDIR default, nothing weakened) and accepted.
Template fixed for all future checks: `TASKDIR="${TASKDIR:-$PWD}"`.

## Validator findings

1. BLOCKING (spec-problem, gates Task 9 / wave 4, not wave 3): plan Check D (line 710) requires the literal `docs/loop/pointer.md` in skills/loop-drive/SKILL.md; plan Check H (line 714) bans regex `/loop($|[^a-z-])` there, and the `/` inside the path matches it. Proven mutually unsatisfiable by probe, both directions. STOP to Jeremy; validator recommends amending Check H with a leading boundary (still catches `Run /loop to resume.`).
2. NOTES overstated ci/single-resolution.sh: the claimed multi-record-path failure branch is not implemented (narrow criterion-12 hole, Task-14-only). Queued into scoped fix unit U03b.
3. Check G em-dash sweep covers skills/ only; the plan says every shipped markdown file. Coverage gap, nothing violating today. Queued into U03b.

## Distilled

- All future checks self-locate with the TASKDIR default; check-bug annotated in MODEL-NOTES so the scoreboard is not poisoned.
- U03's straggler list (principles.md, bare brief-pipeline.md) already baked into U05's wave-3 spec.
