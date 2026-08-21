# Config v4 target-repo roll - handoff (RIT-UADV2223)

Template v4 is the two-file config shape: `config/repo-state.md` is the machine surface (line-anchored keys plus the Lanes table) and `config/conventions.md` holds the mode-invariant doctrine, rendered together as one versioned unit by `skills/loop-setup/setup.sh`.
This host's `~/repos` tree carries zero existing `config/repo-state.md` files - all personal tooling repos there are unconfigured and out of scope for this roll.
The real targets live under the Windows-side project roots: one day-job repo at a pre-`template-version:` config shape (`tracker: local`), four day-job repos at v2/v3 (`tracker: gitlab`), and three no-config repos adopting the convention fresh by explicit choice.
`salesforce-mcp-cli` was considered and excluded from this roll.
Each repo is an independent, resumable unit: roll them in any order, one at a time, and a repo left pending is simply not yet rolled.

## Targets

| Repo                                          | Current version | Status  |
| ---                                           | ---              | ---     |
| /mnt/c/python/projects/ltv-rfm-segments       | pre-key          | pending |
| /mnt/c/python/claude/design-brand-pack        | v2               | pending |
| /mnt/c/python/claude/forge                    | v2               | pending |
| /mnt/c/python/claude/mp4transcript            | v2               | pending |
| /mnt/c/python/claude/sfextract                | v3               | pending |
| /mnt/c/python/claude/dshon                    | none (fresh)     | pending |
| /mnt/c/python/claude/nlm-crm                  | none (fresh)     | pending |
| /mnt/c/python/claude/prospect-news-pipeline   | none (fresh)     | pending |

## Per-repo re-render step

Run, verbatim, from inside the target repo:

```
cd <target-repo> && /path/to/loop-stack/skills/loop-setup/setup.sh
```

Then:

- setup detects the stale `template-version:` (or its absence) and offers a single re-render of `config/repo-state.md` + `config/conventions.md`.
- Accepting preserves `tracker:`, `Remote:`, `backlog-group:`, `autonomy-default:`, and `tracker-remote-ack:`.
- Expect two further offer classes in the same run: vendored-script refreshes (stale `scripts/lifecycle-lint.sh`, `tracker.sh`, etc. - accept these) and import-sweep candidates (triage per candidate; in github mode an accepted offer files a real issue, so never run the roll with `LOOP_ASSUME_YES=1`).
- The import sweep is part of `setup.sh` itself - no separate step; add `--scan <dir>` only if the repo keeps loose planning docs outside the standard roots.
- Verify with `git diff config/` and `bash scripts/lifecycle-lint.sh .` before committing.

Mark the repo's row above done (change `pending`) as each roll lands, so this file is the roll's resume state.
