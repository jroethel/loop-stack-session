# Wave 3 summary - B32 jrit-loop port

Date: 2026-09-13.
Units: U04 (helper), U05-U07 (skill ports), U08 (loop-setup), U11a (sweep staging), plus scoped repairs W3POLISH, U11AFIX, U04FIX.

## Results

| Unit | Ringer | Validator | Final | Repairs |
| --- | --- | --- | --- | --- |
| U04 | TIMEOUT x2 (transport) | fail: done success path broken | fixed by U04FIX, harvested, merged | 2 |
| U05 | pass 1 | pass 5/5 | merged | 0 |
| U06 | pass 1 | pass | merged | 0 |
| U07 | pass 1 | pass 14/14 | merged | 0 |
| U08 | FAIL x2 (check bug) | pass 6/6 | harvested, merged | 0 real |
| U11a | pass 1 | fail: sort-dependent comment target | fixed by U11AFIX, packet corrected | 1 |
| W3POLISH | pass 1 | executed check + diff-read | merged | 0 |
| U11AFIX | FAIL x2 (check bug) | executed check (corrected) | harvested | 0 real |
| U04FIX | TIMEOUT x2 (60s check ceiling) | executed check standalone, all gates 0-7 live | merged | 0 real |

Main: `run-all` exit 0 at HEAD; pushed. Validation worktrees pruned.

## Substantive catches this wave

1. U04 validator: the SLOC squeeze dropped `keep="${2:-}"` in clear_status, killing the done verb's SUCCESS path under set -u; agent:done was reachable by no route. Plan's gate set never tested a successful done. Fixed; Gate 7 added to the plan (in-place edits, no line shift) and to the test; proven live.
2. U11a validator: the #3 migration-note capture depended on list sort order (gh sorts by preserved created_at; #3 is the oldest issue). Packet now transfers #3 solo, captures every transfer URL for the migration map, and has a real STOP after the dry-run.
3. U04FIX root-caused this host's 25-minute test runtime: the WSL resolver stalls ~10s per AAAA query and gh pays it on every call; the test now pins GitHub hosts A-only in an unshare namespace (25min -> 75s), no system files touched.
4. Interim unsatisfiability: U04's helper creates skills/loop-drive/ before Task 9 creates its SKILL.md; version-drift's per-dir assertion went red on main. Fixed with the approved skip-while-pending pattern (skip gated on the SKILL.md itself; first cut wrongly gated on the directory count and was corrected).

## Orchestrator check bugs (3 this run, distilled)

Unset TASKDIR; porcelain without -uall; unanchored sed address. All caught by workers or validators, all fixed at the gate, all annotated in MODEL-NOTES so no model row is poisoned. New template rule: every orchestrator check gets a fail-first probe against a known-bad tree before it gates a worker.

## Slip notes (downstream review / v1 list)

- Helper gitlab arms have never executed (GITLAB_TEST_PROJECT unset on this host); a real GitLab run belongs on the pre-v1 list.
- ringer.py hardcodes CHECK_TIMEOUT_S=60 with no override; long-running checks are impossible under ringer and were harvested manually this run. Candidate ringer backlog item.
- Host finding for Jeremy: WSL AAAA resolver stall (~10s per lookup) taxes every gh call on this host, far beyond this run.
- Marketplace entry version key is now valid; optional third drift surface for criterion 7.
- Cosmetics deferred: loop-auto near-duplicate default/where-it-lives sections; wayfinder's gh flag claims unversioned; grammar test stricter than D4 on empty labels lines.

## Pending human gates

C8 (fire the corrected sweep packet) presented at this gate close. C5 not triggered (SLOC 196). delete_repo verified present.
