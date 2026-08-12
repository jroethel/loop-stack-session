# Handoff: triage of the gitlab-fallout bundle into seams A/B/C/D

Date: 2026-08-12
Session: /loop-brainstorm over backlog #10/#22/#23 and issues #19-27, driven by docs/memos/2026-08-10-to-loop-stack.md
State: two seams closed (C, D), one brief written and committed (B), one seam still open and unstarted (A). No code beyond the SKILL.md doc edit; A is the remaining build work.

## Where things stand

The 10-item bundle was a trenchcoat of four seams, not one idea.
Two are fully resolved, one has an approved committed brief ready to plan, and one is untouched and plan-ready.

| Seam | Items | Status | Next action |
| --- | --- | --- | --- |
| A. gitlab correctness | #19, #25, #26, #27 | Open, unstarted | `/loop-plan` after a freshness re-check (see caveat) |
| B. import governance | #20, #21 | Brief committed | `/loop-plan` on the brief below |
| C. mode expansion | #22, #23, #24 | Done | none - closed |
| D. reconcile posture | #10 | Done | none - closed |

There is no fifth seam: A/B/C/D exhausts all 10 bundle items and all 5 memo findings.

## Artifacts

| Artifact | Path / ref |
| --- | --- |
| Source memo | `docs/memos/2026-08-10-to-loop-stack.md` (5 findings) |
| Seam B brief | `docs/briefs/2026-08-11-import-governance-brief.md` (commit 50edafa) |
| Seam C shipped edit | `skills/loop-setup/SKILL.md` "Tracker modes" section (commit 1e53d3f) |
| New backlog item | idea #28 (B's parked `/dev/tty` gate) |

## What was decided this session, and why (do not relitigate)

- D (#10) was already shipped by the 2026-08-07 loop-setup-reconcile brief/plan/drive, not by today's triage work; all five gaps are in code with tests. Closed as done.
- C (#22) `none` mode: declined. github/gitlab/local are enough. Closed won't-do.
- C (#23) combinations: "remote for code, local tracking" is already supported via `tracker: local` + `tracker-remote-ack:` (verified at setup.sh:370-384); no multi-backend mode will be built. Documented in SKILL.md, closed.
- C (#24) agent-facing mode list: shipped as the SKILL.md "Tracker modes" block (all three modes, viability caveats, present-verbatim instruction). Closed.
- B (#20) brief-import: chosen approach is a minimal `--seed <file>` flag feeding a named excluded doc into the sweep; rejected `--scan` override (overloads the flag) and doc-only (leaves the setup-later case unserved).
- B (#21) approval gate: chosen approach is sharpened prose in import-triage.md, not a hard gate; a `/dev/tty` enforcement gate was rejected as an adversary assumption for a cooperative attended-only tool (no in-band token is agent-proof, since `ask()` reads stdin) and parked as #28.

## Exact next actions

1. Seam A - `/loop-plan` the four issues #19, #25, #26, #27.
   First run the freshness re-check: the memo verified against source on 2026-08-10 but the four have not been re-checked against current code this session, and D showed how a shipped item can sit open. Confirm each is still unfixed before planning its fix.
   The one real design decision inside A: whether to fix #19 as a per-line rewrite in `render_gitlab`, or make the template backend-neutral with a `{{BACKEND}}` token (kills the render-leak bug class across all renderers, also covers the old #10.5 mirror defect). This is A's approach fork - surface it in planning.
2. Seam B - `/loop-plan` on `docs/briefs/2026-08-11-import-governance-brief.md`. The brief's Open questions for planning are the first things to resolve there.

## Resume prompt (paste-ready)

```
Resuming loop-stack work. Read docs/handoffs/2026-08-12-gitlab-fallout-triage.md.
Seams C and D are closed; Seam B has a committed brief; Seam A is unstarted.
Do Seam A next: freshness-check #19/#25/#26/#27 against current code, then /loop-plan
them, surfacing the render_gitlab per-line-fix vs backend-neutral-{{BACKEND}}-template
approach fork. Then /loop-plan the Seam B brief. Do not rebuild C or D.
```
