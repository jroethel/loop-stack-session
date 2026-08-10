---
name: loop-setup
description: Declare a repo's tracker mode, write its repo-state map (config/repo-state.md), and run the mode-appropriate finalize. Run once per repo, safe to re-run.
---

# loop-setup

Bootstraps the repo-state convention in the current repo.
The runnable, idempotent core is `setup.sh` next to this file; this skill narrates and invokes it.

## What it does

1. Writes `config/repo-state.md` by rendering `config/repo-state.template.md`.
   The template is the single schema source; never hand-copy a second schema.
2. Declares the tracker mode - it does NOT infer it from `git remote`.
   If `config/repo-state.md` already carries a `tracker:` key, setup skips the question entirely (idempotent, never re-asks the mode).
   When the declared mode disagrees with a github or gitlab remote, setup prints "declared tracker: X, but the remote is Y" and offers a declinable switch to the remote's backend.
   The offer is silenced by a `tracker-remote-ack:` line in the config - a hand-written acknowledgment of a deliberate mode-versus-remote disagreement that `setup.sh` never writes itself.
   Otherwise it reports the remote status, asks the mode once (`github`, `gitlab`, or `local`), and writes the key via `tracker.sh mode set`.
3. Creates the docs homes: root `ROADMAP.md`, `docs/handoffs/`, `docs/reviews/`, `docs/archive/`.
4. With `tracker: github`:
   - Fails fast unless `gh` is authenticated (`gh auth status`; install gh and run `gh auth login`).
   - Offers `gh repo create --private` when no remote exists.
   - Ensures the `idea` label exists (`gh label create idea`, skipped if already present).
   - Generates `ISSUES.md` and `BACKLOG.md` via `scripts/gen-mirrors.sh .`.
5. With `tracker: gitlab`:
   - Fails fast unless `glab` is authenticated to the remote's host (`glab auth status --hostname <host>`; install glab and run `glab auth login --hostname <host>`).
   - Ensures the `idea` label exists (`glab label create --name idea`, skipped if already present).
   - Generates `ISSUES.md` and `BACKLOG.md` via `scripts/gen-mirrors.sh .`.
6. With `tracker: local`:
   - Creates `docs/issues/` (one file per issue; zero gh).
   - Generates `ISSUES.md` and `BACKLOG.md` via `scripts/gen-mirrors.sh .` from those local files.

The remote is advisory only; it never picks the mode.
Setup prints exactly one of:
- `GitHub remote found: <url> - suggesting tracker: github`
- `GitLab remote found: <url> - suggesting tracker: gitlab`
- `Remote found: <url> - no backend inferred; choose a tracker mode (no default)`
- `No remote found - choose a tracker mode (no default)`
It never assumes local.

## The import sweep

The sweep runs in all three modes, and its recommended default is the triage workflow documented in `references/import-triage.md`.
After the mechanical config and mirror steps, the agent works the candidates as follows:
1. Scan via `setup.sh --list-candidates`.
2. Classify each discrete item as an issue (no label) or a backlog item (`idea`).
3. Verify each item as outstanding vs already-built, with disclosed evidence for every drop.
4. Present one batch disclosure table, then offer a per-candidate walkthrough for any items the user picks.
5. On approval, file each outstanding item, archive each source doc, write the record doc, and regenerate the mirrors.
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
