# Import gate diagnosis: can loop-setup import file a tracker issue without a genuine human approval (#28)

This memo records the verdict for tracker issue #28: whether loop-setup's import workflow can file a tracker issue without a genuine human approval, on each of its two import paths.
The agent path is the prose disclosure in import-triage.md followed by a direct `scripts/tracker.sh create` call.
The bash path is the `reconcile_import` fallback in setup.sh, gated by `ask()`.
Every anchor below was re-confirmed against disk on 2026-08-30.

## Agent path

Finding: nothing but agent-followed prose stands between the disclosure ask and issue creation, so a skipped or hollow disclosure files issues.

Approval is defined at skills/loop-setup/references/import-triage.md:41 as "the human's explicit assent at the batch-disclosure step of this run, nothing else."
The section heading `## On approval` sits at import-triage.md:39, with its body at lines 40-53; the contract cites the section as 40-53, which is the body without the heading.
Lines 41-43 further rule that a pre-supplied classification is never approval to file, and that the proposed issue body must be shown for assent before any create.
That approval step is prose-enforced only: it binds the agent, not the code.
On assent, import-triage.md:47 has the agent run `scripts/tracker.sh create --label <label> --title <title> --body <body>` directly, in a workflow whose step list (import-triage.md:45-53) contains no other gate.

The create case at scripts/tracker.sh:431-469 parses `--label`/`--title`/`--body` (tracker.sh:432-441), resolves the mode (tracker.sh:442), and dispatches straight to the backend.
There is no approval, ask, tty, or confirm step between arg-parse and creation anywhere in that case block.
In github mode, tracker.sh:446-449 builds the `gh issue create` argument array and invokes it directly.
In gitlab mode, tracker.sh:452-460 does the same through `glab issue create --yes --no-editor`, where `--yes` is itself an explicit skip of the CLI's own confirmation.
In local mode, tracker.sh:462-463 calls `local_create`.

The full create call-tree carries no approval either.
`gh_guard` (tracker.sh:28-31) checks only that the gh CLI is present and authenticated.
`glab_guard` (tracker.sh:47-54) checks only that glab is present, that an origin remote resolves the host, and that glab is authenticated to that host.
`local_create` (tracker.sh:100-118) writes the issue file under docs/issues/ and prints the number, with no assent step.
The ungated claim rests on reading the full call-tree, not just the case block: the case block plus all three helpers it can dispatch to were read end to end, and none gates on assent.

Consequently no code detects that the disclosure step happened, and an agent that skips or hollows the disclosure table reaches creation unimpeded.

## Bash reconcile_import fallback

Finding: the LOOP_ASSUME_YES-keyed double-gate closes the env-shortcut form only; it does not make the bash path un-drivable unattended.

`ask()` (skills/loop-setup/setup.sh:9-14) returns 0 without printing when `LOOP_ASSUME_YES=1`, and returns 1 when `LOOP_ASSUME_NO=1`.
With neither env var set it falls to `read -r` at setup.sh:12, so a `y` fed on stdin also assents.

The gate chain has three decision points.
The batch gate at setup.sh:376 (`ask "review them?"`) returns before any create on decline.
The per-item gate at setup.sh:391 (`ask "import $f as a tracker issue?"`) continues past the candidate on decline.
The double-gate at setup.sh:406-409 keys ONLY on `LOOP_ASSUME_YES=1` and `LOOP_IMPORT_REMOTE != 1`.

Under the env-shortcut (`LOOP_ASSUME_YES=1`, no `LOOP_IMPORT_REMOTE`), the item is skipped at setup.sh:406-408 and nothing is filed, while the per-candidate trace at setup.sh:390 still prints.
A piped-y stdin run has `LOOP_ASSUME_YES` unset, so this gate does not fire and creation is reached at setup.sh:413.
A lone interactive `y` is by-design assent: the comment at setup.sh:404-405 states that an interactive per-item `y` in github/gitlab mode creates the issue with no extra variable.

