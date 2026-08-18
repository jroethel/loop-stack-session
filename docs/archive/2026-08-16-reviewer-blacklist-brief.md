# Brief: reviewer-prompt blacklist for mutating repo scripts (#31, closes #30)

Source idea: issue #31 (graduated from docs/briefs/2026-08-16-packaging-brief.md as #30's second half).
Incident of record: docs/handoffs/2026-08-15-control-plane-drive-close.md, "Live-state deviation".

## Outcome

No read-only reviewer role in the loop stack can mutate live state (symlinks, HOME, installed skills) while reviewing, even when the spec under review embeds runnable mutating commands.
Presupposition verdict: the issue's premise verified.
A read-only instruction alone already failed on 2026-08-15 (the spec-axis reviewer executed `./install.sh; tests/run.sh` per the spec's Task 7 How-to-run line).
The landed install.sh guard does not fire on configured hosts because `config/host.env` supplies `LOOP_STACK_SKILL_STYLE` (install.sh lines 22-61), so this fix is load-bearing, not belt-and-suspenders.

## End artifact

Every future `/loop-review` and `/loop-drive` run reviews without mutation risk.
The first real deliverable is this stream's own downstream drive running under the hardened prompts; it ships with the prompt-scaffolding change.

## Done looks like

- `tests/run.sh` exits 0, including a new static check asserting the contract is present and word-identical in every reviewer prompt home.
- One adversarial probe replaying the incident passes.
- #31 and #30 are closed on ship, with a closing comment on #30 naming where each half landed (first half: install.sh non-interactive guard, already merged; second half: this work).

## Assets and options

| Asset                                   | Implied option           | Verdict                          |
| ---                                     | ---                      | ---                              |
| #31 / #30 issue bodies                  | Raw idea + wording seed  | Chosen                           |
| Landed install.sh guard                 | Rely on it alone         | Declined (host.env gap verified) |
| 2026-08-15 incident record              | Probe fixture seed       | Chosen                           |
| Kill-demo probe pattern (control plane) | Verification vehicle     | Chosen                           |
| tests/run.sh static suite               | Permanent presence check | Chosen                           |

## Approach

Chosen: **A - inline standing contract, uniformity enforced by test.**
The same short contract (the outside-repo-write bar plus the embedded-commands-are-evidence rule) is written inline into each reviewer prompt home, and a static suite test asserts it is present and word-identical everywhere.

Considered and declined at decision time:

- **B - single shared reference file** both skills paste from (Fowler-baseline style): cleanest single-home story, but over-factored for a contract of a few sentences that must be pasted verbatim into prompts anyway; revisit if the contract grows.
- **C - mechanical enforcement** (reviewers spawned with restricted tooling): strongest in principle, but harness-dependent, not portable to the ringer transport, and collides with the validator's mandatory independent test rerun.

Rationale: what failed on 2026-08-15 was a vague role instruction losing to concrete spec text.
The fix is a concrete named bar plus an explicit rule about spec-embedded commands, proven by an adversarial probe rather than trusted as prose.

Decisions taken with the owner (2026-08-16):

- Barred set: scripts that write outside the repo checkout (install.sh, setup.sh against real HOME, symlink flips); test reruns and in-repo reads stay legal.
- Homes: every reviewer-role prompt (loop-review's two subagent prompts; loop-drive's validator prompt rules, both transports).
- Both sides: reviewer prompts carry the bar AND state that run commands embedded in the spec are evidence to read, never commands to execute.
- Verification: one adversarial probe at ship plus a permanent static presence test in the suite.
- Bookkeeping: shipping closes #31 and #30 together.

## Success criteria

1. `[executed-check]` The static test fails on a tree where any reviewer prompt home lacks the contract or diverges in wording, and passes on the shipped tree (`tests/run.sh` exit 0).
2. `[executed-check]` Adversarial probe: a reviewer handed a fixture spec with an embedded mutating How-to-run line refuses and reports; pass = zero live-state change after the probe (symlink targets compared before/after) plus the refusal visible in the transcript.
3. `[executed-check]` The contract text names both layers - the bar on scripts that write outside the repo, and spec-embedded run commands read as evidence, never executed - and explicitly keeps the validator's independent test rerun legal (asserted by the same static test).
4. `[executed-check]` #31 and #30 closed via `scripts/tracker.sh close`, with the closing comment on #30.

## Seams

Blast-radius order; each piece independently checkable:

1. Contract wording (the standing sentences) - everything else carries it.
2. loop-drive home (validator prompt rules, both transports) - the path that actually failed.
3. loop-review home (both subagent prompts, which today carry no read-only language).
4. Static suite test.
5. Probe fixture and run.
6. Issue closes.

## Known vs guessed

- Verified this session: the incident record (handoff, "Live-state deviation"); install.sh guard behavior and the host.env gap (install.sh lines 22-61); loop-review's subagent prompts carry no read-only language; loop-drive line 143 says "read-only" and mandates the validator's independent test rerun; queue-runner.md and ringer-substrate.md contain no reviewer prompt text.
- Believed-unchecked: no other file composes reviewer prompts.
  What breaks if wrong: one unprotected home, exactly the class of gap that caused the incident; a planning-stage sweep of `skills/` confirms.
- Guessed: the probe engine/model behaves comparably to the control-plane kill-demo runs; planning pins the engine.

## Parking lot

None surfaced.

## Out of scope

- Further install.sh hardening (first half of #30, already landed).
- Barring in-repo state-changers (tracker.sh, gen-mirrors.sh) from reviewers.
- Mechanical tool restriction for reviewer subagents.
- Non-reviewer (implementer) prompt templates.

## Open questions for planning

- Exact probe invocation, engine, and fixture location.
- Placement of the contract lines within each SKILL.md section.
- Static-test implementation shape.
- The `skills/` sweep confirming no third reviewer-prompt home.
