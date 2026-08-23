# Repo State Map

This file is the machine surface: the line-anchored keys and the Lanes table that parsers read.
Render it into `config/repo-state.md` by replacing the placeholder below with the repo's remote URL.
The tracker backend (github, gitlab, or local) is declared in the `tracker:` key below; the Local tracker section governs local mode.
Mode-invariant doctrine lives in the sibling `config/conventions.md`.

template-version: 5

Remote: {{REMOTE_OR_FALLBACK}}
backlog-group: {{BACKLOG_GROUP}}

## Lanes

| Lane          | Home                           | How                                            |
| ---           | ---                            | ---                                            |
| Roadmap       | `ROADMAP.md`                   | Living file; edit in place, no mirror.         |
| Issues        | GitHub (open, no `idea`)       | `ISSUES.md` via `scripts/gen-mirrors.sh .`.    |
| Backlog       | GitHub (label `idea`)          | `BACKLOG.md` via `scripts/gen-mirrors.sh .`.   |
| Wayfinder     | GitHub (label `wayfinder:map`) | `WAYFINDER.md` via `scripts/gen-mirrors.sh .`. |
| Handoffs      | `docs/handoffs/`               | Per session; git fallback in conventions.md.   |
| Chain state   | `docs/chain-state.md`          | Runtime, gitignored.                           |
| Batch reviews | `docs/reviews/`                | Per review run.                                |
| Archive       | `docs/archive/`                | Moved work lands here.                         |

Backlog cross-repo view: `gh search issues --owner jroethel --label idea --state open`.
Per-repo fallback when private-repo search is unavailable: `gh issue list --label idea --state open`.
Backlog cross-repo view, gitlab: `glab issue list --group {{BACKLOG_GROUP}} --label idea`.
Per-repo fallback, gitlab: `glab issue list --label idea`.

GitHub is the single source of truth.
Mirrors are read-only snapshots whose headers disclose staleness.
They regenerate at handoff time or on demand - no hooks, no daemons.

## Local tracker

When `tracker: local`, the Issues and Backlog lanes live in `docs/issues/`, one file per issue.
These files are durable and committed - not scratch, not disposable.
Each file is named `NNN-<title-slug>.md` (NNN zero-padded, numbers never reused) with line-anchored frontmatter keys `number:`, `title:`, `labels:` (comma-separated), `state:` (open|closed), and `updated:`.
Closed issues keep their files with `state: closed` - archive, never delete.
`scripts/tracker.sh` reads and writes these files; `scripts/gen-mirrors.sh .` renders ISSUES.md/BACKLOG.md from them.
Issues are updated by editing `docs/issues/NNN-<slug>.md` directly; the safe-to-edit frontmatter keys are `title:`, `labels:` (comma-separated), and `state:` (open|closed) - keep each on its own single line, and do not renumber.
Progress notes are appended to the body.
Local-mode limitations, disclosed:
- A local repo is invisible to cross-repo idea search - `gh search issues` needs a remote.
- wayfinder requires a remote tracker (`github` or `gitlab`); its map is issue-shaped end to end, with no local-tracker variant.
- Numbering is safe only for a single linear writer: two branches or contributors can both mint the same number in differently-slugged files that git merges cleanly; shared or branched work should use a remote tracker (`github` or `gitlab`).
Migration to GitHub - distinct from graduation - recreates every local issue as a GitHub issue via `scripts/migrate-tracker.sh`.
Migration targets either remote backend; `scripts/migrate-tracker.sh --to gitlab` recreates every local issue as a GitLab issue.
Migration renumbers issues (GitHub assigns its own numbers); any existing `#N` reference in commits, other issues, or ROADMAP must be updated afterward - the migration prints the old->new mapping.