Cross-mode caveat: the `--dry-run-remote` skip at setup.sh:396-401 is gated on `MODE != local`, so gate topology is not identical across modes.
In local mode, where that skip never fires, `LOOP_IMPORT_REMOTE` is what covers unattended creation.

The scan step has zero side effects: `--list-candidates` at setup.sh:112-115 prints the candidate paths and exits 0 before `reconcile_import` (called at setup.sh:513) can run.

Test coverage.
The env-shortcut arm is covered by scenarios C and D of tests/loop-setup/import.sh: scenario D (tests/loop-setup/import.sh:141-155) asserts that a `LOOP_ASSUME_YES` run without `LOOP_IMPORT_REMOTE` files nothing yet still prints the candidate trace, and scenario C (tests/loop-setup/import.sh:116-139) asserts the zero-side-effects scan.
The piped-stdin arm is reproduced by docs/plans/checks/bash-stdin-vector.sh, which pipes `local\ny\ny\ny\ny\n` into setup.sh with no env flag set and confirms an issue lands in docs/issues/.

The NO is scoped precisely: the double-gate makes the env-shortcut form safe, it does not make the bash path un-drivable unattended, because a piped-y stream files an issue per candidate with no env flag at all.

## Verdict

Agent path: YES, issue creation can occur without a genuine human approval.
Evidence: the approval step is prose-only (import-triage.md:39-53, defined at :41), the agent calls create directly on assent (import-triage.md:47), and the full create call-tree is ungated (tracker.sh:431-469, including the github reach at tracker.sh:446-449; helpers at tracker.sh:28-31, tracker.sh:47-54, tracker.sh:100-118).
This is the primary exposure because a mere agent-compliance lapse is enough: no code backstop exists to catch a skipped or hollow disclosure.

Bash reconcile_import fallback: the double-gate closes the env-shortcut form only.
`LOOP_ASSUME_YES=1` alone files nothing without `LOOP_IMPORT_REMOTE=1` (setup.sh:406-409, asserted by tests/loop-setup/import.sh scenario D).
It does NOT make the path un-drivable unattended: piped-y stdin files an issue per candidate with no env flag (setup.sh:12-13 feed the ask, setup.sh:391 passes the per-item gate, setup.sh:406 does not fire, creation at setup.sh:413), and a lone interactive `y` is by-design assent (setup.sh:404-405).

The bash-path vectors need a deliberate operator act, piping `y` or typing `y`, unlike the agent path's compliance lapse which needs no operator act at all.

Cross-mode caveat carried from above: the `--dry-run-remote` skip is `MODE != local` gated (setup.sh:396-401), so gate topology differs across modes.
This verdict is scoped to the observed github-mode case: the 2026-08-23 report was github-mode, the fixture reproduction here ran in local mode, and gitlab was not exercised.

## Classification of the 2026-08-23 report

Classification: indeterminate, most likely a genuine skip on the agent path.
The path it would have used is the agent path, the prose disclosure followed by `tracker.sh create`.
The agent path matches issue #28's "gates `tracker.sh create`" wording and lacks a code backstop, which makes a compliance lapse there the most likely explanation.
The original session is unrecoverable, so this is inference, to be confirmed at the human checkpoint.

## Dispositions

The three options:

1. Close #28.
2. Keep #28 parked with the diagnosis attached.
3. Build a create-time gate.

Recommendation: keep #28 parked with the diagnosis attached, because the agent-path exposure is confirmed and unmitigated while building a gate is out of scope this pass.

Deferred to a follow-up design: gate scope (remote-only vs all modes) and the /dev/tty-vs-cooperative-strengthen fork are moot this pass.
The recorded lean is to the cooperative-strengthen fork, because a /dev/tty gate fails closed under an agent-driven Bash run, where no controlling terminal is openable, and would block agent-driven import creation entirely.
