---
name: loop-setup
description: Initialize a repo's repo-state map (config/repo-state.md), docs homes, the idea label, and issue mirrors. Run once per repo, safe to re-run.
---

# loop-setup

Bootstraps the repo-state convention in the current repo.
The runnable, idempotent core is `setup.sh` next to this file; this skill narrates and invokes it.

## What it does

1. Writes `config/repo-state.md` by rendering `config/repo-state.template.md`.
   The template is the single schema source; never hand-copy a second schema.
2. Branches on whether a GitHub remote is present, detected via `git remote`.
3. Creates the docs homes: `docs/roadmap.md`, `docs/handoffs/`, `docs/reviews/`, `docs/archive/`.
4. With a remote:
   - Ensures the `idea` label exists (`gh label create idea`, skipped if already present).
   - Generates `ISSUES.md` and `BACKLOG.md` via `scripts/gen-mirrors.sh .`.
5. Without a remote:
   - Records the local-markdown fallback tracker at `.scratch/<feature>/issues/` in the rendered config.
   - One file per issue, graduated to GitHub once the repo gains a remote.

## Run it

From inside the target repo:

```bash
/path/to/this/repo/skills/loop-setup/setup.sh
```

Re-running is safe: existing config, label, and docs homes are skipped.
The `ISSUES.md` / `BACKLOG.md` mirrors regenerate on every run via `scripts/gen-mirrors.sh`.

## Dry-run (no live gh)

```bash
MIRRORS_JSON_FILE=./issues.json skills/loop-setup/setup.sh --dry-run-remote
```

Treats the repo as remote-present, skips `gh label create`, and generates mirrors from the fixture JSON.
