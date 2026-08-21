# Config v4 target-repo roll - handoff

Template v4 is the two-file config shape: `config/repo-state.md` is the machine surface (line-anchored keys plus the Lanes table) and `config/conventions.md` holds the mode-invariant doctrine, rendered together as one versioned unit by `skills/loop-setup/setup.sh`.
This repo (loop-stack-session) is already at v4; the five target repos below are at v2 or have no config yet, all github mode.
Each repo is an independent, resumable unit: roll them in any order, one at a time, and a repo left pending is simply not yet rolled - this is a staged offer, not part of the stream that shipped v4.

## Targets

| Repo              | Current version | Status  |
| ---               | ---             | ---     |
| vaultwise         | v2              | done    |
| pokemine          | v2              | done    |
| iamawriter        | v2              | done    |
| substack-scraper  | v2              | done    |
| ai-benchmark      | none            | done    |

## Per-repo re-render step

Run, verbatim, from inside the target repo:

```
cd <target-repo> && /path/to/loop-stack/skills/loop-setup/setup.sh
```

Then:

- setup detects the stale `template-version:` and offers a single re-render of `config/repo-state.md` + `config/conventions.md`.
- Accepting preserves `tracker:`, `Remote:`, `backlog-group:`, `autonomy-default:`, and `tracker-remote-ack:`.
- Expect two further offer classes in the same run: vendored-script refreshes (stale `scripts/lifecycle-lint.sh`, `tracker.sh`, etc. - accept these) and import-sweep candidates (triage per candidate; in github mode an accepted offer files a real issue, so never run the roll with `LOOP_ASSUME_YES=1`).
- The import sweep is part of `setup.sh` itself - no separate step; add `--scan <dir>` only if the repo keeps loose planning docs outside the standard roots.
- Verify with `git diff config/` and `bash scripts/lifecycle-lint.sh .` before committing.

Mark the repo's row above done (change `pending`) as each roll lands, so this file is the roll's resume state.
