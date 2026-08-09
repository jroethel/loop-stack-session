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
   When the declared mode disagrees with a github or gitlab remote, setup states the disagreement and offers a declinable switch, silenced by a `tracker-remote-ack:` line in the config.
   Otherwise it reports the remote status, asks the mode once (`github`, `gitlab`, or `local`), and writes the key via `tracker.sh mode set`.
3. Creates the docs homes: root `ROADMAP.md`, `docs/handoffs/`, `docs/reviews/`, `docs/archive/`.
4. With `tracker: github`:
   - Fails fast unless `gh` is authenticated (`gh auth status`; install gh and run `gh auth login`).
   - Offers `gh repo create --private` when no remote exists.
   - Ensures the `idea` label exists (`gh label create idea`, skipped if already present).
   - Generates `ISSUES.md` and `BACKLOG.md` via `scripts/gen-mirrors.sh .`.
5. With `tracker: local`:
   - Creates `docs/issues/` (one file per issue; zero gh).
   - Generates `ISSUES.md` and `BACKLOG.md` via `scripts/gen-mirrors.sh .` from those local files.

The remote is advisory only; it never picks the mode.
Setup prints exactly one of:
- `GitHub remote found: <url> - suggesting tracker: github`
- `GitLab remote found: <url> - suggesting tracker: gitlab`
- `Remote found: <url> - no backend inferred; choose a tracker mode (no default)`
- `No remote found - choose a tracker mode (no default)`
It never assumes local.

## Run it

From inside the target repo:

```bash
/path/to/this/repo/skills/loop-setup/setup.sh
```

Re-running is safe: the mode question is never re-asked, and existing config, label, and docs homes are skipped.
When the declared mode disagrees with a github or gitlab remote, setup states the disagreement and offers a declinable switch, silenced by a `tracker-remote-ack:` line in the config.
The `ISSUES.md` / `BACKLOG.md` mirrors regenerate on every run via `scripts/gen-mirrors.sh`.

## Non-interactive hooks

```bash
LOOP_TRACKER_ANSWER=github /path/to/setup.sh
MIRRORS_JSON_FILE=./issues.json /path/to/setup.sh --dry-run-remote
```

`LOOP_TRACKER_ANSWER=github|local` supplies the mode answer without prompting (used in tests and unattended runs).
`--dry-run-remote` treats the repo as remote-present, skips the gh auth fail-fast and `gh label create`, and (with `MIRRORS_JSON_FILE`) generates mirrors from a fixture JSON instead of calling gh.
