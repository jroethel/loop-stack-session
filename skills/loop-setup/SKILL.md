---
name: loop-setup
description: Declare a repo's tracker mode, write its repo-state map (config/repo-state.md), and run the mode-appropriate finalize. Run once per repo, safe to re-run.
---

# loop-setup

Bootstraps the repo-state convention in the current repo.
The runnable, idempotent core is `setup.sh` next to this file; this skill narrates and invokes it.

## Tracker modes

setup.sh supports three tracker modes: `github`, `gitlab`, and `local`.
When an agent fronts the mode question in its own UI instead of letting setup.sh's stdin prompt through, it presents all three verbatim - never paraphrasing the list or silently dropping one - and states each one's viability caveat so the user can see which are usable in this environment:

- `github` - needs an authenticated `gh` CLI (`gh auth status`).
- `gitlab` - needs an origin remote to resolve the host, plus `glab` authenticated to that host (`glab auth status --hostname <host>`).
- `local` - no external dependency; issues live in `docs/issues/`.

There is deliberately no `none` (tracker-off) mode: `local` already runs with zero external dependency, so a repo that wants no remote tracker chooses `local`, which supersedes `none` in every case.

Remote for code, local tracking: to run a repo whose code lives on a github or gitlab remote but whose issues stay local, choose `local` and add a `tracker-remote-ack: <github|gitlab>` line to config/repo-state.md.
That line acknowledges the deliberate mode-versus-remote split and silences setup's switch offer; it is the supported way to pair a remote codebase with local issue tracking, and no multi-backend "combination" mode exists or is planned.

## What it does

1. Writes `config/repo-state.md` by rendering `config/repo-state.template.md`.
   The template is the single schema source; never hand-copy a second schema.
2. Declares the tracker mode - it does NOT infer it from `git remote`.
   If `config/repo-state.md` already carries a `tracker:` key, setup skips the question entirely (idempotent, never re-asks the mode).
   When the declared mode disagrees with a github or gitlab remote, setup prints "declared tracker: X, but the remote is Y" and offers a declinable switch to the remote's backend.
   The offer is silenced by a `tracker-remote-ack:` line in the config - a hand-written acknowledgment of a deliberate mode-versus-remote disagreement that `setup.sh` never writes itself.
   Otherwise it reports the remote status, asks the mode once (`github`, `gitlab`, or `local`), and writes the key via `tracker.sh mode set`.
3. Creates the docs homes: root `ROADMAP.md`, `docs/handoffs/`, `docs/reviews/`, `docs/archive/`.
4. Per mode, finalizes and regenerates `ISSUES.md`/`BACKLOG.md` via `scripts/gen-mirrors.sh .`:
   - **github**: fail-fast unless `gh` is authenticated (`gh auth status`); offer `gh repo create --private` when no remote exists; ensure the `idea` label (`gh label create idea`, skipped if present).
   - **gitlab**: fail-fast unless `glab` is authenticated to the remote's host (`glab auth status --hostname <host>`); ensure the `idea` label (`glab label create --name idea`, skipped if present).
   - **local**: create `docs/issues/` (one file per issue, zero gh); mirrors generate from those local files.

The remote is advisory only; it never picks the mode.
Setup prints exactly one of:
- `GitHub remote found: <url> - suggesting tracker: github`
- `GitLab remote found: <url> - suggesting tracker: gitlab`
- `Remote found: <url> - no backend inferred; choose a tracker mode (no default)`
- `No remote found - choose a tracker mode (no default)`
It never assumes local.

## The import sweep

The sweep runs in all three modes; its recommended default is the triage workflow in `references/import-triage.md`.
After the mechanical config and mirror steps, the agent scans (`setup.sh --list-candidates`), classifies each item as an issue (no label) or backlog (`idea`), verifies outstanding-vs-already-built with disclosed evidence for every drop, presents one batch disclosure table (then a per-candidate walkthrough for items the user picks), and on approval files each outstanding item, archives each source doc, writes the record doc, and regenerates the mirrors.
The scan covers the repo root (depth 1) and the standard roots (`docs/`, `.planning/`, `.ralph/`, `.scratch/*/issues`, plus any `--scan` roots), skipping governed lanes and root project files.
loop-setup is attended-only and ignores the `loop-auto` autonomy knob; there is no unattended triage mode.
Verbatim one-file-one-issue import and skip remain explicitly offered fallbacks, and the bash per-item prompt is unchanged.
Anything declined and left in place is re-offered on the next run, which is the design surfacing a live loose end, not a bug.

## Migration

When `docs/issues/` holds unmigrated local files and the repo has a github or gitlab remote, suggest `scripts/migrate-tracker.sh --to <target>`.
The agent suggests; the user fires it.
`setup.sh` never runs the migration itself.

## Run it

From inside the target repo:

```bash
/path/to/this/repo/skills/loop-setup/setup.sh
```

Re-running is safe: the mode question is never re-asked, and existing config, label, and docs homes are skipped.
The `ISSUES.md` / `BACKLOG.md` mirrors regenerate on every run via `scripts/gen-mirrors.sh`.

## Non-interactive hooks

```bash
LOOP_TRACKER_ANSWER=github /path/to/setup.sh
LOOP_TRACKER_ANSWER=gitlab /path/to/setup.sh
LOOP_IMPORT_REMOTE=1 LOOP_ASSUME_YES=1 /path/to/setup.sh
MIRRORS_JSON_FILE=./issues.json /path/to/setup.sh --dry-run-remote
/path/to/setup.sh --list-candidates
```

`LOOP_TRACKER_ANSWER=github|gitlab|local` supplies the mode answer without prompting (used in tests and unattended runs).
`LOOP_IMPORT_REMOTE=1` is required alongside `LOOP_ASSUME_YES` before an unattended run creates issues in any mode, local included; without it, candidates are skipped with a note in every mode.
`--dry-run-remote` treats the repo as remote-present, skips the gh/glab auth fail-fast and label create, skips the sweep's remote issue creation, and (with `MIRRORS_JSON_FILE`) generates mirrors from a fixture JSON instead of calling gh or glab.
`--list-candidates` prints the candidate paths, one normalized path per line (honoring `--scan`), exits 0 with no side effects, and serves as the triage scan entry point.
