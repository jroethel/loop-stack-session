# GitLab (glab) Backend Support Implementation Plan

> For executors: tasks use checkbox syntax; execute in dependency order; a task is done when its
> acceptance check passes. No specific tooling, harness, or skills are assumed.

**Goal:** Make `gitlab` a first-class third tracker backend alongside `github` and `local`, and make `loop-setup` a universal, re-run-idempotent normalizer in all three modes.

**Approach:** `gitlab` becomes a peer value everywhere the `tracker:` key is consulted, transported by the `glab` CLI, with the GitLab host resolved from the repo's own `origin` remote so a self-hosted instance works.
`setup.sh` sniffs the remote only to *suggest* a mode, never to pick one, and gains a repo-level version plus a decision ledger so a settled repo offers nothing on re-run.
The import sweep is ungated from local mode and becomes backend-independent.

**Tech stack:** Bash (POSIX-leaning, `set -uo pipefail`), `awk`/`sed`/`grep`, the `glab` CLI (>= 1.112.0) with its embedded `--jq`, the `gh` CLI for the existing github path.
No `jq` dependency is introduced; the repo stays deliberately jq-free.

**Source brief:** `docs/briefs/2026-08-09-gitlab-glab-support-brief.md`

## Global constraints

- No `jq` on PATH is ever required; glab's built-in `--jq` flag is the only JSON filter used.
- No script infers the backend from `git remote` at runtime; the `tracker:` key is declared and obeyed.
  `setup.sh` reads the remote solely to phrase a suggestion.
- The `glab` auth guard is always host-scoped: `glab auth status --hostname <host>`, never bare `glab auth status`.
- Every user-facing markdown file follows the house style in `~/.claude/CLAUDE.md`: plain `-` never the em dash character, one full sentence per line in long prose.
- `tracker.sh list` emits gh-shaped JSON in every mode: a JSON array of objects with keys `number` (integer), `title` (string), `labels` (array of `{"name": string}`), `updatedAt` (string).
- Nothing is created, imported, archived, or migrated without an explicit per-item confirmation.
- Existing github-mode and local-mode behavior is preserved byte-for-byte unless a task names the change.
- Bash 3.2 compatible: no associative arrays, no `${var,,}`, guard iteration over possibly-empty arrays.

## Verified facts this plan is built on

These were executed against a live `gitlab.code.rit.edu` during planning.
An executor does not need to re-derive them, but every one is re-checked by a task's acceptance check.

- `glab issue list -O json` emits the raw GitLab REST issue object: `iid` is the per-project issue number, `id` is the global instance id, `labels` is an array of plain strings, `state` is `"opened"`, the timestamp key is `updated_at`.
- `glab issue list -O json --jq '.[] | {number:.iid, title:.title, labels:[.labels[]|{name:.}], updatedAt:.updated_at}'` emits exactly one compact JSON object per line, and emits nothing at all for an empty page.
- `glab` resolves its target host from the *current directory's* git remote.
  Run from a GitHub repo it falls back to `gitlab.com` and fails.
- Bare `glab auth status` exits 1 on a host with any dead token; `glab auth status --hostname gitlab.code.rit.edu` exits 0.
- `glab issue list` accepts `-P/--per-page` and `-p/--page`; GitLab's REST API caps `per_page` at 100.
- `glab issue create` uses `-t/--title`, `-d/--description`, `-l/--label`, and needs `--yes --no-editor` to run unattended.
  It does *not* accept `--body`.
- `glab label create` requires `--name`; `glab label list` uses `-F json` (not `-O json`) and supports `--jq`.
- `glab issue close <iid>` and `glab issue reopen <iid>` take the iid positionally.
- Label names containing a single colon are ordinary GitLab labels; only the `::` double colon marks a scoped label.
  A live label named `In: Container App` was observed, so `wayfinder:map` needs no renaming.
- `config/repo-state.md` in this repo carries no `template-version` line; `/home/jjrdar/claude/forge` carries `template-version: 1`, `tracker: local`, and the false line `Remote: none (local tracker; see the Local tracker section)`.
- `forge`'s `whats_next.md` sits at the repo root, which the current `reconcile_import` scan roots (`docs`, `.planning`, `.ralph`, `.scratch/*/issues`) do not cover.
- Ungating the sweep in this repo **without new exclusions** would surface 9 candidates: 7 under `docs/plans/` (including this plan file) from the existing roots, plus `PLAN.md` by filename keyword and `fixing-agent-errors.md` by content shape from the repo-root scan Task 4 adds.
  An earlier count of 6 was measured before the root scan existed; the re-derived pre-root-scan figure is 7, and both are superseded.
  With Task 4's exclusions (`docs/plans/*` and the depth-1 root project names), the steady-state count in this repo is exactly 1: `fixing-agent-errors.md`, offered by content shape, deliberately - it is a repo-specific document, not a conventional project file.
- `ISSUES.md` and `BACKLOG.md` are gitignored in this repo, but `is_excluded` already drops them by basename, so gitignore-awareness is not load-bearing for them.
- Both `glab issue list --group university-advancement --label idea` and the subgroup form `--group university-advancement/crm --label idea` exit 0 against the live instance.
  The top-level group form that gets rendered into the config is usable, not merely plausible.
- `glab issue list` has **no** `--state` flag.
  It exposes only `-A/--all` and `-c/--closed`, and its documented default is open items only.
  The open-only guarantee is therefore an absence of flags, not a flag.
- Two cleanup commands in Task 7 are **named risks, not verified facts**: `glab api --method DELETE "projects/:id/issues/<iid>"` (including whether the `:id` placeholder substitutes) and `glab issue update <iid> --title` were never exercised during planning.
  Task 7 Step 2b proves both on one throwaway issue before any smoke issue exists, so a wrong guess strands nothing colleague-visible.

## Resolved planning decisions

The brief's open questions, each answered here so no task carries a placeholder.

| Question | Resolution |
| --- | --- |
| Where does the JSON translation live | glab's built-in `--jq`, one expression, no bash JSON assembly and no new dependency |
| `iid` or `id` for the issue number | `iid`; `id` is the instance-global id and is never used |
| Pagination past 100 | Page loop at `--per-page 100`, stopping when a page returns fewer than 100 rows, with a 50-page ceiling |
| Backlog group: key or derived | Derived from the remote at render time, written as a line-anchored `backlog-group:` key so it is overridable, and preserved across re-renders |
| Split/merge guidance home | A new reference file, `skills/loop-setup/references/import-triage.md`, keeping SKILL.md short |
| Standalone migration re-run | `scripts/migrate-tracker.sh --to <target>` is the operation; `SKILL.md` tells the agent when to suggest it, and `setup.sh` never runs it. A setup-side offer was planned and cut at the bloat review - it added an `env -u` dance, a `DRY_REMOTE` interaction, and ledger records for a command one prose line can name |
| forge's false `Remote: none` line | Needs its own correction, not the re-render alone. `setup.sh:203-206` short-circuits whenever a `tracker:` key already exists, so in forge (`tracker: local`) `report_remote` never runs, `MODE` stays `local`, and `render_local` writes `Remote: none` straight back. Task 3 adds a remote-versus-declared-mode disagreement check that runs even on the short-circuit path |
| Does "leave in place" need a marker | No. Imported files are archived (the user's chosen flow), and `docs/archive/*` is already excluded from the scan, so the settled path is quiet with zero state. A declined-and-left file re-offers next run behind the gate question - one keystroke. The committed ledger, fingerprints, and version stamps that made declines durable were cut at the bloat review; a 10-line skip file (`path|cksum`) is the named upgrade if the re-offer ever proves annoying in practice |
| Setup-logic stamp shape | None. The only version key is the already-shipped `template-version` in the config render. The sweep needs no stamp because it keeps no state to go stale |
| This repo's missing `template-version` | Backfilled in Task 6 as part of bringing `config/repo-state.md` to template-version 2 |

### The idempotence model

State of the world, not a state file.

- An **imported** candidate is offered a move to `docs/archive/`, which `is_excluded` already skips; once archived it is invisible to every future sweep with zero bookkeeping.
- A **declined-and-left** candidate re-offers on the next run, behind the single gate question, so the cost of durability-by-nagging is one `n` per run - and per the user's direction, a file someone chose to leave in place is exactly the thing worth speaking up about again.
- The **config** re-render offers while `config/repo-state.md`'s `template-version` differs from the template's, exactly as the shipped `reconcile_config` already behaves; a declined re-render re-offers because the config genuinely is stale.
- Every run ends with a summary line, so "nothing to do" is a statement, not an absence.

This replaces an earlier design (committed decision ledger, `cksum` fingerprints, three version constants) that was cut at the bloat review against Matt Pocock's setup skill: it existed to make declines durable, and declines are the rare case once accepts self-archive.
Criterion 8 is read in the scope its parent sentence gives it (brief lines 39-41, "nothing else changed"): a settled repo offers nothing for content already imported and archived, and says so.

## Review record

This plan was revised three times.

**First, a two-lens fresh-context (Rubix) review.**
Twenty-one findings were applied in full; three were applied only in part, and the reason each was narrowed is recorded in the table below.

**Second, a baseline review against Matt Pocock's setup skill** (`~/repos/mattpocock/skills/skills/engineering/setup-matt-pocock-skills/`), requested by the user in the spirit of avoiding bloat.
Its verdict: the script seam (`tracker.sh`, mirrors, rendered config) is justified divergence because loop-stack has deterministic consumers Matt's prose-only design does not, but the decision ledger, `cksum` fingerprints, version constants (`SETUP_VERSION`, `SWEEP_CHANGED_AT`, `loop-setup-version`), `LOOP_SWEEP_ANSWER`, and the setup-side migration offer all served one premise - declines must be durable in a state file - that archive-on-import makes mostly moot.
All of it was cut; several Rubix findings (the ledger-format mismatch, the `env -u` stripping, the `DRY_REMOTE`-versus-offer interaction, the decline-then-accept break in `reconcile.sh`) resolved by deletion, and `tests/loop-setup/reconcile.sh` and `tests/repo-state/config.sh` are back to untouched.
The named upgrade path if decline re-offers prove annoying in practice: a skip file of `path|cksum` lines, roughly ten lines of bash, deliberately not built now.

**Third, a second Rubix review after the bloat cut** (findings recorded in `docs/handoffs/2026-08-09-gitlab-plan-rubix-findings.md`).
Two fresh-context lenses re-reviewed the post-cut text and produced 23 deduplicated findings; all 23 were applied, two narrowed per the table below.
The blocking one: the ungated sweep would have offered and archived every `docs/plans/*` file in this repo - a blast radius the prior handoff had measured and blessed as "expected" without ever classifying it.
Findings 1 through 5 together changed Task 4's sweep design rather than its wording: `docs/plans/*` joined the exclusions (plan and brief archival stays owned by the Archive-and-graduation rules), the archive move gained collision and repo-boundary guards, the root scan no longer rides the empty-roots early return, the unattended remote gate is stated as a literal condition, and `--dry-run-remote` now also gates the sweep's remote creation.
Because those five were a design change, the revised Task 4 then got its own fresh-context cold read (same blind method, scoped to the revision), which produced ten repairs, all applied in place: `tests/loop-setup/import.sh`'s `MARKER_PLAN` fixture retargeted from imported to excluded (the revision would have failed its own gate on that suite), an observable capture-and-re-emit mechanism for the `$TIDY` offer counter, the empty-array expansion idiom struck as a false substitute for the roots guard, sweep-specific skip strings with their output stream pinned to stdout, a create-failure scenario, a false-direction assertion on the summary line, announce-on-success for the archive move, a corrected `tidy.sh` line cite, and the remote report suppressed on settled no-remote repos.

| Reviewer proposal | Verdict | Reason |
| --- | --- | --- |
| Add `--state opened` to the `glab issue list` call | Declined as written, intent adopted | The flag does not exist: `glab issue list` exposes only `-A/--all` and `-c/--closed`, and defaults to open. Task 1 instead asserts the call passes **neither** flag, which is the checkable form of the same guarantee |
| Pass `-R/--repo` on every `glab issue` call so the guard's host cannot diverge from glab's target | Declined | glab already resolves host and project from the same repo remote, so the two cannot diverge today. Adding `-R` introduces a second, independently-derivable target and a new way for them to disagree. The underlying fork-layout concern is addressed instead by fixing remote classification (Task 3) |
| Add a `setup.sh --reopen <path>` subcommand to clear one ledger line | Declined, then mooted | Declined at triage as an unearned CLI surface; the bloat review then removed the ledger it would have operated on. Reopening a decision is now `git mv docs/archive/<file> .` - moving the file back is the whole mechanism |
| Top-level `backlog-group` may be unusable on a university-wide instance | Premise declined, check adopted | `glab issue list --group university-advancement --label idea` exits 0 against the live instance, so the rendered command works. Task 7 still fires the rendered command, because a verified command beats a plausible one. The second round added a classification to that check: exit 0 alone cannot distinguish a correctly scoped group from a university-wide one, so Task 7 Step 4 also inspects the returned projects and names the by-hand `backlog-group:` override as the action on any foreign row |
| Swap the mode-switch trigger to "the `Remote:` line is absent or starts with `none`" (round-2 finding 8) | Declined as written, defect adopted | The mode-versus-remote disagreement is what produces criterion 5's observable in forge, and Task 7 Step 2 stops the run if the offer never appears - replacing the trigger would remove the plan's own tripwire. The real defect was the missing acknowledgment path: a declined switch now names a line-anchored `tracker-remote-ack:` key as the recorded off switch, and SKILL.md's absolute "never re-asks" claims are corrected in Task 3 |
| Trim the new root-exclusion names to the three that exist in this repo (round-2 finding 17) | Declined as written, depth fix adopted | `setup.sh` is vendored into repos where `AGENTS.md`, `CHANGELOG.md`, `LICENSE.md`, and `CONTRIBUTING.md` do exist, so the defensive names stay. What was wrong was the scope: the names now match depth-1 normalized paths only, not basenames at any depth, and the exclusion set is declared in the template where a user can find it |

## Dependency graph

```
Wave 1 (parallel):  Task 1 (tracker.sh)      Task 2 (gen-mirrors.sh)
                          |________________________|
                          |
Wave 2:             Task 3 (setup.sh: gitlab mode)
                          |
Wave 3:             Task 4 (setup.sh: universal sweep)
                          |
Wave 4:             Task 5 (migrate-tracker.sh: gitlab target + vendoring)
                          |
Wave 5:             Task 6 (docs and skill sweep)
                          |
Wave 6:             Task 7 (live forge smoke - HUMAN CHECKPOINT)
```

Tasks 1 and 2 touch disjoint files and have no path between them, so they are parallel-eligible.
Task 3 consumes both: Task 1's subcommands, and Task 2's `GitLab issues` disclosure string, which the gitlab finalize greps for in the target repo's vendored `gen-mirrors.sh`.
Tasks 3, 4, and 5 all modify `skills/loop-setup/setup.sh` and are therefore strictly sequential; that is a deliberate serialization, not a missing edge.

## Human checkpoints

1. **Before Task 7, and throughout it.**
   Task 7 writes to a live shared GitLab instance (`gitlab.code.rit.edu`, group `university-advancement`).
   Every issue-creating and issue-closing command in Task 7 is staged for the user to fire; an executor never runs them unattended.

2. **Criterion 13 of the brief (`[judgment]`).**
   "The sweep's proposed split of `whats_next.md` yields issues that each name one actionable item, with no proposal spanning two unrelated items."
   This is judged by a human reading the proposed titles in Task 7, not by any command.
   If a proposal spans two unrelated items, the split is redone before any issue is created.

3. **Any candidate file the sweep offers to archive in a repo other than a scratch sandbox.**
   The archive move is per-file and declinable; an executor never accepts on the user's behalf.

## Brief coverage

Every success criterion in the source brief, mapped to where it is checked.
No criterion is unmapped, and the only `[judgment]` criterion lands on a human checkpoint rather than on a task.

| # | Criterion (abbreviated) | Where it is checked |
| --- | --- | --- |
| 1 | `mode set gitlab` / `mode get`; setup accepts a third answer | Task 1 test (mode block), Task 3 test (scenarios A and D) |
| 2 | `list` exits 0 with gh-shaped JSON translated from glab | Task 1 test (list block) |
| 3 | Live round trip in forge: create, list, mirror, close | Task 7 Step 4, user-fired |
| 4 | Dead `gitlab.com` token; `list` still exits 0, no bare `glab auth status` | Task 1 test (guard block), Task 7 Step 5 live |
| 5 | `setup.sh` in forge reports a GitLab remote and suggests gitlab | Task 3 test **scenario E**, which reproduces forge's exact shape (declared `tracker: local` plus a GitLab remote); scenario A covers the fresh-repo path; Task 7 Step 2 live |
| 6 | The `ssh://...:2222/...` URL yields backlog group `university-advancement` | Task 1 test (`check_url`), Task 3 test (scenario A) |
| 7 | The sweep runs in all three modes, per-item confirmation | Task 4 test (local, github, and gitlab scenarios) |
| 8 | *(revised at the bloat review, per the user's direction)* A re-run offers nothing for content already imported and archived, and says so; declined-and-left content may re-offer | Task 4 test (re-run block), Task 7 Step 6 live |
| 9 | *(revised)* The shipped `template-version` mechanism re-offers the config render when the template moves; the setup-logic stamp was cut with the ledger | Covered by the existing `tests/loop-setup/reconcile.sh`, which this plan no longer touches |
| 10 | *(revised)* Migration is documented and suggested during setup; the standalone script is the operation and re-runs safely | Task 5 test (re-run no-op block), Task 6 test (SKILL.md assertion), Task 7 Step 6 live |
| 11 | wayfinder works in a gitlab repo; SKILL.md drops the github-only claim | Task 6 test (docs half), Task 7 Step 7 live (label half) |
| 12 | Offline fixture tests cover gitlab mode; `tests/run.sh` passes | Task 7 Step 1, the plan's gate |
| 13 | `[judgment]` One actionable item per proposed issue | **Human checkpoint 2**, exercised in Task 7 Step 3 |

## How to run

All commands run from the repo root, `/home/jjrdar/repos/loop-stack-session`.

```bash
# full suite (the plan's top-level gate)
bash tests/run.sh

# a single suite
bash tests/repo-state/tracker-gitlab.sh

# lint a script for syntax before running it
bash -n scripts/tracker.sh
```

`tests/run.sh` discovers every `tests/*/*.sh`, skips `build-fixtures.sh`, and skips `live.sh` when `gh auth status` fails.
New suites are picked up automatically by living in a `tests/<group>/<name>.sh` path.
No suite added by this plan may require network access or an authenticated CLI; all of them stub `glab` and `gh` on `PATH`.

---

### Task 1: `tracker.sh` gitlab backend

Depends on: none

**Files (exclusive ownership):**

- Modify: `scripts/tracker.sh`
- Test: `tests/repo-state/tracker-gitlab.sh` (create)

**Interfaces:**

Consumes: nothing from other tasks.

Produces, for Tasks 2 through 7:

- `scripts/tracker.sh mode set gitlab` writes `tracker: gitlab` and echoes `gitlab`.
- `scripts/tracker.sh mode get` prints `gitlab` for such a repo.
- `scripts/tracker.sh list` in gitlab mode prints a single-line JSON array of `{"number":<int>,"title":<string>,"labels":[{"name":<string>}],"updatedAt":<string>}` objects, or `[]` when there are none.
- `scripts/tracker.sh create --label L --title T --body B` in gitlab mode prints the new issue's bare iid on stdout.
- `scripts/tracker.sh close <iid>` and `scripts/tracker.sh reopen <iid>` operate on gitlab.
- Two shell functions, used by Task 3 through a `source`-free copy of the same `sed` expressions (Task 3 re-implements them in `setup.sh`; they are documented here so the two agree):
  - `gitlab_host` prints the host of `origin`, handling `ssh://git@HOST:PORT/path`, `git@HOST:path`, and `https://HOST/path`.
  - `gitlab_group` prints the first path segment after the host, for the same three URL forms.

**Acceptance check:** `bash tests/repo-state/tracker-gitlab.sh` exits 0 `[executed-check]`

- [ ] **Step 1: Write the failing test.**
      Create `tests/repo-state/tracker-gitlab.sh` with exactly this content:

```bash
#!/usr/bin/env bash
# tracker.sh gitlab backend: mode accepts gitlab, the auth guard is host-scoped, list translates
# glab JSON to the gh shape across pages, create returns the iid, close/reopen dispatch to glab.
# A stub glab on PATH records every invocation, so "never bare glab auth status" is provable.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
T="$REPO/scripts/tracker.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$T" ] || fail "scripts/tracker.sh missing or not executable"

BIN="$(mktemp -d)"; SB="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB"' EXIT
LOG="$BIN/glab.calls"
GHLOG="$BIN/gh.calls"

# gh stub: records any call. gitlab mode must never touch gh; the github-mode block near the
# end of this file uses it to prove the empty-label fix applies to both remote backends.
cat > "$BIN/gh" <<'STUB'
#!/usr/bin/env bash
echo "GH CALLED: $*" >> "$GH_LOG"
[ "$1" = auth ] && exit 0
if [ "$1" = issue ] && [ "$2" = create ]; then
  echo "https://github.com/acme/x/issues/77"; exit 0
fi
exit 0
STUB
chmod +x "$BIN/gh"
export GH_LOG="$GHLOG"

# The --jq expression the implementation MUST pass. The stub only translates when it sees this
# string verbatim; any drift makes the stub emit RAW GitLab JSON instead, and every assertion
# below fails. Without this, a stub that pre-translates would pass no matter what filter the
# implementation used, and the brief's highest-risk claim would be untested.
EXPECTED_JQ='.[] | {number:.iid, title:.title, labels:[.labels[]|{name:.}], updatedAt:.updated_at}'

# glab stub. Records every invocation. Mimics the real CLI's contract:
#   auth status              -> exit 1 unless --hostname is supplied (the dead-token regression)
#   auth status --hostname H -> exit 0 for gitlab.example.com
#   issue list               -> RAW GitLab REST rows, translated only if --jq matches EXPECTED_JQ
#   issue create             -> a URL line whose last path segment is the new iid
#   issue close|reopen       -> exit 0
# Stub modes, set by the caller:
#   GLAB_PAGES=1   -> page 1 returns 100 rows, page 2 returns 3, page 3+ returns nothing
#   GLAB_FAIL=1    -> issue list exits 1 (to prove a hard failure is not swallowed into [])
# Quoted heredoc: nothing expands at write time, so no escaping. The stub reads its config
# from the environment at run time instead.
cat > "$BIN/glab" <<'STUB'
#!/usr/bin/env bash
echo "GLAB CALLED: $*" >> "$GLAB_LOG"
if [ "$1" = auth ] && [ "$2" = status ]; then
  for a in "$@"; do [ "$a" = --hostname ] && exit 0; done
  exit 1
fi
if [ "$1" = issue ] && [ "$2" = list ]; then
  [ "${GLAB_FAIL:-0}" = 1 ] && { echo "ERROR 500" >&2; exit 1; }
  page=1; jqexpr=""; prev=""
  for a in "$@"; do
    case "$prev" in -p|--page) page="$a" ;; --jq) jqexpr="$a" ;; esac
    prev="$a"
  done
  rows=""
  if [ "${GLAB_PAGES:-0}" = 1 ]; then
    case "$page" in
      1) rows="$(awk 'BEGIN{for(i=1;i<=100;i++) printf "%d\tbulk %d\t\n", i, i}')" ;;
      2) rows="$(awk 'BEGIN{for(i=101;i<=103;i++) printf "%d\ttail %d\t\n", i, i}')" ;;
    esac
  elif [ "$page" = 1 ]; then
    rows="$(printf '7\ta backlog item\tidea\n4\ta plain issue\t\n')"
  fi
  [ -n "$rows" ] || exit 0
  # Emit RAW GitLab REST shape, and translate ONLY on an exact --jq match. Any drift in the
  # implementation's filter leaves the raw shape, which every assertion below rejects.
  if [ "$jqexpr" = "$EXPECTED_JQ_ENV" ]; then
    printf '%s\n' "$rows" | awk -F'\t' '{
      lbl = ($3 == "") ? "" : "{\"name\":\"" $3 "\"}"
      printf "{\"number\":%s,\"title\":\"%s\",\"labels\":[%s],\"updatedAt\":\"2026-08-01T00:00:00Z\"}\n", $1, $2, lbl
    }'
  else
    printf '%s\n' "$rows" | awk -F'\t' '{
      lbl = ($3 == "") ? "" : "\"" $3 "\""
      printf "{\"id\":%d,\"iid\":%s,\"state\":\"opened\",\"title\":\"%s\",\"labels\":[%s],\"updated_at\":\"2026-08-01T00:00:00Z\"}\n", 9000+$1, $1, $2, lbl
    }'
  fi
  exit 0
fi
if [ "$1" = issue ] && [ "$2" = create ]; then
  echo "https://gitlab.example.com/grp/sub/repo/-/issues/42"
  exit 0
fi
if [ "$1" = issue ] && { [ "$2" = close ] || [ "$2" = reopen ]; }; then exit 0; fi
exit 0
STUB
chmod +x "$BIN/glab"
export PATH="$BIN:$PATH"
export GLAB_LOG="$LOG"
export EXPECTED_JQ_ENV="$EXPECTED_JQ"

cd "$SB" && git init -q && mkdir -p config
git remote add origin 'ssh://git@gitlab.example.com:2222/grp/sub/repo.git'

# --- mode: gitlab is a peer third value ---
[ "$("$T" mode set gitlab)" = "gitlab" ] || fail "mode set gitlab did not echo gitlab"
[ "$("$T" mode get)" = "gitlab" ]        || fail "mode get did not read back gitlab"
[ "$(grep -c '^tracker:' config/repo-state.md)" -eq 1 ] || fail "mode set duplicated the tracker: line"
"$T" mode set banana >/dev/null 2>&1 && fail "mode set accepted an unknown backend"

# --- list: gh-shaped translation, paginated, valid single-line array ---
out="$("$T" list)" || fail "list exited non-zero in gitlab mode"
[ "${out#\[}" != "$out" ] || fail "list output does not start with ["
[ "${out%\]}" != "$out" ] || fail "list output does not end with ]"
[ "$(printf '%s\n' "$out" | grep -c .)" -eq 1 ] || fail "list emitted more than one line"
printf '%s' "$out" | grep -q '"number":7'  || fail "list lost issue 7"
printf '%s' "$out" | grep -q '"number":4'  || fail "list lost issue 4"
printf '%s' "$out" | grep -q '"name":"idea"' || fail "list lost the idea label"
printf '%s' "$out" | grep -q '},{'         || fail "list did not comma-join the two rows"
printf '%s' "$out" | grep -q ',,'          && fail "list emitted an empty element"

# --- the RAW GitLab shape must never reach a consumer ---
# The stub only translates on an exact --jq match; these three assertions are what makes the
# translation expression itself the thing under test rather than the stub's generosity.
printf '%s' "$out" | grep -q '"iid"'        && fail "raw glab shape leaked through: --jq did not translate"
printf '%s' "$out" | grep -q '"updated_at"' && fail "raw updated_at leaked through instead of updatedAt"
printf '%s' "$out" | grep -q '"state"'      && fail "raw state field leaked into the gh-shaped output"
grep -qF -- "--jq $EXPECTED_JQ" "$LOG" \
  || fail "list did not pass the expected --jq translation expression verbatim"

# --- open-only is an ABSENCE of flags: glab issue list has no --state, and defaults to open ---
grep -qE -- '--all|(^| )-A( |$)'    "$LOG" && fail "list passed --all, which would include closed issues"
grep -qE -- '--closed|(^| )-c( |$)' "$LOG" && fail "list passed --closed"

# --- the auth guard is host-scoped and resolves the host from the remote ---
grep -q 'GLAB CALLED: auth status --hostname gitlab.example.com' "$LOG" \
  || fail "guard did not run a --hostname-scoped auth status"
grep -E 'GLAB CALLED: auth status$' "$LOG" \
  && fail "guard ran a BARE glab auth status (regression: a dead token on another host fails it)"

# --- list asked for 100 per page and started at page 1 ---
grep -q -- '--per-page 100' "$LOG" || fail "list did not request 100 items per page"
grep -q -- '--page 1'       "$LOG" || fail "list did not request page 1"

# --- pagination actually crosses a page boundary (100 on page 1, 3 on page 2, then stop) ---
: > "$LOG"
out="$(GLAB_PAGES=1 "$T" list)" || fail "paginated list exited non-zero"
[ "$(printf '%s' "$out" | grep -o '"number":' | wc -l)" -eq 103 ] \
  || fail "paginated list returned $(printf '%s' "$out" | grep -o '"number":' | wc -l) rows, expected 103"
printf '%s' "$out" | grep -q ',,' && fail "page join produced an empty element"
printf '%s' "$out" | grep -q '"number":100,' || fail "last row of page 1 was lost at the join"
printf '%s' "$out" | grep -q '"number":101,' || fail "first row of page 2 was lost at the join"
[ "$(printf '%s\n' "$out" | grep -c .)" -eq 1 ] || fail "paginated list emitted more than one line"
grep -q -- '--page 2' "$LOG" || fail "list did not request page 2 after a full page"
grep -q -- '--page 3' "$LOG" && fail "list requested page 3 after a short page (must stop)"

# --- a glab failure is a hard failure, never a silently empty array ---
: > "$LOG"
out="$(GLAB_FAIL=1 "$T" list 2>/dev/null)"; rc=$?
[ "$rc" -ne 0 ] || fail "list exited 0 when glab failed (an empty mirror would render with no error)"
[ "$out" = "[]" ] && fail "list printed [] on a glab failure instead of failing"

# --- create returns the bare iid parsed from the issue URL ---
n="$("$T" create --label idea --title "new thing" --body "some body")" \
  || fail "create exited non-zero in gitlab mode"
[ "$n" = "42" ] || fail "create returned '$n', expected the iid 42"
grep -q -- '--no-editor' "$LOG" || fail "create did not pass --no-editor (would block on an editor)"
grep -q -- '--yes'       "$LOG" || fail "create did not pass --yes (would block on a prompt)"

# --- create with an empty label must not pass a bare -l "" ---
: > "$LOG"
"$T" create --label "" --title "no label" --body b >/dev/null || fail "create failed with an empty label"
grep -qE -- "-l( |$)" "$LOG" && fail "create passed -l with an empty label value"

# --- close and reopen dispatch to glab with the iid ---
"$T" close 42  >/dev/null 2>&1 || fail "close exited non-zero in gitlab mode"
"$T" reopen 42 >/dev/null 2>&1 || fail "reopen exited non-zero in gitlab mode"
grep -q 'GLAB CALLED: issue close 42'  "$LOG" || fail "close did not call glab issue close 42"
grep -q 'GLAB CALLED: issue reopen 42' "$LOG" || fail "reopen did not call glab issue reopen 42"

# --- zero gh in gitlab mode (must be asserted BEFORE the github-mode block below) ---
[ -f "$GHLOG" ] && fail "gitlab mode invoked gh: $(cat "$GHLOG")"

# --- an unknown mode FAILS; it must never fall through to the local backend ---
"$T" mode set gitlab >/dev/null
sed -i.bak 's/^tracker: gitlab$/tracker: bitbucket/' config/repo-state.md
"$T" list   >/dev/null 2>&1 && fail "list silently accepted an unknown tracker mode"
"$T" create --label idea --title x --body y >/dev/null 2>&1 \
  && fail "create silently accepted an unknown tracker mode"
[ -d docs/issues ] && fail "an unknown mode fell through to the LOCAL backend and wrote docs/issues/"
"$T" mode set gitlab >/dev/null

# --- the empty-label fix applies to the github branch too, not just gitlab ---
"$T" mode set github >/dev/null
: > "$GHLOG"
n="$("$T" create --label "" --title "no label on github" --body b)" \
  || fail "github create failed with an empty label"
[ "$n" = "77" ] || fail "github create returned '$n', expected 77"
grep -qE -- '--label( |$)' "$GHLOG" && fail "github create passed --label with an empty value"
"$T" create --label idea --title "labelled" --body b >/dev/null || fail "github create failed with a label"
grep -q -- '--label idea' "$GHLOG" || fail "github create dropped a non-empty label"
"$T" mode set gitlab >/dev/null

# --- host and group derivation across all three remote URL forms ---
check_url() {  # $1 = url, $2 = expected host, $3 = expected group
  git remote set-url origin "$1"
  h="$("$T" host)"  || fail "host failed for $1"
  g="$("$T" group)" || fail "group failed for $1"
  [ "$h" = "$2" ] || fail "host for $1 was '$h', expected '$2'"
  [ "$g" = "$3" ] || fail "group for $1 was '$g', expected '$3'"
}
check_url 'ssh://git@gitlab.code.rit.edu:2222/university-advancement/crm/forge.git' \
          'gitlab.code.rit.edu' 'university-advancement'
check_url 'git@gitlab.example.com:grp/sub/repo.git' 'gitlab.example.com' 'grp'
check_url 'https://gitlab.example.com/grp/sub/repo.git' 'gitlab.example.com' 'grp'

echo "PASS: tracker gitlab backend"
```

- [ ] **Step 2: Run it.**
      `bash tests/repo-state/tracker-gitlab.sh`
      Expect FAIL with `mode set gitlab did not echo gitlab`, because `tracker_mode_set` currently rejects anything but `github` and `local`.

- [ ] **Step 3: Implement against the contract in Interfaces.**
      Edit `scripts/tracker.sh` only.

  a. Update the file's header comment to say the backend dispatches to github (`gh`), gitlab (`glab`), or local (`docs/issues/*.md`).

  b. In `tracker_mode_set`, widen the validation case to `github|gitlab|local` and update the failure message to `"mode set: must be 'github', 'gitlab', or 'local' (got '$m')"`.

  c. Add `gitlab_host` and `gitlab_group`, each reading `git remote get-url origin`.
     Use exactly these `sed` pipelines, which were checked against all three URL forms:
     - host: `sed -E 's#^[a-z+]+://##; s#^[^@]*@##; s#[:/].*$##'`
     - group: `sed -E 's#^[a-z+]+://##; s#^[^@]*@##; s#^[^:/]+##; s#^:[0-9]+/#/#; s#^:##; s#^/##'` then take the text before the first `/` via `${p%%/*}`.
     Both return non-zero and print nothing when `origin` is absent.

  d. Add `glab_guard`, mirroring `gh_guard`'s fail-fast shape:
     - `command -v glab` missing: fail with `"gitlab mode requires the glab CLI, which is not on PATH"`.
     - `gitlab_host` empty: fail with `"gitlab mode requires an origin remote to resolve the GitLab host (found none)"`.
     - `glab auth status --hostname "$host"` non-zero: fail with `"gitlab mode requires glab authenticated to $host (run: glab auth login --hostname $host)"`.
     Never call `glab auth status` without `--hostname`.

  e. Add `gitlab_list`, the page loop, exactly as written here.
     This one is given verbatim rather than as a contract, because two of its details are traps: `local out="$(cmd)" || fail` can never fail (the status returned is `local`'s, not the command's), and a swallowed failure here yields `[]`, which `gen-mirrors.sh` renders as an empty table with exit 0.
     That is the brief's second-ranked blast radius, failing silently rather than loudly.

     ```bash
     # ponytail: 50 pages x 100 = a 5000-open-issue ceiling. GitLab caps per_page at 100, so a
     # page loop is the only correct form; raise the cap or switch to keyset pagination if a repo
     # ever exceeds it. The loop stops on the first short page, so the cap costs nothing normally.
     gitlab_list() {
       local page=1 rows n all=""
       while [ "$page" -le 50 ]; do
         # declare first, assign second: `local rows="$(...)" || fail` would test local's status.
         rows="$(glab issue list --per-page 100 --page "$page" -O json \
           --jq '.[] | {number:.iid, title:.title, labels:[.labels[]|{name:.}], updatedAt:.updated_at}')" \
           || fail "glab issue list failed on page $page"
         [ -n "$rows" ] || break
         all="${all:+$all,}$(printf '%s' "$rows" | paste -sd, -)"
         n="$(printf '%s\n' "$rows" | grep -c .)"
         [ "$n" -lt 100 ] && break
         page=$((page + 1))
       done
       printf '[%s]\n' "$all"
     }
     ```

     Pass no `--all` and no `--closed`: `glab issue list` has no `--state` flag and defaults to open items, so open-only is guaranteed by the absence of those two flags, and Task 1's test asserts that absence.

  f. In the `list`, `create`, and `close|reopen` dispatch blocks, replace the two-branch `if [ "$mode" = github ]` with a **four**-branch case:

     ```bash
     case "$mode" in
       github) ... ;;
       gitlab) ... ;;
       local)  ... ;;
       *)      fail "unknown tracker mode '$mode' in $RS (expected github, gitlab, or local)" ;;
     esac
     ```

     The explicit `local)` plus a failing default is load-bearing, not tidiness.
     Today's `if github ... else <local>` treats every non-github value as local, so a repo whose config already says `tracker: gitlab` but whose vendored `tracker.sh` predates this work files its issues into `docs/issues/` while reporting success.
     A `*)` that falls through to local reproduces exactly that failure for any typo or future backend, and it is silent.

     Preserve the existing github and local bodies verbatim, with one correction to the github `create` body noted in (i) below.
     The gitlab branches:
     - `list`: `glab_guard; gitlab_list`
     - `create`: `glab_guard`, then build an argument array so an empty label passes no `-l` at all:
       ```
       args=(issue create --yes --no-editor -t "$title" -d "$body")
       [ -n "$label" ] && args+=(-l "$label")
       out="$(glab "${args[@]}")" || fail "glab issue create failed"
       iid="$(printf '%s' "$out" | grep -oE '/issues/[0-9]+' | tail -1 | sed 's#.*/##')"
       [ -n "$iid" ] || fail "glab issue create returned no parseable issue URL"
       printf '%s\n' "$iid"
       ```
       Parsing `/issues/<n>` rather than the last path segment of the last line is deliberate: it does not assume the URL is the whole final line of glab's output.
     - `close|reopen`: `glab_guard; glab issue "$sub" "$num"`

  g. Add two new subcommands to the top-level `case "$sub"`, used by the test and by Task 3:
     `host)` prints `gitlab_host` output, `group)` prints `gitlab_group` output.
     Both fail with `"no origin remote"` when `origin` is absent.

  h. Extend `usage()` with the new values and subcommands:
     ```
       mode get                       print the declared tracker mode (github|gitlab|local); exit 3 if the key is absent
       mode set <github|gitlab|local> write the line-anchored tracker: key
       host                           print the GitLab host derived from origin
       group                          print the first path segment of origin (the backlog group)
     ```

  i. Fix the same empty-label defect on the **github** branch, which today unconditionally passes `--label "$label"` at `tracker.sh:161`.
     Task 4 ungates the import sweep into github mode, and the sweep's corpus contains candidates with no `Label:` line, so this stops being latent the moment Task 4 lands.
     Apply the identical argument-array treatment:
     ```bash
     args=(issue create --title "$title" --body "$body")
     [ -n "$label" ] && args+=(--label "$label")
     url="$(gh "${args[@]}")" || fail "gh issue create failed"
     ```
     Fixing it here rather than in Task 4 is deliberate: one guard in the shared dispatch beats a guard in each caller, and both remote backends then behave the same way.

- [ ] **Step 4: Run it.**
      `bash tests/repo-state/tracker-gitlab.sh` - expect PASS.
      Then `bash tests/repo-state/tracker.sh` and `bash tests/repo-state/tracker-limit.sh` - expect PASS, proving the github and local paths are untouched.

- [ ] **Step 5: Commit.**
      ```bash
      git add scripts/tracker.sh tests/repo-state/tracker-gitlab.sh
      git commit -m "tracker: add gitlab backend via glab with host-scoped auth and paginated list"
      ```

---

### Task 2: `gen-mirrors.sh` gitlab source disclosure

Depends on: none

**Files (exclusive ownership):**

- Modify: `scripts/gen-mirrors.sh:84-87`
- Test: `tests/repo-state/mirrors-gitlab.sh` (create)

**Interfaces:**

Consumes: nothing.
It reads `scripts/tracker.sh mode get`, which already returns whatever string the `tracker:` key holds, so this task does not depend on Task 1.

Produces: mirrors whose disclosed header reads `source of truth: GitLab issues` when the mode is `gitlab`.
The existing values `GitHub issues` and `docs/issues/ local tracker` are unchanged.

**Acceptance check:** `bash tests/repo-state/mirrors-gitlab.sh` exits 0 `[executed-check]`

- [ ] **Step 1: Write the failing test.**
      Create `tests/repo-state/mirrors-gitlab.sh` with exactly this content:

```bash
#!/usr/bin/env bash
# gen-mirrors.sh discloses GitLab as the source of truth in gitlab mode, and still renders the
# lane split (idea -> BACKLOG.md, everything else -> ISSUES.md) from gh-shaped JSON.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
GEN="$REPO/scripts/gen-mirrors.sh"
TRK="$REPO/scripts/tracker.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$GEN" ] || fail "scripts/gen-mirrors.sh missing or not executable"

SB="$(mktemp -d)"; trap 'rm -rf "$SB"' EXIT
mkdir -p "$SB/scripts" "$SB/config"
cp "$GEN" "$SB/scripts/gen-mirrors.sh"; chmod +x "$SB/scripts/gen-mirrors.sh"
cp "$TRK" "$SB/scripts/tracker.sh";     chmod +x "$SB/scripts/tracker.sh"
printf 'tracker: gitlab\n' > "$SB/config/repo-state.md"

cat > "$SB/issues.json" <<'EOS'
[{"number":7,"title":"a backlog item","labels":[{"name":"idea"}],"updatedAt":"2026-08-01T00:00:00Z"},
 {"number":4,"title":"a plain issue","labels":[],"updatedAt":"2026-07-01T00:00:00Z"},
 {"number":9,"title":"the map","labels":[{"name":"wayfinder:map"}],"updatedAt":"2026-08-02T00:00:00Z"}]
EOS

( cd "$SB" && MIRRORS_JSON_FILE=./issues.json ./scripts/gen-mirrors.sh . >/dev/null ) \
  || fail "gen-mirrors.sh failed in gitlab mode"

grep -q 'source of truth: GitLab issues' "$SB/ISSUES.md" \
  || fail "ISSUES.md does not disclose GitLab as the source of truth"
grep -q 'source of truth: GitLab issues' "$SB/BACKLOG.md" \
  || fail "BACKLOG.md does not disclose GitLab as the source of truth"
grep -q 'GitHub issues' "$SB/ISSUES.md" && fail "gitlab-mode mirror still claims GitHub"

grep -q '| 4 | a plain issue' "$SB/ISSUES.md"   || fail "unlabelled issue missing from ISSUES.md"
grep -q '| 7 | a backlog item' "$SB/BACKLOG.md" || fail "idea issue missing from BACKLOG.md"
grep -q '| 7 |' "$SB/ISSUES.md"  && fail "idea issue leaked into ISSUES.md"
grep -q '| 9 |' "$SB/ISSUES.md"  && fail "wayfinder issue leaked into ISSUES.md"
grep -q '| 9 |' "$SB/BACKLOG.md" && fail "wayfinder issue leaked into BACKLOG.md"

# github and local disclosures are unchanged
printf 'tracker: github\n' > "$SB/config/repo-state.md"
( cd "$SB" && MIRRORS_JSON_FILE=./issues.json ./scripts/gen-mirrors.sh . >/dev/null ) || fail "github regen failed"
grep -q 'source of truth: GitHub issues' "$SB/ISSUES.md" || fail "github disclosure regressed"
printf 'tracker: local\n' > "$SB/config/repo-state.md"
( cd "$SB" && MIRRORS_JSON_FILE=./issues.json ./scripts/gen-mirrors.sh . >/dev/null ) || fail "local regen failed"
grep -q 'source of truth: docs/issues/ local tracker' "$SB/ISSUES.md" || fail "local disclosure regressed"

echo "PASS: gen-mirrors gitlab disclosure"
```

- [ ] **Step 2: Run it.**
      `bash tests/repo-state/mirrors-gitlab.sh`
      Expect FAIL with `ISSUES.md does not disclose GitLab as the source of truth`, because `SRC_LABEL` defaults to `GitHub issues` for any non-local mode.

- [ ] **Step 3: Implement.**
      In `scripts/gen-mirrors.sh`, replace the `SRC_LABEL` block at lines 84-87 with a single `case` over the mode read once into a variable:
      `github` and an unreadable mode both give `GitHub issues`, `gitlab` gives `GitLab issues`, `local` gives `docs/issues/ local tracker`.
      Also update the file's header comment on line 2, which currently says "render open GitHub issues", to say the source is the declared tracker backend.
      Change nothing else in the file; the awk parser is already backend-agnostic because it consumes the gh shape.

- [ ] **Step 4: Run it.**
      `bash tests/repo-state/mirrors-gitlab.sh` - expect PASS.
      Then `bash tests/repo-state/mirrors.sh` - expect PASS.

- [ ] **Step 5: Commit.**
      ```bash
      git add scripts/gen-mirrors.sh tests/repo-state/mirrors-gitlab.sh
      git commit -m "gen-mirrors: disclose GitLab as the source of truth in gitlab mode"
      ```

---

### Task 3: `setup.sh` gitlab mode - remote detection, render, finalize

Depends on: Task 1, Task 2 (the finalize's provenance guard greps for Task 2's `GitLab issues` string)

**Files (exclusive ownership):**

- Modify: `skills/loop-setup/setup.sh`
- Modify: `config/repo-state.template.md`
- Modify: `tests/loop-setup/acceptance.sh:56,66` (the two remote-report string assertions)
- Modify: `skills/loop-setup/SKILL.md` (step k only: the remote-report strings and the two "never re-asks" claims; Task 6 owns the full rewrite and asserts these strings)
- Test: `tests/loop-setup/gitlab-setup.sh` (create)

**Interfaces:**

Consumes, from Task 1:
`scripts/tracker.sh mode set gitlab`, `scripts/tracker.sh host`, `scripts/tracker.sh group`.

Produces, for Tasks 4 through 7:

- `render_gitlab <remote-url> <backlog-group>` emits a config with the Local tracker section stripped, `Remote: <url>`, and a line-anchored `backlog-group: <group>` key.
- `report_remote` prints exactly one of four lines to stdout:
  - `GitHub remote found: <url> - suggesting tracker: github`
  - `GitLab remote found: <url> - suggesting tracker: gitlab`
  - `Remote found: <url> - no backend inferred; choose a tracker mode (no default)`
  - `No remote found - choose a tracker mode (no default)`
- `determine_mode` accepts and validates `github|gitlab|local`; `LOOP_TRACKER_ANSWER=gitlab` supplies it non-interactively.
- The template carries `template-version: 2`.

**Acceptance check:** `bash tests/loop-setup/gitlab-setup.sh && bash tests/run.sh` exits 0 `[executed-check]`
The full-suite half is load-bearing: this task edits the shared `setup.sh` and `tests/loop-setup/acceptance.sh`, so the new suite alone cannot gate what the task can break.

- [ ] **Step 1: Write the failing test.**
      Create `tests/loop-setup/gitlab-setup.sh` with exactly this content:

```bash
#!/usr/bin/env bash
# loop-setup in gitlab mode: remote detection and suggestion, config render with the derived
# backlog group, gitlab finalize (host-scoped auth, idea label, gen-mirrors provenance guard),
# repair of a false "Remote: none" line inherited from a local-mode config, gitlab-only lines
# dropped from github and local renders, and the tracker-remote-ack off switch for a deliberate
# mode-versus-remote disagreement.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SETUP="$REPO/skills/loop-setup/setup.sh"
FIX="$REPO/tests/repo-state/fixtures/issues.json"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$SETUP" ] || fail "setup.sh missing"

BIN="$(mktemp -d)"; trap 'rm -rf "$BIN"' EXIT
LOG="$BIN/glab.calls"
cat > "$BIN/glab" <<EOF
#!/usr/bin/env bash
echo "GLAB CALLED: \$*" >> "$LOG"
if [ "\$1" = auth ] && [ "\$2" = status ]; then
  for a in "\$@"; do [ "\$a" = --hostname ] && exit 0; done
  exit 1
fi
if [ "\$1" = issue ] && [ "\$2" = list ]; then exit 0; fi
if [ "\$1" = label ] && [ "\$2" = list ]; then echo "[]"; exit 0; fi
if [ "\$1" = label ] && [ "\$2" = create ]; then exit 0; fi
exit 0
EOF
chmod +x "$BIN/glab"
export PATH="$BIN:$PATH"

# ---------- scenario A: a fresh gitlab repo ----------
A="$(mktemp -d)"; trap 'rm -rf "$BIN" "$A"' EXIT
( cd "$A" && git init -q \
    && git remote add origin 'ssh://git@gitlab.code.rit.edu:2222/university-advancement/crm/forge.git' )

out="$( cd "$A" && LOOP_TRACKER_ANSWER=gitlab LOOP_ASSUME_NO=1 "$SETUP" </dev/null 2>/dev/null )" \
  || fail "gitlab setup exited non-zero"

printf '%s\n' "$out" | grep -q 'GitLab remote found: ssh://git@gitlab.code.rit.edu:2222/university-advancement/crm/forge.git - suggesting tracker: gitlab' \
  || fail "setup did not report the GitLab remote and suggest gitlab"

[ "$(grep -c '^tracker: gitlab$' "$A/config/repo-state.md")" -eq 1 ] \
  || fail "config does not carry exactly one 'tracker: gitlab' line"
grep -q '^Remote: ssh://git@gitlab.code.rit.edu:2222/university-advancement/crm/forge.git$' "$A/config/repo-state.md" \
  || fail "config did not record the real remote URL"
grep -q '^backlog-group: university-advancement$' "$A/config/repo-state.md" \
  || fail "config did not derive backlog-group from the remote path (criterion 6)"
grep -q '^template-version: 2$' "$A/config/repo-state.md" \
  || fail "gitlab render carries no template-version 2 stamp"
grep -q '## Local tracker' "$A/config/repo-state.md" \
  && fail "gitlab render kept the Local tracker section"
grep -qi 'local tracker section governs local mode' "$A/config/repo-state.md" \
  && fail "gitlab render kept a dangling pointer to the stripped Local tracker section"
grep -q 'glab issue list --label idea' "$A/config/repo-state.md" \
  || fail "gitlab config does not name the glab per-repo backlog query"
[ -d "$A/docs/handoffs" ] && [ -d "$A/docs/reviews" ] && [ -d "$A/docs/archive" ] \
  || fail "docs homes were not created in gitlab mode"
[ -f "$A/ISSUES.md" ] && [ -f "$A/BACKLOG.md" ] || fail "mirrors were not generated in gitlab mode"

# the auth guard is host-scoped, and the idea label was created
grep -q 'GLAB CALLED: auth status --hostname gitlab.code.rit.edu' "$LOG" \
  || fail "gitlab finalize did not run a --hostname-scoped auth status"
grep -E 'GLAB CALLED: auth status$' "$LOG" && fail "gitlab finalize ran a BARE glab auth status"
grep -q 'GLAB CALLED: label create --name idea' "$LOG" \
  || fail "gitlab finalize did not create the idea label"

# ---------- scenario B: a gitlab-DECLARED config still carrying the local-tracker Remote ----------
# ---------- placeholder; the re-render must repair the false "Remote: none" line     ----------
# (The declared-local-plus-GitLab-remote disagreement - forge's actual shape - is scenario E's
# job, not this one: here existing_mode is already gitlab, so only reconcile_config's new
# none-prefix fallback is exercised.)
B="$(mktemp -d)"; trap 'rm -rf "$BIN" "$A" "$B"' EXIT
( cd "$B" && git init -q \
    && git remote add origin 'ssh://git@gitlab.code.rit.edu:2222/university-advancement/crm/forge.git' )
mkdir -p "$B/config"
cat > "$B/config/repo-state.md" <<'EOS'
# Repo State Map

template-version: 1

Remote: none (local tracker; see the Local tracker section)

## Local tracker
placeholder
tracker: gitlab
EOS
( cd "$B" && LOOP_ASSUME_YES=1 "$SETUP" </dev/null >/dev/null 2>&1 ) \
  || fail "re-render of the mislabelled config exited non-zero"
grep -q '^Remote: ssh://git@gitlab.code.rit.edu:2222/university-advancement/crm/forge.git$' "$B/config/repo-state.md" \
  || fail "the false 'Remote: none' line survived the gitlab re-render"
grep -q 'none (local tracker' "$B/config/repo-state.md" \
  && fail "the local-tracker Remote placeholder is still present after re-render"

# ---------- scenario C: a non-inferable remote gets a report and NO suggestion ----------
C="$(mktemp -d)"; trap 'rm -rf "$BIN" "$A" "$B" "$C"' EXIT
( cd "$C" && git init -q && git remote add origin 'https://git.example.org/team/thing.git' )
out="$( cd "$C" && LOOP_TRACKER_ANSWER=local "$SETUP" </dev/null 2>/dev/null )" \
  || fail "non-inferable-remote setup exited non-zero"
printf '%s\n' "$out" | grep -q 'Remote found: https://git.example.org/team/thing.git - no backend inferred' \
  || fail "a non-github non-gitlab remote was not reported as found-but-uninferable"
printf '%s\n' "$out" | grep -qi 'no remote found' \
  && fail "a repo WITH a remote was reported as having none (the forge bug)"

# the gitlab-only lines are DROPPED from a local render, never substituted into
grep -q '{{BACKLOG_GROUP}}' "$C/config/repo-state.md" && fail "an unsubstituted placeholder leaked into a local render"
grep -q '^backlog-group:' "$C/config/repo-state.md"   && fail "a local render kept the gitlab backlog-group key"
grep -q 'glab issue list' "$C/config/repo-state.md"   && fail "a local render kept the gitlab backlog-view lines"

# ---------- scenario C2: a github render carries the widened sentence and no gitlab lines ----------
C2="$(mktemp -d)"; trap 'rm -rf "$BIN" "$A" "$B" "$C" "$C2"' EXIT
( cd "$C2" && git init -q && git remote add origin 'https://github.com/acme/x.git' )
( cd "$C2" && LOOP_TRACKER_ANSWER=github MIRRORS_JSON_FILE="$FIX" "$SETUP" --dry-run-remote </dev/null >/dev/null 2>&1 ) \
  || fail "github render run exited non-zero"
grep -q '(github, gitlab, or local)' "$C2/config/repo-state.md" \
  || fail "a github render still says (github or local): setup.sh's hardcoded replacement sentence was never widened"
grep -q '^backlog-group:' "$C2/config/repo-state.md" && fail "a github render kept a bare backlog-group key"
grep -q 'glab issue list' "$C2/config/repo-state.md" && fail "a github render kept the gitlab backlog-view lines"

# ---------- scenario D: an unknown mode answer is rejected ----------
D="$(mktemp -d)"; trap 'rm -rf "$BIN" "$A" "$B" "$C" "$C2" "$D"' EXIT
( cd "$D" && git init -q )
( cd "$D" && LOOP_TRACKER_ANSWER=bitbucket "$SETUP" </dev/null >/dev/null 2>&1 ) \
  && fail "setup accepted an unknown tracker mode"

# ---------- scenario E: THE FORGE CASE - a declared mode that disagrees with the remote ----------
# This is the shape of /home/jjrdar/claude/forge: tracker: local declared, GitLab remote present.
# Before this fix, setup.sh short-circuited at line 203 and none of the above was reachable there.
E="$(mktemp -d)"; trap 'rm -rf "$BIN" "$A" "$B" "$C" "$C2" "$D" "$E"' EXIT
( cd "$E" && git init -q \
    && git remote add origin 'ssh://git@gitlab.code.rit.edu:2222/university-advancement/crm/forge.git' )
mkdir -p "$E/config" "$E/scripts"
cp "$REPO/scripts/tracker.sh" "$E/scripts/tracker.sh"; chmod +x "$E/scripts/tracker.sh"
printf 'template-version: 1\n\nRemote: none (local tracker; see the Local tracker section)\n\ntracker: local\n' \
  > "$E/config/repo-state.md"

# declining the switch leaves everything alone, but the disagreement is still STATED
out="$( cd "$E" && LOOP_ASSUME_NO=1 "$SETUP" </dev/null 2>&1 )" || fail "forge-shaped run exited non-zero"
printf '%s\n' "$out" | grep -q 'GitLab remote found' \
  || fail "a repo with a declared mode never reported its remote (the forge bug)"
printf '%s\n' "$out" | grep -q 'declared tracker: local, but the remote is gitlab' \
  || fail "setup stayed silent about a declared mode that disagrees with the remote"
[ "$(grep '^tracker:' "$E/config/repo-state.md")" = "tracker: local" ] \
  || fail "a DECLINED switch changed the tracker mode anyway"

# a declined switch names the off switch, and the ack key silences the offer without silencing
# the remote report - a deliberate tracker: local behind a remote must be recordable
printf '%s\n' "$out" | grep -q 'tracker-remote-ack' \
  || fail "the declined switch did not name the tracker-remote-ack acknowledgment key"
printf 'tracker-remote-ack: gitlab\n' >> "$E/config/repo-state.md"
out="$( cd "$E" && LOOP_ASSUME_NO=1 "$SETUP" </dev/null 2>&1 )" || fail "acknowledged run exited non-zero"
printf '%s\n' "$out" | grep -q 'but the remote is' && fail "an acknowledged disagreement was still nagged"
printf '%s\n' "$out" | grep -q 'GitLab remote found' \
  || fail "the ack silenced the remote report too (it must only silence the switch offer)"
sed -i.bak '/^tracker-remote-ack:/d' "$E/config/repo-state.md" && rm -f "$E/config/repo-state.md.bak"

# accepting the switch flips the mode AND corrects the false Remote line on the same run
out="$( cd "$E" && LOOP_ASSUME_YES=1 "$SETUP" </dev/null 2>&1 )" || fail "accepted switch exited non-zero"
[ "$(grep '^tracker:' "$E/config/repo-state.md")" = "tracker: gitlab" ] \
  || fail "an accepted switch did not flip the mode to gitlab (criterion 5)"
grep -q '^Remote: ssh://git@gitlab.code.rit.edu:2222/university-advancement/crm/forge.git$' "$E/config/repo-state.md" \
  || fail "the false 'Remote: none' line survived the accepted switch"
grep -q '^backlog-group: university-advancement$' "$E/config/repo-state.md" \
  || fail "the switched config did not derive backlog-group"

# a repo whose declared mode AGREES with its remote is never nagged
out="$( cd "$E" && "$SETUP" </dev/null 2>&1 )" || fail "settled forge-shaped re-run exited non-zero"
printf '%s\n' "$out" | grep -q 'but the remote is' && fail "an agreeing repo was offered a mode switch"

# ---------- scenario F: a vendored tracker.sh that rejects the mode fails the run loudly ----------
F="$(mktemp -d)"; trap 'rm -rf "$BIN" "$A" "$B" "$C" "$C2" "$D" "$E" "$F"' EXIT
( cd "$F" && git init -q && git remote add origin 'ssh://git@gitlab.example.com:2222/grp/repo.git' )
mkdir -p "$F/scripts"
# A pre-gitlab tracker.sh: its mode set rejects 'gitlab'. It must report NO declared mode, so the
# run reaches determine_mode and resolves to gitlab; a stub that echoed a mode would short-circuit
# at line 203 and the call under test would never be reached.
printf '#!/usr/bin/env bash\n# legacy: predates the gitlab backend\nexit 1\n' > "$F/scripts/tracker.sh"
chmod +x "$F/scripts/tracker.sh"
# LOOP_ASSUME_NO declines the drift refresh, so the legacy copy survives to the mode set call.
out="$( cd "$F" && LOOP_TRACKER_ANSWER=gitlab LOOP_ASSUME_NO=1 "$SETUP" </dev/null 2>&1 )" \
  && fail "setup exited 0 although the vendored tracker.sh rejected the mode (silent today via >/dev/null)"
printf '%s\n' "$out" | grep -q 'accept the drift refresh' \
  || fail "the mode-set failure did not name the fix (accept the drift refresh and re-run)"

# ---------- scenario G: the gitlab finalize refuses a gen-mirrors.sh that cannot disclose GitLab ----------
# A declined gen-mirrors.sh drift refresh must not produce mirrors claiming GitHub as the source
# of truth on a GitLab repo - the file's entire purpose is disclosure.
G="$(mktemp -d)"; trap 'rm -rf "$BIN" "$A" "$B" "$C" "$C2" "$D" "$E" "$F" "$G"' EXIT
( cd "$G" && git init -q && git remote add origin 'ssh://git@gitlab.example.com:2222/grp/repo.git' )
mkdir -p "$G/scripts"
printf '#!/usr/bin/env bash\n# legacy: knows only GitHub issues as a remote source\nexit 0\n' \
  > "$G/scripts/gen-mirrors.sh"
chmod +x "$G/scripts/gen-mirrors.sh"
out="$( cd "$G" && LOOP_TRACKER_ANSWER=gitlab LOOP_ASSUME_NO=1 "$SETUP" </dev/null 2>&1 )" \
  && fail "the gitlab finalize exited 0 with a gen-mirrors.sh that would disclose GitHub"
printf '%s\n' "$out" | grep -q 'drift refresh' \
  || fail "the provenance failure did not name the fix (accept the gen-mirrors.sh drift refresh)"

echo "PASS: loop-setup gitlab mode"
```

- [ ] **Step 2: Run it.**
      `bash tests/loop-setup/gitlab-setup.sh`
      Expect FAIL with `setup did not report the GitLab remote and suggest gitlab`, because `setup.sh:46` greps the remote list only for `github.com`.

- [ ] **Step 3: Implement.**

  a. In `config/repo-state.template.md`:
     - Bump `template-version: 1` to `template-version: 2`.
     - Change line 5 to name all three backends: `The tracker backend (github, gitlab, or local) is declared in the `tracker:` key below; the Local tracker section governs local mode.`
     - Change line 23 the same way, to `(value `github`, `gitlab`, or `local`)`.
     - Add a `backlog-group: {{BACKLOG_GROUP}}` placeholder line directly under the `Remote:` line.
     - Under the "Backlog cross-repo view" lines, add the gitlab equivalents:
       `Backlog cross-repo view, gitlab: `glab issue list --group {{BACKLOG_GROUP}} --label idea`.`
       `Per-repo fallback, gitlab: `glab issue list --label idea`.`
     - In the Local tracker section, change the wayfinder limitation from `wayfinder requires `tracker: github`` to `wayfinder requires a remote tracker (`github` or `gitlab`); its map is issue-shaped end to end, with no local-tracker variant`.
     - In the same section's numbering limitation, change the ending `shared or branched work should use `tracker: github`` to `shared or branched work should use a remote tracker (`github` or `gitlab`)` - the second github-only assertion in that block, easy to miss because the wayfinder line sits two lines above it.
     - Add one line to the Local tracker section's migration paragraph naming gitlab as a migration target: `Migration targets either remote backend; `scripts/migrate-tracker.sh --to gitlab` recreates every local issue as a GitLab issue.`
     - After the Lanes table, add the autonomy-default paragraph verbatim from the shipped `config/repo-state.md` (the two sentences beginning `The committed per-repo autonomy default is a line-anchored \`autonomy-default:\` key`).
       The shipped config carries it and the template does not, so today's config is a hand-maintained superset a re-render would silently destroy; a v2 render must round-trip it.
     - After the sentence claiming the file is "the definitive list", add one sentence declaring the import sweep's exclusions, so the set is discoverable where the claim is made: the sweep never offers the root project files `README.md`, `CLAUDE.md`, `AGENTS.md`, `PLAN.md`, `CHANGELOG.md`, `LICENSE.md`, `CONTRIBUTING.md`, nor anything under `docs/plans/`, `docs/briefs/`, `docs/issues/`, `docs/handoffs/`, `docs/reviews/`, or `docs/archive/`.

  b. In `skills/loop-setup/setup.sh`, replace the remote detection at lines 38-47.
     Capture a remote, preferring `origin` but falling back to the first remote of any name, then classify it:
     ```bash
     remote_url="$(git remote get-url origin 2>/dev/null || true)"
     # Falling back matters: today's line 46 scans `git remote -v` for ANY remote, so a repo whose
     # only GitHub remote is named `upstream` is detected. Keying solely on origin would regress it.
     [ -n "$remote_url" ] || remote_url="$(git remote -v 2>/dev/null | awk 'NR==1 {print $2}' || true)"
     remote_kind=none
     if [ -n "$remote_url" ]; then
       remote_kind=other
       case "$remote_url" in *github.com*) remote_kind=github ;; *gitlab*) remote_kind=gitlab ;; esac
     fi
     ```
     `scripts/tracker.sh host` and `group` still read `origin` only, because glab itself resolves its target from the repo's remote and the guard must check the host glab will actually contact.
     When `origin` is absent but another remote exists, the gitlab finalize fails with the existing "requires an origin remote to resolve the GitLab host" message rather than guessing.
     Keep the `--dry-run-remote` branch, which forces `remote_url` to origin-or-stub; set `remote_kind=github` for the stub URL so existing dry-run tests keep their behavior.
     Classifying on the substring `gitlab` is a heuristic, not a fact: a self-hosted instance at a hostname without "gitlab" in it correctly falls to `other`, which reports the remote and suggests nothing.
     Leave a comment saying exactly that.

  c. Rewrite `report_remote` to print the four lines named in Interfaces, one per `remote_kind`.

  d. In `determine_mode`, change the prompt to `tracker mode (github|gitlab|local): `.

  e. Add `render_gitlab`, modelled on `render_github` but taking two arguments.
     It strips the `## Local tracker` section by heading exactly as `render_github` does, replaces `{{REMOTE_OR_FALLBACK}}` with `Remote: <url>`, replaces every `{{BACKLOG_GROUP}}` occurrence with the group, rewrites the "the Local tracker section governs local mode" sentence to `The tracker backend (github, gitlab, or local) is declared in the `tracker:` key below.`, and drops the "Render it into" line.
     Also update `render_github` and `render_local` to **drop the gitlab-only lines outright** rather than substituting into them: the `backlog-group:` line and the two gitlab backlog-view lines are removed with the same `index($0, ...)`/`next` awk mechanism already used for the "Render it into" line.
     Substituting would render a broken `glab issue list --group n/a (local tracker) --label idea` command into every local config and a bare `backlog-group:` line into every github config, and no existing suite diffs a github or local render against the template.
     And update the hardcoded sentence `render_github` emits at `setup.sh:99` from `(github or local)` to `(github, gitlab, or local)`, so a github render matches the widened template it claims to be a render of.

  f. Repair `reconcile_config` (lines 139-145) so a remote mode never preserves a local-tracker placeholder as its Remote value.
     Read the recorded `Remote:` value; if it is empty **or** begins with `none`, fall back to `$remote_url`.
     Add the `gitlab` branch, which reads the recorded `backlog-group:` value (preserving a user override) and falls back to `scripts/tracker.sh group` when absent, then calls `render_gitlab`.

  g. In the mode-resolution block at lines 209-219, add `gitlab)` to the render `case`, calling `render_gitlab "$remote_url" "$(scripts/tracker.sh group 2>/dev/null || true)"`.
     Update the failure message to `"tracker mode must be 'github', 'gitlab', or 'local' (got '$MODE')"`.

  g2. **Fix the short-circuit that makes forge unreachable.**
     `setup.sh:203-206` returns early whenever a `tracker:` key already exists: it prints `tracker mode: <m> (declared); not re-asking` and skips `report_remote`, `determine_mode`, and the whole render `case`.
     forge carries `tracker: local`, so today every path this plan adds is dead there, `MODE` stays `local`, and `reconcile_config` calls `render_local`, which writes `Remote: none (local tracker; see the Local tracker section)` straight back over the correction.
     Without this fix criterion 5 is unobservable in forge and the brief's end artifact cannot be produced.

     Keep the "never silently re-ask" property, but stop being silent when the declared mode and the remote disagree.
     In the `if [ -n "$existing_mode" ]` branch, after setting `MODE`:
     - Call `report_remote` whenever `remote_kind` is not `none`, so the remote is stated on every run rather than only on first setup.
       When `remote_kind` is `none` on this declared-mode path, print nothing: the fresh-setup wording ends in "choose a tracker mode (no default)", which would be a standing false instruction on every run of a settled no-remote repo.
     - When `remote_kind` is `github` or `gitlab` and it differs from `existing_mode`, print
       `declared tracker: <existing_mode>, but the remote is <remote_kind>: <url>`
       and offer, via the existing `ask`, `switch this repo to tracker: <remote_kind>?`.
     - On accept, run `scripts/tracker.sh mode set "<remote_kind>"` (guarded per g3), set `MODE` to it, and let `reconcile_config` render the correct config on the same run.
     - On decline, leave everything untouched and print one line naming the off switch: `to stop this suggestion, add 'tracker-remote-ack: <remote_kind>' to config/repo-state.md`.
       Without the ack, the offer repeats on the next run - the intended durability for a live, unacknowledged disagreement.
     - Skip the offer (but never the `report_remote` line) when the config carries a line-anchored `tracker-remote-ack:` key whose value equals `remote_kind`.
       This is the acknowledgment path for a deliberate `tracker: local` behind a remote, which `config/repo-state.md`'s own guidance tells users to choose for branched work: without it, that documented choice is the one offer with unbounded repeat and no off switch.
       The ack is written by the user or agent by hand, never by `setup.sh` - an auto-recorded decline would be the durable-decline ledger this plan already cut.
     A `remote_kind` of `other` or `none` never triggers the offer: there is nothing to suggest.

  g3. **Check the exit status of every `tracker.sh mode set` call.**
     `setup.sh` drives the target repo's own vendored `scripts/tracker.sh`, and the drift refresh at lines 75-87 is declinable per file.
     Declining it while choosing gitlab leaves a pre-gitlab `tracker.sh` whose validation rejects `gitlab` - and line 219's `scripts/tracker.sh mode set "$MODE" >/dev/null` swallows only stdout, not the exit code, which nothing checks, so the failure is silent and the run continues believing the mode was set.
     Append `|| fail "scripts/tracker.sh rejected mode '$MODE' - it may predate this backend; accept the drift refresh and re-run"` to the line-219 call and to g2's switch-path call.
     One exit-status check at the call sites replaces a content heuristic (an earlier draft grepped `tracker.sh` for a `gitlab)` case) and catches more: any `mode set` failure, not just the stale-vendored-copy one.
     Task 1's four-branch `case` with a failing default is the second half of this guard: it turns the same mistake into a loud error at every later `tracker.sh` call, not only during setup.

  h. In the finalize block at lines 223-239, convert the two-branch `if` into a three-branch `case "$MODE"`.
     The `gitlab` branch, under `[ "$DRY_REMOTE" -eq 0 ]`:
     ```
     host="$(scripts/tracker.sh host 2>/dev/null || true)"
     [ -n "$host" ] || fail "tracker: gitlab requires an origin remote to resolve the GitLab host"
     command -v glab >/dev/null 2>&1 && glab auth status --hostname "$host" >/dev/null 2>&1 \
       || fail "tracker: gitlab requires glab authenticated to $host (install glab and run: glab auth login --hostname $host)"
     if ! glab label list -F json --jq '.[].name' 2>/dev/null | grep -qx 'idea'; then
       glab label create --name idea --description "Backlog candidate" >/dev/null 2>&1 \
         && echo "created label idea" || echo "label idea not created; continuing"
     else echo "label idea exists; skipping"; fi
     ```
     Under dry-run, echo `dry-run-remote: skipping glab auth check and glab label create`.
     Both remote branches end with the existing `scripts/gen-mirrors.sh . || fail "gen-mirrors.sh failed"`.
     Before that call, the gitlab branch (dry-run included) verifies the target repo's vendored copy can disclose GitLab:
     ```bash
     grep -q 'GitLab issues' scripts/gen-mirrors.sh \
       || fail "scripts/gen-mirrors.sh predates the gitlab backend and would disclose GitHub as the source of truth - accept the gen-mirrors.sh drift refresh and re-run"
     ```
     The drift refresh at `setup.sh:75-87` is declinable per file, and a declined `gen-mirrors.sh` refresh would otherwise leave every mirror on a GitLab repo claiming `source of truth: GitHub issues` - a lie in the file whose entire purpose is disclosure.
     A content grep is the right guard here (where g3 used an exit status) because `gen-mirrors.sh` defaults its `SRC_LABEL` silently; there is no failure to check.

  i. Update the header comment on lines 2-4 to name the gitlab finalize.

  j. In `tests/loop-setup/acceptance.sh`, update line 56's expected string to `GitHub remote found` (unchanged) and line 66's to `No remote found`, matching the new wording.

  k. In `skills/loop-setup/SKILL.md`, make the three edits that would otherwise leave the skill naming strings the script no longer prints for the three commits until Task 6:
     - Line 29 documents the literal `No GitHub remote found`, which lives in exactly two shipped places (`setup.sh:121` and this line); replace that sentence with the four exact `report_remote` lines from Interfaces.
     - Line 16's "skips the question entirely (idempotent, never re-asks)" and line 39's "a declared mode is never re-asked" now promise the opposite of what g2 does; qualify both: the mode question is never re-asked, but when the declared mode disagrees with a github or gitlab remote, setup states the disagreement and offers a declinable switch, silenced by a `tracker-remote-ack:` line in the config.
     This step is deliberately narrow; Task 6 owns the full SKILL.md rewrite and its test asserts these strings.

- [ ] **Step 4: Run it.**
      `bash tests/loop-setup/gitlab-setup.sh` - expect PASS.
      Then `bash tests/run.sh` - expect `0 failed`; this task edits the shared `setup.sh` and `tests/loop-setup/acceptance.sh`, so the full suite is part of the gate, not a courtesy.
      Note: `tests/loop-setup/reconcile.sh` compares an accepted re-render against a fresh render, so it passes across the template bump without editing.

- [ ] **Step 5: Commit.**
      ```bash
      git add skills/loop-setup/setup.sh config/repo-state.template.md skills/loop-setup/SKILL.md \
              tests/loop-setup/gitlab-setup.sh tests/loop-setup/acceptance.sh
      git commit -m "loop-setup: gitlab mode with remote suggestion, derived backlog group, and glab finalize"
      ```

---

### Task 4: `setup.sh` universal sweep - all modes, root scan, archive-on-import idempotence

Depends on: Task 3

**Files (exclusive ownership):**

- Modify: `skills/loop-setup/setup.sh`
- Modify: `tests/loop-setup/import.sh` (header comment and one relaxed assertion, per step d; the sweep is no longer local-mode-only)
- Test: `tests/loop-setup/idempotence.sh` (create)

`tests/loop-setup/reconcile.sh` and `tests/repo-state/config.sh` are deliberately **not** touched: an earlier ledger-based design required rewriting both, and cutting it at the bloat review returned them to their shipped state, including the existing decline-then-accept contract in `reconcile.sh`.

**Interfaces:**

Consumes, from Task 3: `render_gitlab`, the repaired `reconcile_config`, `report_remote`.

Produces, for Tasks 5 through 7:

- `reconcile_import` runs in all three modes and additionally scans repo-root `*.md` non-recursively.
- `is_excluded` grows two guards: the `docs/plans/*` prefix (plan documents are a governed lane; the Archive-and-graduation rules in `config/repo-state.md` own plan and brief archival, not the sweep), and the depth-1 root project names listed in step a.
- Idempotence is state of the world, not a state file: an imported candidate is offered a move to `docs/archive/`, which `is_excluded` already skips, so a settled repo offers nothing on re-run; a declined-and-left candidate re-offers next run behind the gate question, one keystroke, by design.
- The archive move never overwrites (an existing destination skips the move, with a message) and never reaches outside the repo (a candidate whose normalized path is absolute or starts with `../` is imported but gets no archive offer).
- Before any per-item offer, the sweep prints `found N import candidate(s)` to stdout and asks one gate question, `review them?`, through the existing `ask()` - so `LOOP_ASSUME_YES`/`LOOP_ASSUME_NO` answer it like every other question, and the count line prints even when `ask()` short-circuits on those variables without showing its prompt.
- A new hook, `LOOP_IMPORT_REMOTE=1`, required in addition to `LOOP_ASSUME_YES` before an unattended run may create issues on a **remote** backend.
  The skip condition is stated literally in step a; it keys on the unattended-yes variable and on `DRY_REMOTE`, never on `MODE` alone, so interactive per-item answers are unaffected.
  Local mode ignores it.
  It exists because ungating the sweep changed the unattended blast radius from "writes local markdown" to "files an issue per candidate on a shared instance", and that escalation should be opted into explicitly rather than inherited from a blanket yes.
- After a sweep that imported at least one candidate, the mirrors are re-rendered, so a run never ends by printing completion over an `ISSUES.md`/`BACKLOG.md` that lack the issues it just filed.
- The run ends with a summary: `loop-setup complete - nothing to do` when no offer source fired, so quiet is a statement rather than an absence.

**Acceptance check:** `bash tests/loop-setup/idempotence.sh && bash tests/run.sh` exits 0 `[executed-check]`
The full-suite half is load-bearing: this task edits the shared `setup.sh` and `tests/loop-setup/import.sh`, so the new suite alone cannot gate what the task can break.

- [ ] **Step 1: Write the failing test.**
      Create `tests/loop-setup/idempotence.sh` with exactly this content:

```bash
#!/usr/bin/env bash
# Criteria 7 and 8 (revised): the sweep runs in all three modes behind one gate question then
# per-item confirmation; archive-on-import makes a settled repo offer nothing on re-run and SAY
# so; a declined-and-left candidate re-offers next run (durability lives in the archive move,
# not a state file); remote modes need LOOP_IMPORT_REMOTE for unattended creation, and the gate
# keys on the unattended variable, never on MODE; --dry-run-remote never creates; docs/plans/
# and root project files are never offered; the archive move never overwrites and never
# reaches outside the repo; mirrors are re-rendered after an importing sweep.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SETUP="$REPO/skills/loop-setup/setup.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$SETUP" ] || fail "setup.sh missing"

mk() {   # $1 = dir; a local-mode repo with one root candidate and one docs candidate
  mkdir -p "$1/docs"
  ( cd "$1" && git init -q )
  printf '# What is next\nLabel: idea\nship the thing\n' > "$1/whats_next.md"
  printf '# The todo\nLabel: idea\ndo the work\n'        > "$1/docs/some-todo.md"
}

# ---------- criterion 7: gate then per-item in local mode; the repo root is reached ----------
A="$(mktemp -d)"; trap 'rm -rf "$A"' EXIT
mk "$A"
# never offered: docs/plans/ is a governed lane, and a root PLAN.md is a project document
mkdir -p "$A/docs/plans" "$A/docs/nested"
printf '# Old plan\nLabel: idea\nsettled work\n'   > "$A/docs/plans/2020-01-01-old-plan.md"
printf '# Plan\nLabel: idea\nproject file\n'       > "$A/PLAN.md"
# offered: the root-name exclusion is depth-1 only, so a nested PLAN.md stays a candidate
printf '# Nested plan\nLabel: idea\nnested work\n' > "$A/docs/nested/PLAN.md"
out="$( cd "$A" && LOOP_TRACKER_ANSWER=local LOOP_ASSUME_YES=1 "$SETUP" </dev/null 2>/dev/null )" \
  || fail "local sweep run exited non-zero"
# the count line prints to stdout BEFORE the gate, because ask() returns without printing its
# prompt when LOOP_ASSUME_* is set - the count is the only always-visible trace of the gate
printf '%s\n' "$out" | grep -q 'found 3 import candidate' || fail "sweep did not announce its candidate count"
printf '%s\n' "$out" | grep -qi 'import candidate:' || fail "sweep offered no candidates in local mode"
# the ROOT file is reached - the current scan roots miss it, which is the forge bug
printf '%s\n' "$out" | grep -q 'whats_next.md' || fail "sweep did not reach the repo-root whats_next.md"
printf '%s\n' "$out" | grep -q 'docs/some-todo.md' || fail "sweep did not reach docs/some-todo.md"
printf '%s\n' "$out" | grep -q 'docs/nested/PLAN.md' \
  || fail "a nested PLAN.md stopped being a candidate (the root-name exclusion must be depth-1 only)"
printf '%s\n' "$out" | grep -q 'docs/plans/' \
  && fail "the sweep offered a plan-lane file (docs/plans/ archival is owned by the Archive-and-graduation rules)"
printf '%s\n' "$out" | grep -q 'import candidate: PLAN.md ' \
  && fail "the sweep offered the root PLAN.md project file"
[ "$(ls "$A/docs/issues"/*.md 2>/dev/null | wc -l)" -eq 3 ] || fail "accept-all did not create three issues"
# accept-all also accepts the archive offer, so the imported sources moved and the originals are gone
[ -f "$A/docs/archive/whats_next.md" ] || fail "imported root candidate was not archived"
[ -f "$A/docs/archive/some-todo.md" ]  || fail "imported docs candidate was not archived"
[ -f "$A/docs/archive/PLAN.md" ]       || fail "imported nested candidate was not archived"
[ -f "$A/whats_next.md" ] && fail "archived candidate still present at its original path"
[ -f "$A/PLAN.md" ] || fail "the excluded root PLAN.md was moved or deleted"
[ -f "$A/docs/plans/2020-01-01-old-plan.md" ] || fail "the excluded plan-lane file was moved or deleted"
# an importing sweep re-renders the mirrors, so the run never ends over stale ISSUES/BACKLOG
grep -q 'What is next' "$A/BACKLOG.md" || fail "the mirrors were not re-rendered after the sweep imported issues"

# ---------- criterion 8 (revised): the settled repo offers nothing AND says so ----------
# No state file: quiet follows from the archive move alone (docs/archive/* is excluded from the scan).
out2="$( cd "$A" && "$SETUP" </dev/null 2>/dev/null )" || fail "second run exited non-zero"
printf '%s\n' "$out2" | grep -qi 'import candidate' && fail "settled repo re-offered a candidate"
printf '%s\n' "$out2" | grep -qi 'nothing to do'    || fail "settled repo went quiet instead of saying nothing to do"

# ---------- a NEW candidate appearing later is offered; archived ones stay quiet ----------
printf '# Todo\nLabel: idea\nnew work\n' > "$A/docs/late-todo.md"
out3="$( cd "$A" && LOOP_ASSUME_NO=1 "$SETUP" </dev/null 2>/dev/null )" || fail "new-candidate run exited non-zero"
printf '%s\n' "$out3" | grep -q 'found 1 import candidate' \
  || fail "a newly added candidate was not picked up (or an archived one leaked back in)"

# ---------- declined-and-left re-offers next run: the CONTRACT, not a bug ----------
B="$(mktemp -d)"; trap 'rm -rf "$A" "$B"' EXIT
mk "$B"
outB="$( cd "$B" && LOOP_TRACKER_ANSWER=local LOOP_ASSUME_NO=1 "$SETUP" </dev/null 2>/dev/null )" \
  || fail "decline-at-gate run exited non-zero"
[ "$(printf '%s\n' "$outB" | grep -c 'found 2 import candidate')" -eq 1 ] \
  || fail "the candidate count was not announced exactly once"
printf '%s\n' "$outB" | grep -qi 'import candidate:' && fail "a declined gate still offered items"
# the false direction of the summary line: a run that OFFERED the gate may never claim quiet
printf '%s\n' "$outB" | grep -qi 'nothing to do' && fail "a run that offered the gate claimed nothing to do"
[ -f "$B/whats_next.md" ] || fail "a declined run touched a candidate file"
find "$B/docs/issues" -name '*.md' 2>/dev/null | grep -q . && fail "a declined run created issues"
outB2="$( cd "$B" && LOOP_ASSUME_NO=1 "$SETUP" </dev/null 2>/dev/null )" \
  || fail "post-decline re-run exited non-zero"
printf '%s\n' "$outB2" | grep -q 'found 2 import candidate' \
  || fail "declined-and-left candidates were not re-offered on the next run (nothing may suppress them)"

# ---------- the archive move never overwrites: same-basename candidates collide safely ----------
K="$(mktemp -d)"; trap 'rm -rf "$A" "$B" "$K"' EXIT
mkdir -p "$K/docs/a" "$K/docs/b"
( cd "$K" && git init -q )
printf '# First todo\nLabel: idea\none\n'  > "$K/docs/a/dup-todo.md"
printf '# Second todo\nLabel: idea\ntwo\n' > "$K/docs/b/dup-todo.md"
outK="$( cd "$K" && LOOP_TRACKER_ANSWER=local LOOP_ASSUME_YES=1 "$SETUP" </dev/null 2>/dev/null )" \
  || fail "collision run exited non-zero"
[ "$(ls "$K/docs/issues"/*.md 2>/dev/null | wc -l)" -eq 2 ] || fail "collision run did not import both candidates"
[ -f "$K/docs/archive/dup-todo.md" ] || fail "no candidate reached the archive"
[ -f "$K/docs/a/dup-todo.md" ] || [ -f "$K/docs/b/dup-todo.md" ] \
  || fail "BOTH same-basename candidates were moved onto one archive path - the first was silently destroyed"
printf '%s\n' "$outK" | grep -qi 'skip' || fail "the skipped collision move did not say so"

# ---------- an out-of-tree --scan candidate is imported but NEVER archived into this repo ----------
# tests/loop-setup/import.sh already runs `--scan "$(mktemp -d)"` under LOOP_ASSUME_YES, so
# without this guard the existing suite's first post-Task-4 run would move a file out of an
# unrelated directory and stay green.
L="$(mktemp -d)"; XT="$(mktemp -d)"; trap 'rm -rf "$A" "$B" "$K" "$L" "$XT"' EXIT
( cd "$L" && git init -q )
printf '# Extra todo\nLabel: idea\nelsewhere\n' > "$XT/extra-todo.md"
outL="$( cd "$L" && LOOP_TRACKER_ANSWER=local LOOP_ASSUME_YES=1 "$SETUP" --scan "$XT" </dev/null 2>/dev/null )" \
  || fail "out-of-tree scan run exited non-zero"
printf '%s\n' "$outL" | grep -q 'found 1 import candidate' || fail "the --scan candidate was not found"
[ "$(ls "$L/docs/issues"/*.md 2>/dev/null | wc -l)" -eq 1 ] || fail "the --scan candidate was not imported"
[ -f "$XT/extra-todo.md" ] \
  || fail "an out-of-tree candidate was moved out of its directory (no archive offer may reach outside the repo)"
find "$L/docs/archive" -name 'extra-todo.md' 2>/dev/null | grep -q . \
  && fail "an out-of-tree candidate landed in this repo's archive"

# ---------- criterion 7: the sweep also runs in github mode ----------
D="$(mktemp -d)"; FIX="$REPO/tests/repo-state/fixtures/issues.json"
trap 'rm -rf "$A" "$B" "$K" "$L" "$XT" "$D"' EXIT
mk "$D"
( cd "$D" && git remote add origin https://github.com/acme/x.git )
out6="$( cd "$D" && LOOP_TRACKER_ANSWER=github MIRRORS_JSON_FILE="$FIX" LOOP_ASSUME_NO=1 \
         "$SETUP" --dry-run-remote </dev/null 2>/dev/null )" || fail "github sweep run exited non-zero"
printf '%s\n' "$out6" | grep -q 'found 2 import candidate' \
  || fail "the sweep did not run in github mode (criterion 7)"

# ---------- criterion 7: gitlab mode, and the remote-creation safety gate ----------
BIN="$(mktemp -d)"; E="$(mktemp -d)"
trap 'rm -rf "$A" "$B" "$K" "$L" "$XT" "$D" "$BIN" "$E"' EXIT
GLOG="$BIN/glab.calls"
cat > "$BIN/glab" <<'STUB'
#!/usr/bin/env bash
echo "GLAB CALLED: $*" >> "$GLAB_LOG"
if [ "$1" = auth ] && [ "$2" = status ]; then
  for a in "$@"; do [ "$a" = --hostname ] && exit 0; done
  exit 1
fi
if [ "$1" = issue ] && [ "$2" = list ]; then exit 0; fi
if [ "$1" = issue ] && [ "$2" = create ]; then
  [ "${GLAB_CREATE_FAIL:-0}" = 1 ] && { echo "ERROR 403" >&2; exit 1; }
  n=$(( $(cat "$GLAB_N" 2>/dev/null || echo 200) + 1 )); echo "$n" > "$GLAB_N"
  echo "https://gitlab.example.com/grp/repo/-/issues/$n"; exit 0
fi
if [ "$1" = label ] && [ "$2" = list ]; then echo "[]"; exit 0; fi
exit 0
STUB
chmod +x "$BIN/glab"
export GLAB_LOG="$GLOG" GLAB_N="$BIN/n"
mk "$E"
( cd "$E" && git remote add origin 'ssh://git@gitlab.example.com:2222/grp/repo.git' )

# SAFETY FIRST: LOOP_ASSUME_YES alone must NOT create issues on a remote instance.
out7="$( cd "$E" && PATH="$BIN:$PATH" LOOP_TRACKER_ANSWER=gitlab LOOP_ASSUME_YES=1 \
         "$SETUP" </dev/null 2>&1 )" || fail "gitlab sweep run exited non-zero"
printf '%s\n' "$out7" | grep -q 'found 2 import candidate' \
  || fail "the sweep did not run in gitlab mode (criterion 7)"
printf '%s\n' "$out7" | grep -q 'set LOOP_IMPORT_REMOTE=1' \
  || fail "unattended remote import was neither performed nor explained"
grep -q 'GLAB CALLED: issue create' "$GLOG" \
  && fail "LOOP_ASSUME_YES alone created remote issues without LOOP_IMPORT_REMOTE"
[ -f "$E/whats_next.md" ] \
  || fail "a skipped remote import still archived or removed the candidate (nothing was imported)"

# --dry-run-remote keeps its promise even with every unattended gate open: nothing is created.
# Without a DRY_REMOTE term in the sweep's gate, this exact invocation would file real issues.
: > "$GLOG"
outDR="$( cd "$E" && PATH="$BIN:$PATH" MIRRORS_JSON_FILE="$FIX" LOOP_ASSUME_YES=1 LOOP_IMPORT_REMOTE=1 \
          "$SETUP" --dry-run-remote </dev/null 2>&1 )" || fail "dry-run gitlab sweep exited non-zero"
grep -q 'GLAB CALLED: issue create' "$GLOG" \
  && fail "--dry-run-remote created remote issues (the flag promises no remote calls)"
printf '%s\n' "$outDR" | grep -q 'skipping remote import of' \
  || fail "the dry-run remote-import skip was silent (the finalize's own dry-run line does not count)"
[ -f "$E/whats_next.md" ] || fail "a dry-run archived a candidate whose issue was never created"

# With the explicit opt-in, the sweep creates through the glab backend and archives the sources.
: > "$GLOG"
out8="$( cd "$E" && PATH="$BIN:$PATH" LOOP_ASSUME_YES=1 LOOP_IMPORT_REMOTE=1 \
         "$SETUP" </dev/null 2>&1 )" || fail "opted-in gitlab sweep exited non-zero"
[ "$(grep -c 'GLAB CALLED: issue create' "$GLOG")" -eq 2 ] \
  || fail "the opted-in sweep did not create exactly two remote issues"
[ -f "$E/docs/archive/whats_next.md" ] || fail "the opted-in sweep did not archive the imported candidate"
find "$E/docs/issues" -name '*.md' 2>/dev/null | grep -q . \
  && fail "gitlab mode wrote local issue files instead of creating remote issues"

# ---------- the remote gate keys on the unattended variable, never on MODE ----------
# Interactive per-item answers create remote issues with no extra variable; a gate that keyed
# on MODE being remote would break exactly the interactive path Task 7 Steps 2 and 3 rely on.
M="$(mktemp -d)"; trap 'rm -rf "$A" "$B" "$K" "$L" "$XT" "$D" "$BIN" "$E" "$M"' EXIT
mk "$M"
( cd "$M" && git remote add origin 'ssh://git@gitlab.example.com:2222/grp/repo.git' )
: > "$GLOG"
outM="$( cd "$M" && printf 'y\ny\ny\ny\ny\ny\ny\ny\ny\ny\ny\ny\n' | \
         PATH="$BIN:$PATH" LOOP_TRACKER_ANSWER=gitlab "$SETUP" 2>&1 )" \
  || fail "interactive gitlab sweep exited non-zero"
[ "$(grep -c 'GLAB CALLED: issue create' "$GLOG")" -eq 2 ] \
  || fail "interactive per-item yes did not create both remote issues (the gate must key on LOOP_ASSUME_YES, not MODE)"
printf '%s\n' "$outM" | grep -q 'set LOOP_IMPORT_REMOTE=1' \
  && fail "an interactive run was told to set LOOP_IMPORT_REMOTE (the variable gates unattended runs only)"

# ---------- a failed create is never treated as imported: no archive, no "imported" line ----------
# On a shared instance a create can fail partway (label, permission, rate); archiving a file
# whose issue does not exist would lose the only copy of the work item.
N="$(mktemp -d)"; trap 'rm -rf "$A" "$B" "$K" "$L" "$XT" "$D" "$BIN" "$E" "$M" "$N"' EXIT
mk "$N"
( cd "$N" && git remote add origin 'ssh://git@gitlab.example.com:2222/grp/repo.git' )
: > "$GLOG"
outN="$( cd "$N" && PATH="$BIN:$PATH" GLAB_CREATE_FAIL=1 LOOP_TRACKER_ANSWER=gitlab \
         LOOP_ASSUME_YES=1 LOOP_IMPORT_REMOTE=1 "$SETUP" </dev/null 2>&1 )" \
  || fail "a run with failing creates aborted instead of skipping and continuing"
printf '%s\n' "$outN" | grep -q 'create failed' || fail "a failed create was not reported"
printf '%s\n' "$outN" | grep -q 'imported '     && fail "a failed create was announced as imported"
[ -f "$N/whats_next.md" ] || fail "a candidate whose create failed was archived or removed"
find "$N/docs/archive" -name '*.md' 2>/dev/null | grep -q . \
  && fail "a failed create still produced an archive move"

echo "PASS: loop-setup universal sweep"
```

- [ ] **Step 2: Run it.**
      `bash tests/loop-setup/idempotence.sh`
      Expect FAIL with `sweep did not announce its candidate count`, because today's `reconcile_import` prints no count line, is gated to local mode, and never scans the repo root.

- [ ] **Step 3: Implement.**
      Edit `skills/loop-setup/setup.sh` only (plus `tests/loop-setup/import.sh`, per step d).

  a. Rework `reconcile_import` into the universal sweep.
     - Add the repo root as a non-recursive root: collect `*.md` at depth 1 via a separate `find . -maxdepth 1 -type f -name '*.md'` pass, merged with the existing recursive `find` over the other roots.
       **The root pass runs unconditionally; the guard structure must change to allow that.**
       `setup.sh:178`'s `[ "${#roots[@]}" -gt 0 ] || return 0` exists because `find` with an empty array silently expands to `find .` and scans the whole tree (confirmed by running it during review).
       In practice `roots` is never empty here - `setup.sh:49` creates `docs/` unconditionally before the sweep runs - so the restructure is defensive, but the shape still matters: an implementer who merges the root pass into the same guarded `find` reintroduces the full-tree hazard the guard exists to prevent.
       Keep the recursive pass strictly inside the `[ "${#roots[@]}" -gt 0 ]` test, run the root pass first regardless, and return early only when the merged candidate list is empty.
       The `${roots[@]+"${roots[@]}"}` expansion idiom at `setup.sh:177` is **not** a substitute for the guard on a `find` call: with an empty array it passes `find` no path operand at all, which is the full-tree scan again (confirmed by running it).
     - **Normalize every path with `f="${f#./}"` before `is_excluded` and the offer.**
       The root pass yields `./whats_next.md` while the recursive pass yields `docs/some-todo.md`; the offer lines and archive moves should show one consistent repo-relative spelling.
     - Extend `is_excluded` twice.
       First, add `docs/plans/*` to the existing prefix case (alongside `docs/briefs/*`, which is already there): plan documents are a governed lane, and `config/repo-state.md`'s Archive-and-graduation rules own plan and brief archival ("a brief archives when its plan archives; they travel together"), so the sweep offering to archive a live plan would be reaching into a lane it does not own.
       Without this line, every `docs/plans/*` file in this repo - including this plan - is offered for import and archival on the first ungated run.
       Second, exclude these root project names, matched against the **normalized path** so only depth-1 files are excluded (a normalized depth-1 path contains no `/`; matching on `basename` would silently hide `docs/notes/PLAN.md` and any nested `README.md`, which is wider than intended):
       `README.md`, `CLAUDE.md`, `AGENTS.md`, `PLAN.md`, `CHANGELOG.md`, `LICENSE.md`, `CONTRIBUTING.md`.
       The list is deliberately wider than this repo's own root `ls`: `setup.sh` is vendored into other repos where all seven exist.
       Measured in this repo, the un-excluded count would be 9 (7 plan-lane files, `PLAN.md`, `fixing-agent-errors.md`); with both exclusions the steady state is exactly 1.
       `fixing-agent-errors.md` is deliberately still offered: it is a repo-specific document, not a conventional project file, and declining it is one keystroke.
     - Build the candidate list first.
       When it is empty, return without printing anything; the end-of-run summary is what says "nothing to do".
     - Otherwise print `found N import candidate(s)` to **stdout**, then ask the single gate question `review them?` through the existing `ask`.
       The count line is separate from the prompt on purpose: `ask()` returns without printing when `LOOP_ASSUME_YES`/`LOOP_ASSUME_NO` is set, so the count is the trace that survives non-interactive runs, and the tests key on it.
       A declined gate returns without recording anything anywhere, so the same candidates are announced again next run - re-offering is the contract, and durability comes from archiving, not from remembering declines.
     - For each candidate, print the existing `import candidate: <path> (title: <title>, label: <label>)` line and ask per item, exactly as today.
     - **The per-item confirmation is not satisfied by `LOOP_ASSUME_YES` alone when `MODE` is `github` or `gitlab`.**
       Until now the worst an unattended sweep could do was write local markdown; ungating it means a single blanket yes files an issue per candidate on a shared corporate instance, which in forge is the `university-advancement` group.
       The skip condition, stated literally so no reading keys it on `MODE` alone:
       ```bash
       # remote creation is skipped for this candidate when MODE is github or gitlab AND:
       [ "$DRY_REMOTE" -eq 1 ] || { [ "${LOOP_ASSUME_YES:-0}" = 1 ] && [ "${LOOP_IMPORT_REMOTE:-0}" != 1 ]; }
       ```
       The second term keys on the unattended-yes variable, never on the mode: an interactive per-item `y` in gitlab mode creates the issue with no extra variable, because `ask()` at `setup.sh:8-13` returns 0 for both a blanket yes and an interactive `y`, and only the blanket form carries the escalation this gate exists for.
       The first term is `--dry-run-remote` keeping its documented promise (`SKILL.md:50`: no remote calls); without it, `--dry-run-remote LOOP_ASSUME_YES=1 LOOP_IMPORT_REMOTE=1` would file real issues.
       On a skip, print **to stdout** `skipping remote import of <path> (set LOOP_IMPORT_REMOTE=1 to allow unattended remote creation)` under the unattended gate, or `dry-run-remote: skipping remote import of <path>` under dry-run; skip that file's archive offer too (nothing was imported), and the candidate is offered again next run.
       The dry-run string must contain `skipping remote import of` verbatim - the finalize already prints a different `dry-run-remote:` line on every dry run, so the test greps for the sweep-specific text.
       Local mode ignores the gate entirely.
     - On accept, guard the create - the code being replaced has `&& echo "imported $f"` and the rewrite must not lose the guard:
       ```bash
       num="$(scripts/tracker.sh create --label "$label" --title "$title" --body "$body")" \
         || { echo "create failed for $f; skipping" >&2; continue; }
       [ -n "$num" ] || { echo "create returned no issue number for $f; skipping" >&2; continue; }
       echo "imported $f as issue #$num"
       ```
       Treating a failed create as imported would archive a file whose issue does not exist; on a shared instance a create can fail for label, permission, or rate reasons partway through a multi-candidate sweep.
     - After a successful create, ask `move <path> to docs/archive/?`; on accept `mkdir -p docs/archive`, then `git mv` when the file is tracked else `mv`, and announce the move.
       The archive move is the idempotence mechanism: `is_excluded` already skips `docs/archive/*`, so an archived candidate never re-offers, with zero bookkeeping.
       A declined move leaves the file in place, and it will be offered again next run - by design, per the user's direction that a live loose end is worth speaking up about.
       **Two guards on the move, both load-bearing:**
       - Never offer the move for a candidate whose normalized path is absolute or starts with `../` - which is every `--scan` root outside the repo.
         `setup.sh:33` accepts `--scan <dir>` with no in-tree requirement, and `tests/loop-setup/import.sh:68` already runs `--scan "$(mktemp -d)"` under `LOOP_ASSUME_YES=1`, so without this guard the existing suite's first post-Task-4 run moves a file out of an unrelated directory into the sandbox repo and stays green.
         An out-of-tree candidate is imported normally; it just keeps its home, and re-offers next run like any declined move.
       - Never overwrite: when `docs/archive/<basename>` already exists, skip the move, say so **on stdout** (`skipping archive move: docs/archive/<name> already exists; left at <path>`), and leave the file in place.
         Two candidates sharing a basename would otherwise collapse onto one destination and the first would be destroyed with no message.
         Stdout matters: the test captures stdout only, and the create-failure message four lines up goes to stderr - an implementer following that neighboring convention would fail scenario K on a correct guard.
       Announce the move only when the `git mv`/`mv` actually succeeded; on failure print `archive move failed for <path>; left in place` to stdout and continue.
       A false "moved" line in the mechanism the idempotence model rests on is worse than no move at all.
     - After the per-item loop, when at least one candidate was imported, re-run `scripts/gen-mirrors.sh . || fail "gen-mirrors.sh failed"` once.
       The finalize renders mirrors at `setup.sh:235-238` and `reconcile_import` runs after them at `:240`, so a sweep that just filed issues would otherwise end by printing completion over mirrors that lack every one of them - and only the local backend even mentions staleness (`scripts/tracker.sh:73`); the remote create paths say nothing.
     - Keep the frontmatter-versus-prose title and label extraction unchanged.
     - The create call is backend-agnostic because it routes through `scripts/tracker.sh`, so the sweep needs no per-mode branch of its own beyond the `LOOP_IMPORT_REMOTE` gate.

  b. Remove the `[ "$MODE" = local ]` gate at line 240 so `reconcile_import` runs in every mode.

  c. Replace the final `echo "loop-setup complete"` with a summary, tracked by a counter incremented by **every** offer source: `reconcile_config`, the sweep, the per-file drift-refresh loop at `setup.sh:75-87`, and the `$TIDY` byproduct pass at `setup.sh:241` (`scripts/tidy.sh:16-22` prints `byproduct:` per item and asks).
     `$TIDY` is a child process whose offers `setup.sh` cannot otherwise observe (tidy always exits 0), so capture and re-emit:
     ```bash
     t="$("$TIDY")" || true
     [ -n "$t" ] && printf '%s\n' "$t"
     printf '%s' "$t" | grep -q '^byproduct:' && offers=$((offers + 1))
     ```
     Re-emitting keeps `tests/loop-setup/tidy.sh`'s byproduct-lines-on-stdout assertion true, and the interactive ordering stays usable because tidy's per-item prompt names the file (`delete <f>?`, on stderr).
     When the counter is zero, print `loop-setup complete - nothing to do`.
     The line exists so quiet is a statement rather than an absence: the brief bought exactly one line here ("finds nothing to do and **says so**"), so it is the one line that must never be false - a run that asked four drift-refresh questions and then claimed nothing to do would be worse than the current silence.

  d. Update `tests/loop-setup/import.sh` - it is **not** unaffected, in one load-bearing way.
     The suite's `docs/plans/big-plan.md` fixture (`import.sh:29-33`, content `MARKER_PLAN`) now sits in the excluded plan lane, so move `MARKER_PLAN` from the imported-candidates loop at `import.sh:72` to the excluded-content loop at `import.sh:88`, and note at the fixture that the plan lane is exercised as an exclusion.
     Without that move, this task's own `tests/run.sh` gate fails on this suite.
     Its `LOOP_ASSUME_YES=1` scenarios accept the new gate the same way they accept every other question; its decline-all scenario now declines at the gate instead of per item, which still satisfies its "nothing imported" assertions.
     If any assertion expects per-item `import candidate:` lines under `LOOP_ASSUME_NO=1`, retarget it at the `found N import candidate(s)` line, which is what a declined-gate run prints.
     Update the header comment to say the sweep runs in all three modes.
     Accept-all scenarios must also answer the new archive offers, which `LOOP_ASSUME_YES=1` does; where a scenario then asserts a candidate file still exists at its original path, change it to assert the file now lives under `docs/archive/` - with one exception: `$EXTRA/extra-plan.md`, the out-of-tree `--scan` candidate, must be asserted to **survive at its original path** (add that assertion; the suite currently never checks it), because out-of-tree candidates are imported but never archived.

- [ ] **Step 4: Run it.**
      `bash tests/loop-setup/idempotence.sh` - expect PASS.
      Then `bash tests/run.sh` - expect `0 failed`; this task edits the shared `setup.sh` and `tests/loop-setup/import.sh`, so the full suite is part of the gate, not a courtesy.
      `tests/loop-setup/reconcile.sh` is untouched and must still pass unmodified.

- [ ] **Step 5: Commit.**
      ```bash
      git add skills/loop-setup/setup.sh tests/loop-setup/idempotence.sh tests/loop-setup/import.sh
      git commit -m "loop-setup: universal import sweep - all modes, root scan, archive-on-import idempotence"
      ```

---

### Task 5: `migrate-tracker.sh` gitlab target, vendored by setup

Depends on: Task 4

**Files (exclusive ownership):**

- Modify: `scripts/migrate-tracker.sh`
- Modify: `skills/loop-setup/setup.sh` (vendor `migrate-tracker.sh`: the skip-if-exists copy and a drift-refresh entry, nothing else)
- Test: `tests/repo-state/migrate-gitlab.sh` (create)

An earlier draft also had `setup.sh` *offer* the migration interactively.
That was cut at the bloat review: the offer needed an `env -u` dance around a nested destructive prompt, a `DRY_REMOTE` interaction, and a ledger record - three review findings' worth of machinery for a command one `SKILL.md` line can name.
Task 6 puts that line in `SKILL.md`: the agent running loop-setup suggests the command when local issues and a remote coexist, and the user fires it.
Note the end artifact never needed the offer anyway: forge has zero files in `docs/issues/`.

**Interfaces:**

Consumes, from Task 1: `scripts/tracker.sh mode set gitlab`, `scripts/tracker.sh host`.

Produces:

- `scripts/migrate-tracker.sh [--to github|gitlab]`, defaulting to `github` so every existing invocation behaves identically.
- The script vendored into every repo loop-setup touches, so the `SKILL.md` suggestion names a path that exists.

**Acceptance check:** `bash tests/repo-state/migrate-gitlab.sh && bash tests/run.sh` exits 0 `[executed-check]`
The full-suite half is load-bearing: this task edits the shared `setup.sh`, so the new suite alone cannot gate what the task can break.

- [ ] **Step 1: Write the failing test.**
      Create `tests/repo-state/migrate-gitlab.sh` with exactly this content:

```bash
#!/usr/bin/env bash
# migrate-tracker.sh --to gitlab: labels first, one issue per local file, closed issues re-closed,
# frontmatter stamped, mode flipped to gitlab. Dry run prints glab commands and touches nothing.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
M="$REPO/scripts/migrate-tracker.sh"
TRK="$REPO/scripts/tracker.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$M" ] || fail "scripts/migrate-tracker.sh missing"

BIN="$(mktemp -d)"; SB="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB"' EXIT
LOG="$BIN/glab.calls"
cat > "$BIN/glab" <<EOF
#!/usr/bin/env bash
echo "GLAB CALLED: \$*" >> "$LOG"
if [ "\$1" = auth ] && [ "\$2" = status ]; then
  for a in "\$@"; do [ "\$a" = --hostname ] && exit 0; done
  exit 1
fi
if [ "\$1" = issue ] && [ "\$2" = create ]; then
  n=\$(( \$(cat "$BIN/n" 2>/dev/null || echo 100) + 1 )); echo "\$n" > "$BIN/n"
  echo "https://gitlab.example.com/grp/repo/-/issues/\$n"
  exit 0
fi
exit 0
EOF
chmod +x "$BIN/glab"
# gh stub: the default-target dry run below must not depend on this host's real gh auth state
cat > "$BIN/gh" <<'STUB'
#!/usr/bin/env bash
[ "$1" = auth ] && exit 0
if [ "$1" = issue ] && [ "$2" = create ]; then echo "https://github.com/acme/x/issues/9"; exit 0; fi
exit 0
STUB
chmod +x "$BIN/gh"
export PATH="$BIN:$PATH"

mkdir -p "$SB/scripts" "$SB/config" "$SB/docs/issues"
cp "$TRK" "$SB/scripts/tracker.sh"; chmod +x "$SB/scripts/tracker.sh"
( cd "$SB" && git init -q && git remote add origin 'ssh://git@gitlab.example.com:2222/grp/repo.git' )
printf 'tracker: local\n' > "$SB/config/repo-state.md"

cat > "$SB/docs/issues/001-open-one.md" <<'EOS'
---
number: 1
title: an open item
labels: idea
state: open
updated: 2026-08-01T00:00:00Z
---
body one
EOS
cat > "$SB/docs/issues/002-closed-one.md" <<'EOS'
---
number: 2
title: a closed item
labels:
state: closed
updated: 2026-08-01T00:00:00Z
---
body two
EOS

# --- dry run prints glab commands and changes nothing ---
before="$(cat "$SB/docs/issues/001-open-one.md")"
out="$( cd "$SB" && MIGRATE_DRY_RUN=1 "$M" --to gitlab )" || fail "dry run exited non-zero"
printf '%s\n' "$out" | grep -q 'glab issue create' || fail "dry run did not print glab issue create"
printf '%s\n' "$out" | grep -q 'gh issue create'   && fail "dry run printed gh commands for a gitlab target"
printf '%s\n' "$out" | grep -q 'glab label create' || fail "dry run did not print glab label create"
[ "$before" = "$(cat "$SB/docs/issues/001-open-one.md")" ] || fail "dry run modified a local issue file"
[ "$(grep '^tracker:' "$SB/config/repo-state.md")" = "tracker: local" ] || fail "dry run flipped the mode"

# --- the default target is still github, asserted POSITIVELY while the files are unstamped ---
# `|| true` with only a negative grep would pass vacuously if --to became mandatory (a usage
# error contains no glab line either); this must run BEFORE the real run stamps every file.
out2="$( cd "$SB" && MIGRATE_DRY_RUN=1 "$M" )" || fail "default-target dry run exited non-zero"
printf '%s\n' "$out2" | grep -q 'gh issue create'   || fail "the default github dry run printed no gh issue create"
printf '%s\n' "$out2" | grep -q 'glab issue create' && fail "the default target became gitlab"

# --- real run ---
( cd "$SB" && LOOP_ASSUME_NO=1 "$M" --to gitlab >/dev/null 2>&1 ) || fail "real run exited non-zero"
grep -q 'GLAB CALLED: auth status --hostname gitlab.example.com' "$LOG" \
  || fail "migration did not run a --hostname-scoped auth status"
grep -E 'GLAB CALLED: auth status$' "$LOG" && fail "migration ran a BARE glab auth status"
grep -q 'GLAB CALLED: label create --name idea' "$LOG" || fail "migration did not pre-create the idea label"
[ "$(grep -c 'GLAB CALLED: issue create' "$LOG")" -eq 2 ] || fail "migration did not create exactly two issues"
grep -q 'GLAB CALLED: issue close' "$LOG" || fail "migration did not re-close the locally-closed issue"
grep -q '^migrated: https://gitlab.example.com' "$SB/docs/issues/001-open-one.md" \
  || fail "migrated file was not stamped with its new URL"
grep -q '^state: migrated' "$SB/docs/issues/001-open-one.md" || fail "migrated file state was not frozen"
[ "$(grep '^tracker:' "$SB/config/repo-state.md")" = "tracker: gitlab" ] || fail "mode was not flipped to gitlab"

# --- a second real run is a no-op: every file is already stamped ---
: > "$LOG"
( cd "$SB" && LOOP_ASSUME_NO=1 "$M" --to gitlab >/dev/null 2>&1 ) || fail "re-run exited non-zero"
grep -q 'GLAB CALLED: issue create' "$LOG" && fail "re-run re-created an already-migrated issue"

# --- an unknown target is rejected ---
( cd "$SB" && MIGRATE_DRY_RUN=1 "$M" --to bitbucket >/dev/null 2>&1 ) && fail "an unknown target was accepted"

# --- a real run on UNTRACKED issue files still exits 0 (the git rm exit-status fix) ---
# The files in $SB were never `git add`ed, so the end-of-run `git rm --cached` cannot succeed;
# a successful migration must not inherit that failure as its exit status.
V="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB" "$V"' EXIT
mkdir -p "$V/scripts" "$V/config" "$V/docs/issues"
cp "$TRK" "$V/scripts/tracker.sh"; chmod +x "$V/scripts/tracker.sh"
( cd "$V" && git init -q && git remote add origin 'ssh://git@gitlab.example.com:2222/grp/repo.git' )
printf 'tracker: local\n' > "$V/config/repo-state.md"
cp "$SB/docs/issues/001-open-one.md" "$V/docs/issues/001-open-one.md"
sed -i.bak '/^migrated:/d; s/^state: migrated/state: open/' "$V/docs/issues/001-open-one.md"
rm -f "$V/docs/issues/001-open-one.md.bak"
( cd "$V" && LOOP_ASSUME_YES=1 "$M" --to gitlab >/dev/null 2>&1 ) \
  || fail "a successful migration reported failure because git rm --cached hit untracked files"
[ -f "$V/docs/issues/001-open-one.md" ] || fail "the frozen audit file was removed from disk"

# --- setup.sh vendors migrate-tracker.sh, so the SKILL.md suggestion names a real path ---
SETUP="$REPO/skills/loop-setup/setup.sh"
W="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB" "$V" "$W"' EXIT
( cd "$W" && git init -q )
( cd "$W" && LOOP_TRACKER_ANSWER=local LOOP_ASSUME_NO=1 "$SETUP" </dev/null >/dev/null 2>&1 ) \
  || fail "vendoring setup run exited non-zero"
[ -x "$W/scripts/migrate-tracker.sh" ] \
  || fail "setup.sh did not vendor migrate-tracker.sh (the documented command would be a dangling path)"

echo "PASS: migrate-tracker gitlab target"
```

- [ ] **Step 2: Run it.**
      `bash tests/repo-state/migrate-gitlab.sh`
      Expect FAIL with `dry run did not print glab issue create`, because `migrate-tracker.sh` accepts no arguments and hardcodes `gh`.

- [ ] **Step 3: Implement.**

  a. In `scripts/migrate-tracker.sh`, parse a single optional flag `--to <github|gitlab>` into `TARGET`, defaulting to `github`; reject anything else with `fail "--to: must be 'github' or 'gitlab' (got '<v>')"`.
     Reject unknown arguments the same way.

  b. Replace the auth fail-fast with a per-target branch.
     For `github`, keep the existing `gh auth status` check verbatim.
     For `gitlab`, resolve the host via `scripts/tracker.sh host` and run `glab auth status --hostname "$host"`, failing with `"migration to gitlab requires glab authenticated to $host (run: glab auth login --hostname $host)"`.

  c. Replace the three `gh` call sites with target-aware ones, keeping the existing dry-run/real split and the existing ordering guarantees (labels first, stamp before close, resume-safe skip on `migrated:`):
     - label pre-create: `gh label create "$lbl"` or `glab label create --name "$lbl"`
     - issue create: `gh issue create --title T [--label L] --body B` or `glab issue create --yes --no-editor -t T [-l L] -d B`
     - close: `gh issue close "$new"` or `glab issue close "$new"`
     For gitlab, derive `new` by the same `/issues/<n>` grep Task 1 uses, not by `${url##*/}`.

  d. Change the final `scripts/tracker.sh mode set github` to `mode set "$TARGET"`, and its echo to `flipped tracker: $TARGET`.

  d2. End the script with an explicit `exit 0` after the `git rm` block.
     Today the last statement is `git rm -qf --cached "${mig[@]}"`, so on a repo where the migrated files were never `git add`ed, `git rm --cached` exits 128 and that becomes the script's exit status even though the migration fully succeeded.
     The script runs `set -uo pipefail` without `-e`, so this is a misreported status rather than an abort, which is worse: callers see failure after a successful migration.
     Guard the call as well, so a failure to stage the deletion is reported but not fatal:
     ```bash
     git rm -qf --cached "${mig[@]}" 2>/dev/null \
       && echo "staged git rm of ${#mig[@]} migrated ledger file(s)" \
       || echo "could not stage git rm (files may be untracked); left on disk"
     ```

  e. Update the header comment to name both targets and the `--to` flag.

  f. Add `migrate-tracker.sh` to the scripts `setup.sh` vendors into the target repo.
     `setup.sh` currently copies and drift-refreshes only `gen-mirrors.sh`, `tracker.sh`, and `graduate-parking.sh` (lines 51-87), so the `scripts/migrate-tracker.sh` command Task 6 documents would resolve to a path that does not exist in any repo loop-setup has set up.
     Add a `MIG="$REPO/scripts/migrate-tracker.sh"` resolution with the same `[ -x ]` check, the same skip-if-exists copy, and a fourth entry `"migrate-tracker.sh:$MIG"` in the drift-refresh `for pair` loop.
     This is the only `setup.sh` change in this task; `setup.sh` never invokes the migration itself - suggesting it is `SKILL.md` prose (Task 6), and firing it is the user's.

- [ ] **Step 4: Run it.**
      `bash tests/repo-state/migrate-gitlab.sh` - expect PASS.
      Then `bash tests/run.sh` - expect `0 failed`; this task edits the shared `setup.sh`, so the full suite is part of the gate, not a courtesy.

- [ ] **Step 5: Commit.**
      ```bash
      git add scripts/migrate-tracker.sh skills/loop-setup/setup.sh tests/repo-state/migrate-gitlab.sh
      git commit -m "migrate-tracker: --to gitlab target, vendored into target repos by loop-setup"
      ```

---

### Task 6: Doc and skill sweep

Depends on: Task 4, Task 5

**Files (exclusive ownership):**

- Modify: `skills/loop-setup/SKILL.md`
- Create: `skills/loop-setup/references/import-triage.md`
- Modify: `skills/wayfinder/SKILL.md:15` and its GitHub-issue prose
- Modify: `skills/loop-improve/SKILL.md:60-61`
- Modify: `skills/loop-review/SKILL.md:40`
- Modify: `config/repo-state.md` (this repo's own config: backfill to template-version 2, widen github-only prose)
- Test: `tests/loop-setup/docs-gitlab.sh` (create)

`config/repo-state.template.md` is not touched here; Task 3 owns it, and no lane row is added anywhere because there is no state file to declare.

**Interfaces:**

Consumes: the finished behavior of Tasks 1 through 5.
Produces: no code surface; this task exists so the documentation stops asserting github-only behavior that is no longer true.

**Acceptance check:** `bash tests/loop-setup/docs-gitlab.sh` exits 0 `[executed-check]`

- [ ] **Step 1: Write the failing test.**
      Create `tests/loop-setup/docs-gitlab.sh` with exactly this content:

```bash
#!/usr/bin/env bash
# The docs no longer assert github-only behavior, the triage reference exists and is pointed at,
# and this repo's own config is at the current template-version.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }

SK="$REPO/skills/loop-setup/SKILL.md"
REF="$REPO/skills/loop-setup/references/import-triage.md"
WF="$REPO/skills/wayfinder/SKILL.md"
IMP="$REPO/skills/loop-improve/SKILL.md"
REV="$REPO/skills/loop-review/SKILL.md"
CFG="$REPO/config/repo-state.md"
TPL="$REPO/config/repo-state.template.md"

# criterion 11: wayfinder no longer states a github-only requirement
grep -q 'Wayfinder requires `tracker: github`' "$WF" \
  && fail "wayfinder still states a github-only tracker requirement (criterion 11)"
grep -qi 'gitlab' "$WF" || fail "wayfinder does not mention gitlab at all"
grep -q 'wayfinder:map' "$WF" || fail "wayfinder lost its map label name"

# the template's local-mode limitation matches
grep -q 'wayfinder requires `tracker: github`' "$TPL" \
  && fail "the template still states wayfinder is github-only"

# the SAME assertions against this repo's own config - it is the file agents actually read,
# and asserting only against the template would pass while the config stayed wrong
grep -q 'wayfinder requires `tracker: github`' "$CFG" \
  && fail "config/repo-state.md still states wayfinder is github-only"
grep -q 'Migration to GitHub' "$CFG" \
  && fail "config/repo-state.md still describes migration as GitHub-only"
grep -qi 'gitlab' "$CFG" || fail "config/repo-state.md never mentions gitlab"

# the second github-only assertion (the numbering limitation) is widened in both files
grep -q 'shared or branched work should use `tracker: github`' "$CFG" \
  && fail "config/repo-state.md still tells shared work to use github only"
grep -q 'shared or branched work should use `tracker: github`' "$TPL" \
  && fail "the template still tells shared work to use github only"

# the config round-trips the v2 template: the autonomy-default prose survives a render
grep -q 'autonomy-default' "$TPL" \
  || fail "the template lacks the autonomy-default paragraph (a v2 re-render would silently drop it from the config)"
grep -q 'autonomy-default' "$CFG" || fail "config/repo-state.md lost its autonomy-default paragraph"

# the sweep's root exclusions are declared where the config claims to be the definitive list
grep -q 'CONTRIBUTING.md' "$TPL" || fail "the template does not declare the sweep's root exclusions"
grep -q 'CONTRIBUTING.md' "$CFG" || fail "config/repo-state.md does not declare the sweep's root exclusions"

# loop-setup SKILL.md documents all three modes and points at the triage reference
for w in github gitlab local; do
  grep -q "$w" "$SK" || fail "loop-setup SKILL.md does not mention $w"
done
grep -q 'references/import-triage.md' "$SK" || fail "SKILL.md does not point at the triage reference"
grep -q 'LOOP_IMPORT_REMOTE' "$SK" \
  || fail "SKILL.md does not document the LOOP_IMPORT_REMOTE guard on unattended remote creation"
grep -q 'LOOP_TRACKER_ANSWER=gitlab' "$SK" || fail "SKILL.md does not document the gitlab non-interactive answer"
grep -qi 'but the remote is' "$SK" || fail "SKILL.md does not document the mode-switch offer"
grep -q 'migrate-tracker.sh --to' "$SK" \
  || fail "SKILL.md does not tell the agent when to suggest the standalone migration (criterion 10)"
grep -q 'tracker-remote-ack' "$SK" \
  || fail "SKILL.md does not document the tracker-remote-ack off switch for the mode-switch offer"
grep -qi 'declin' "$SK" \
  || fail "SKILL.md does not explain that declining the mechanical import routes a file to the triage prose"
[ -f "$REF" ] || fail "skills/loop-setup/references/import-triage.md missing"
grep -qi 'one actionable item' "$REF" || fail "the triage reference does not state the one-item-per-issue rule"
grep -qi 'split' "$REF" || fail "the triage reference does not cover splitting"
grep -qi 'merge' "$REF" || fail "the triage reference does not cover merging"

# the documented remote-report strings match what setup.sh actually prints
S="$REPO/skills/loop-setup/setup.sh"
for s in 'GitHub remote found' 'GitLab remote found' 'Remote found' 'No remote found'; do
  grep -qF "$s" "$S"  || fail "setup.sh does not print '$s'"
  grep -qF "$s" "$SK" || fail "SKILL.md does not document '$s'"
done

# loop-improve and loop-review name the gitlab read path alongside the others
grep -qi 'glab issue view' "$IMP" || fail "loop-improve does not name the gitlab issue-read command"
grep -qi 'glab issue view' "$REV" || fail "loop-review does not name the gitlab issue-read command"

# this repo's own config is current
grep -q '^template-version: 2$' "$CFG" || fail "config/repo-state.md is not at template-version 2"
grep -q '^tracker: github$' "$CFG"     || fail "this repo's tracker mode changed"

# house style: no em dash anywhere this task touched
for f in "$SK" "$REF" "$WF" "$CFG" "$TPL"; do
  grep -q $'—' "$f" && fail "em dash found in $f (house style forbids it)"
done

echo "PASS: gitlab doc and skill sweep"
```

- [ ] **Step 2: Run it.**
      `bash tests/loop-setup/docs-gitlab.sh`
      Expect FAIL with `wayfinder still states a github-only tracker requirement (criterion 11)`.

- [ ] **Step 3: Implement.**

  a. `skills/wayfinder/SKILL.md`: change line 15 to state that wayfinder requires a remote tracker, `github` or `gitlab`, with no local-tracker variant.
     Change "on the repo's GitHub issues" and "a single GitHub issue" to backend-neutral phrasing ("the repo's issue tracker", "a single tracker issue"), and add one sentence recording the verified fact that `wayfinder:map` needs no renaming on GitLab, because a single colon is an ordinary label character and only `::` marks a scoped label.

  b. `config/repo-state.md` (this repo): bring it to what `render_github` of the v2 template emits, keeping the two hand-set values (`Remote:` and `tracker: github`).
     Add `template-version: 2` above the `Remote:` line and widen the two "(github or local)" sentences to "(github, gitlab, or local)".
     Do **not** add a `backlog-group:` line or the gitlab backlog-view lines: Task 3's `render_github` drops those from github renders, and adding them by hand would recreate exactly the config-versus-render divergence this task exists to close.
     **Also rewrite the Local-tracker limitation prose, locating it by string rather than line number** (an earlier draft cited line numbers that were off by one on disk, and an executor with zero context edits by line number): the sentence containing `wayfinder requires \`tracker: github\``, the sentence ending `shared or branched work should use \`tracker: github\``, and the "Migration to GitHub" paragraph all still assert github-only behavior.
     This is the file an agent orienting in the repo actually reads, so leaving any of them stale would have it contradict both the template and `skills/wayfinder/SKILL.md` while the test still passed.
     Match the template's new wording exactly in all of these places, and carry over the sweep root-exclusion sentence Task 3 added to the template.
     Do not change `tracker: github`, and do not remove the `autonomy-default:` paragraph - Task 3 added it to the template precisely so this file's render round-trips it.

  c. `skills/loop-improve/SKILL.md:60-61`: state that `tracker.sh list` returns gh-shaped JSON in all three modes, and add the gitlab read path `glab issue view N` next to the existing `gh issue view N` and `docs/issues/NNN-*.md`.

  d. `skills/loop-review/SKILL.md:40`: add the gitlab equivalent, so the line reads that the referenced issue is fetched with `gh issue view <n>` in github mode or `glab issue view <n>` in gitlab mode, when that CLI is available and authenticated.

  e. Create `skills/loop-setup/references/import-triage.md`.
     It carries the split-and-merge judgment the brief assigned to prose rather than to bash, and it is the only home for that judgment.
     Contents, in the house style, one sentence per line:
     - The division of labor: `setup.sh`'s sweep offers only the mechanical import - one file becomes one issue, verbatim.
       A file that needs splitting or merging is **declined at the bash prompt** and handled here by the agent, who proposes the split, creates each issue through `scripts/tracker.sh create`, and then offers the archive move - so the flagship case (a `whats_next.md` holding many items) is never mangled into a single issue.
     - The rule: one issue names one actionable item; a proposal spanning two unrelated items is wrong and gets split before anything is created.
     - When to split: a candidate file is a list, its sections are independently actionable, or its title needs an "and" to describe it.
     - When to merge: two candidates restate the same work, or one is strictly a subset of the other; merge into the one with the better restart context and decline the other.
     - When to leave: the file is reference material, a log, or a completed record; decline it and leave it in place, knowing it will be offered again next run - that repeat is the design speaking up about a live loose end, not a bug.
     - Titling: the title is the action, in the imperative, readable without the body.
     - Labelling: `idea` for anything parked by decision; no label for active work; the `idea` label is the one load-bearing label.
     - The disclosure requirement: every proposed split is shown to the human with its proposed titles before any issue is created, because this is criterion 13 of the source brief and it is a judgment, not a check.

  f. `skills/loop-setup/SKILL.md`: update it to describe what now exists.
     Add the `gitlab` finalize alongside github and local, quote the four exact `report_remote` strings, document the mode-switch offer when a declared mode disagrees with the remote, and document both non-interactive hooks (`LOOP_TRACKER_ANSWER=gitlab`; `LOOP_IMPORT_REMOTE=1`, required alongside `LOOP_ASSUME_YES` before an unattended run may create issues on a remote backend).
     Describe the sweep: it runs in all three modes, scans the repo root, asks one gate question then per-item confirmations, offers a declinable archive move after each import, and re-offers anything declined-and-left on the next run - idempotence comes from the archive move, not from any state file.
     State the division of labor with `references/import-triage.md` (mechanical imports in bash; split/merge judgment in prose) and link it.
     Add one line for migration: when `docs/issues/` holds unmigrated files and the repo has a github or gitlab remote, suggest `scripts/migrate-tracker.sh --to <target>` - the agent suggests, the user fires, `setup.sh` never runs it.
     Correct line 50's `--dry-run-remote` description: the flag now also skips the sweep's remote issue creation, not only the finalize's gh/glab calls - the old wording would tell a test author the exact lie finding the gate exists to prevent.
     Document `tracker-remote-ack:` as the recorded acknowledgment that silences the mode-switch offer for a deliberate mode-versus-remote disagreement (written by hand, never by `setup.sh`).
     Keep it short; detail belongs in the reference file.

- [ ] **Step 4: Run it.**
      `bash tests/loop-setup/docs-gitlab.sh` - expect PASS.
      Then `bash tests/repo-state/config.sh` - expect PASS, proving the template and this repo's config still declare the same lane set.

- [ ] **Step 5: Commit.**
      ```bash
      git add skills/loop-setup/SKILL.md skills/loop-setup/references/import-triage.md \
              skills/wayfinder/SKILL.md skills/loop-improve/SKILL.md skills/loop-review/SKILL.md \
              config/repo-state.md tests/loop-setup/docs-gitlab.sh
      git commit -m "docs: gitlab as a peer backend across wayfinder, loop-improve, loop-review, and loop-setup"
      ```

---

### Task 7: Live forge smoke `[HUMAN CHECKPOINT - every write is the user's to fire]`

Depends on: Task 6

**Files (exclusive ownership):**

- Modify: `/home/jjrdar/claude/forge/config/repo-state.md` (via the tooling, not by hand)
- Move: `/home/jjrdar/claude/forge/whats_next.md` to `docs/archive/` (via the sweep's archive offer, user-accepted)
- Modify: `/home/jjrdar/claude/forge/scripts/tracker.sh`, `gen-mirrors.sh`, `graduate-parking.sh` (via loop-setup's drift refresh)
- No files in this repo are modified.

**Interfaces:**

Consumes: everything from Tasks 1 through 6.
Produces: the brief's end artifact, plus a recorded answer to criterion 13.

**Acceptance check:** `bash tests/run.sh` exits 0 and reports `0 failed`, **and** the results table below is filled in with an observed value for every row `[executed-check]`

The offline suite alone is not sufficient: it verifies none of Steps 3 through 8, so criteria 3, 4, and 11 would reduce to unrecorded human observation and an executor could mark this task done without firing anything live.
The live GitLab round trip is **not** an executed check an executor may run.
It is staged below for the user, who fires each command and records what came back.

**Results table - Task 7 is not done until every row has an observed value.**

| Step | What was fired | Expected | Observed |
| --- | --- | --- | --- |
| 1 | `bash tests/run.sh` | `0 failed` | |
| 2 | `setup.sh` in forge | reports the GitLab remote, offers the mode switch | |
| 2b | cleanup probe: rename then delete one throwaway issue | at least one route works; the route is recorded | |
| 3 | proposed `whats_next.md` split | titles approved by a human | |
| 4 | create / list / mirror / close | iid created, appears in BACKLOG.md, gone after close | |
| 5 | bare `glab auth status` vs `tracker.sh list` | bare non-zero, tracker exit 0 | |
| 6 | immediate re-run | `nothing to do`, zero `import candidate:` lines | |
| 7 | wayfinder map + ticket | `wayfinder:map` accepted, excluded from both mirrors | |
| 8 | cleanup | smoke issues removed, forge tree clean | |

- [ ] **Step 1: Run the full offline suite first.**
      `bash tests/run.sh`
      Expect every suite to pass and the final line to read `0 failed`.
      This is the task's acceptance check and the plan's gate.
      Nothing touches forge until this is green.

- [ ] **Step 2: Stage the forge run - do not execute.**
      Print these for the user, with the blast radius stated: they write to the shared RIT instance `gitlab.code.rit.edu`, group `university-advancement`.

      ```bash
      cd /home/jjrdar/claude/forge
      git status --short              # must be clean before anything writes
      git rev-parse --abbrev-ref HEAD # note the branch you are on
      git checkout -b loop-setup-gitlab-adoption   # a rollback point, not optional
      glab auth status --hostname gitlab.code.rit.edu   # expect exit 0
      /home/jjrdar/repos/loop-stack-session/skills/loop-setup/setup.sh
      ```

      The branch is not ceremony.
      `setup.sh`'s drift-refresh loop offers to **replace** forge's vendored `scripts/tracker.sh`, `gen-mirrors.sh`, `graduate-parking.sh`, and now `migrate-tracker.sh` with loop-stack's copies, and it warns that local edits are lost.
      forge has its own `scripts/` tree with many unrelated Python files; a branch makes accepting those refreshes reversible with one command.

      For gitlab mode, two of those refreshes are required, not optional: `tracker.sh` (a declined refresh leaves a copy whose `mode set` rejects `gitlab`, which g3 turns into a loud stop) and `gen-mirrors.sh` (a declined refresh would leave forge's mirrors disclosing GitHub as the source of truth on a GitLab repo, which Task 3's finalize guard turns into a named failure).
      Accept both; decline any other at will.

      Expected, in order: `GitLab remote found: ssh://git@gitlab.code.rit.edu:2222/university-advancement/crm/forge.git - suggesting tracker: gitlab`; then, because forge already declares `tracker: local`, `declared tracker: local, but the remote is gitlab: <url>` and the offer to switch; a drift-refresh offer per vendored script; a config re-render offer that replaces `Remote: none (local tracker; see the Local tracker section)` with the real URL and adds `backlog-group: university-advancement`; then the import sweep's count line and gate question covering `whats_next.md`.

      **Decline the sweep's mechanical import offer for `whats_next.md`.**
      The bash sweep would file the whole 7433-byte file as one issue, which is exactly what criterion 13 forbids; per `references/import-triage.md`, a file that needs splitting is declined at the bash prompt and handled by the agent in Step 3.

      If the mode-switch offer does not appear, stop: Task 3's g2 did not land, and everything downstream of it in forge is unreachable.

- [ ] **Step 2b: Verify the cleanup surface before anything permanent is created - the user fires.**
      Step 7b's cleanup rests on two `glab` commands the planning session never verified (they are named risks in the Verified facts section): `glab api --method DELETE "projects/:id/issues/<iid>"`, including whether the `:id` placeholder substitutes, and `glab issue update <iid> --title`.
      Prove both on one throwaway issue now, while zero smoke issues exist, so a wrong guess strands nothing colleague-visible later:

      ```bash
      cd /home/jjrdar/claude/forge
      p=$(scripts/tracker.sh create --label idea --title "loop-stack cleanup probe" --body "Delete me immediately. Verifying the cleanup route before the smoke run.")
      echo "probe #$p"
      glab issue update "$p" --title "[probe] loop-stack cleanup probe" ; echo "update exit: $?"
      glab api --method DELETE "projects/:id/issues/$p" ; echo "delete exit: $?"
      ```

      Record in the results table which of the two worked.
      If the delete fails (owner rights, or the `:id` placeholder does not substitute), Step 7b's rename route is the committed fallback - that decision is made here, not after three smoke issues exist.
      If **both** fail, stop before Step 4: the plan's own standard says closed "Delete me" tickets left in the shared project are not an acceptable end state, so do not create what cannot be cleaned up or clearly marked.

- [ ] **Step 3: Criterion 13 - the human judgment, before any issue exists.**
      Read `/home/jjrdar/claude/forge/whats_next.md` (7433 bytes) against `skills/loop-setup/references/import-triage.md`.
      Propose a split into issues, one actionable item each, and show the proposed titles to the user **before** creating anything.
      If any proposed issue spans two unrelated items, redo the split.
      After the user approves the title list, create each issue with `scripts/tracker.sh create` (the user fires each one, or approves the batch explicitly), then offer the archive move: `git mv whats_next.md docs/archive/`.
      Once archived, the file never re-offers - that move, not any record, is what makes the re-run in Step 6 quiet.

- [ ] **Step 4: Stage the criterion 3 round trip - the user fires each line.**

      ```bash
      cd /home/jjrdar/claude/forge
      scripts/tracker.sh mode get                    # expect: gitlab
      scripts/tracker.sh list                        # expect: exit 0, gh-shaped JSON array
      n=$(scripts/tracker.sh create --label idea --title "loop-stack gitlab smoke" --body "Delete me. Round-trip check for the gitlab backend.")
      echo "created #$n"
      scripts/tracker.sh list | grep -o "\"number\":$n"    # expect the new iid
      scripts/gen-mirrors.sh .
      grep "| $n |" BACKLOG.md                       # expect the row, in BACKLOG not ISSUES
      grep -c "| $n |" ISSUES.md                     # expect 0
      scripts/tracker.sh close "$n"
      scripts/gen-mirrors.sh .
      grep -c "| $n |" BACKLOG.md                    # expect 0
      ```

      Then fire the cross-repo backlog query **exactly as the config renders it**, rather than trusting that a rendered command works:

      ```bash
      cd /home/jjrdar/claude/forge
      grep '^backlog-group:' config/repo-state.md    # expect: university-advancement
      glab issue list --group university-advancement --label idea ; echo "exit: $?"
      ```

      Expect exit 0 - and then classify the rows, because exit 0 alone cannot distinguish a correctly scoped group from a university-wide one that would pull other teams' `idea` issues into this repo's declared backlog view (the live query currently returns `[]`, which passes either way):

      ```bash
      glab issue list --group university-advancement --label idea -O json --jq '.[].web_url'
      ```

      An empty result or rows all under `https://gitlab.code.rit.edu/university-advancement/crm/` both pass; any row from a project outside `university-advancement/crm/` means the top-level group is too wide for this instance.
      On a non-zero exit or a foreign row, set `backlog-group: university-advancement/crm` **by hand** in `config/repo-state.md` - the key is documented as an overridable, re-render-surviving value, and that is the whole mechanism.
      Do **not** change Task 1's `gitlab_group` derivation: its committed test asserts the first-segment derivation at three URL shapes, so changing it reopens a done task and turns `tests/run.sh` red inside the task whose acceptance check is `0 failed`.
      If the derivation itself proves wrong for this instance, file a follow-up issue rather than patching it mid-checkpoint.

- [ ] **Step 5: Criterion 4 - the dead-token regression, fired by the user.**
      With the `gitlab.com` token still dead on this host:

      ```bash
      cd /home/jjrdar/claude/forge
      glab auth status ; echo "bare exit: $?"        # expect a NON-zero exit - this is the trap
      scripts/tracker.sh list >/dev/null ; echo "tracker exit: $?"   # expect 0
      ```

      A non-zero `tracker exit` means the guard is not host-scoped and Task 1 is not done.

- [ ] **Step 6: Criteria 8 and 10 - idempotence and the standalone migration, fired by the user.**

      ```bash
      cd /home/jjrdar/claude/forge
      /home/jjrdar/repos/loop-stack-session/skills/loop-setup/setup.sh   # answer nothing; expect no offers
      ```

      Expect `loop-setup complete - nothing to do` and zero `import candidate:` lines - `whats_next.md` is quiet because it now lives in `docs/archive/`, not because anything remembered a decision.
      Then confirm the standalone migration path runs and reports correctly against forge's empty `docs/issues/`:

      ```bash
      cd /home/jjrdar/claude/forge
      MIGRATE_DRY_RUN=1 scripts/migrate-tracker.sh --to gitlab
      ```

      Expect exit 0 with `migrate-tracker: no local issues in docs/issues` - forge has zero local issue files, so there is nothing to migrate; the check is that the vendored script exists, accepts the flag, and says so.

- [ ] **Step 7: Criterion 11 - wayfinder on GitLab, fired by the user.**
      Task 6 removes wayfinder's github-only claim, but only a live run proves the claim was safe to remove.
      In forge, with the user firing each write, create a wayfinder map issue and one decision ticket:

      ```bash
      cd /home/jjrdar/claude/forge
      m=$(scripts/tracker.sh create --label "wayfinder:map" --title "forge: wayfinder smoke map" --body "## Destination
      Delete me. Live check that wayfinder's issue shape works on GitLab.

      ## Notes

      ## Decisions so far

      ## Not yet specified
      - the one open question below")
      echo "map #$m"
      t=$(scripts/tracker.sh create --label "" --title "forge: wayfinder smoke ticket" --body "Child of the smoke map #$m. Delete me.")
      echo "ticket #$t"
      scripts/gen-mirrors.sh .
      grep -c "| $m |" ISSUES.md BACKLOG.md   # expect 0 in BOTH: wayfinder:* is excluded from mirrors
      grep -c "| $t |" ISSUES.md              # expect 1
      scripts/tracker.sh close "$t"
      scripts/tracker.sh close "$m"
      scripts/gen-mirrors.sh .
      ```

      The load-bearing check is the label: `wayfinder:map` must survive GitLab intact, and the mirror exclusion for `wayfinder:*` must still fire.
      A non-zero count for `$m` in either mirror means the exclusion broke and criterion 11 is not met.
      If GitLab rejects the label name outright, stop: the plan's assumption that a single colon is an ordinary label character is wrong, and `skills/wayfinder/SKILL.md` needs a GitLab-specific label name rather than the edit Task 6 made.

- [ ] **Step 7b: Clean up the smoke artifacts - fired by the user.**
      Steps 4 and 7 create three issues titled for deletion, and closing an issue does not remove it.
      Left as-is they persist permanently in a shared corporate project that other people browse.

      ```bash
      cd /home/jjrdar/claude/forge
      # confirm exactly which issues the smoke created, by title, before touching anything
      glab issue list --all --search "smoke" -O json --jq '.[] | "\(.iid) \(.title) \(.state)"'
      ```

      Use the route Step 2b proved on the throwaway issue - both commands were verified there before anything permanent existed.
      If the delete route worked, delete one iid at a time, each confirmed:

      ```bash
      glab api --method DELETE "projects/:id/issues/<iid>"
      ```

      If Step 2b recorded the rename fallback instead, mark each clearly:

      ```bash
      glab issue update <iid> --title "[closed test artifact] <original title>"
      ```

      Record in the results table which route was taken and the final iids.
      Leaving closed "Delete me" tickets in `university-advancement/crm/forge` is not an acceptable end state.

- [ ] **Step 8: Commit forge's own state, if the user accepts.**
      forge is a separate repo; this plan's commits do not cover it.
      Stage and hand the user the command:

      ```bash
      cd /home/jjrdar/claude/forge
      git add config/repo-state.md docs/archive/whats_next.md scripts/ ISSUES.md BACKLOG.md
      git status --short
      git commit -m "loop-setup: adopt the gitlab tracker backend"
      ```

      Whether `whats_next.md` is archived, deleted, or kept is the user's call; archived is the recommended end state, because it is what keeps every future `loop-setup` run quiet.
