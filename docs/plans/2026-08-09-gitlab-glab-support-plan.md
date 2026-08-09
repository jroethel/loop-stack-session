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
- Ungating the sweep in this repo, **with the repo-root scan Task 4 adds**, surfaces 9 candidates: 7 under `docs/plans/` (including this plan file), plus `PLAN.md` by filename keyword and `fixing-agent-errors.md` by content shape.
  An earlier count of 6 was measured before the root scan existed and is superseded.
- `ISSUES.md` and `BACKLOG.md` are gitignored in this repo, but `is_excluded` already drops them by basename, so gitignore-awareness is not load-bearing for them.
- Both `glab issue list --group university-advancement --label idea` and the subgroup form `--group university-advancement/crm --label idea` exit 0 against the live instance.
  The top-level group form that gets rendered into the config is usable, not merely plausible.
- `glab issue list` has **no** `--state` flag.
  It exposes only `-A/--all` and `-c/--closed`, and its documented default is open items only.
  The open-only guarantee is therefore an absence of flags, not a flag.

## Resolved planning decisions

The brief's open questions, each answered here so no task carries a placeholder.

| Question | Resolution |
| --- | --- |
| Where does the JSON translation live | glab's built-in `--jq`, one expression, no bash JSON assembly and no new dependency |
| `iid` or `id` for the issue number | `iid`; `id` is the instance-global id and is never used |
| Pagination past 100 | Page loop at `--per-page 100`, stopping when a page returns fewer than 100 rows, with a 50-page ceiling |
| Backlog group: key or derived | Derived from the remote at render time, written as a line-anchored `backlog-group:` key so it is overridable, and preserved across re-renders |
| Split/merge guidance home | A new reference file, `skills/loop-setup/references/import-triage.md`, keeping SKILL.md short |
| Standalone migration re-run | Both: `setup.sh` offers it, and `scripts/migrate-tracker.sh` remains directly runnable with identical behavior |
| forge's false `Remote: none` line | Needs its own correction, not the re-render alone. `setup.sh:203-206` short-circuits whenever a `tracker:` key already exists, so in forge (`tracker: local`) `report_remote` never runs, `MODE` stays `local`, and `render_local` writes `Remote: none` straight back. Task 3 adds a remote-versus-declared-mode disagreement check that runs even on the short-circuit path |
| Does "leave in place" need a marker | Yes, forced by criterion 8: a declined candidate is a recorded decision in the ledger, not a deferral |
| Setup-logic stamp shape | One repo-side version, `loop-setup-version:` in the ledger, plus per-consumer "last changed at" constants held in the tool (see below) |
| This repo's missing `template-version` | Backfilled in Task 6 as part of bringing `config/repo-state.md` to template-version 2 |

### The versioning model

The repo carries exactly **one** number.
Each consumer of that number declares, inside the tool, the version at which *it* last changed.
A consumer re-fires if and only if the repo's recorded version is older than that consumer's own last-changed version.

- Repo side: `loop-setup-version: N` in `config/loop-setup-state.md`, written at the end of a completed run.
- Tool side: `SETUP_VERSION` in `setup.sh` (the current bundle version, bumped on every release), `SWEEP_CHANGED_AT` in `setup.sh` (last version at which sweep logic changed), and for the config consumer the template's own `template-version:` value, which already means "the template last changed at version N".

This gives one repo-side number without conflating remedies.
Bumping the template offers a config re-render and nothing else.
Bumping `SWEEP_CHANGED_AT` re-offers imports and nothing else.
Adding a fourth consumer later costs one more constant and no repo-side schema change.

Seeding an existing repo that predates the ledger: read `template-version:` from its `config/repo-state.md`, or `0` when absent.
The version is recorded at the end of a run whether an offer was accepted or declined.

### What makes a decision durable, and what reopens it

A recorded decision stays quiet only while the thing it was about has not moved.
This is the brief's own scope, at lines 39-41: "with the same answers **and nothing else changed**", and "it acts again only when **something it depends on has moved**".
Criterion 8 is the checkable restatement of that sentence, not a stronger claim; an unconditional never-ask-again would be a misreading of it.

Two independent reopen triggers, and a decision is re-offered when **either** fires:

1. **A version moved.** `RV < SWEEP_CHANGED_AT` reopens every import decision; `RV < tv` reopens the config decision.
2. **The subject moved.** Every decision records a fingerprint of what it was about: `cksum` of the candidate file for an import, `cksum` of `config/repo-state.md` for the config.
   When the current fingerprint differs from the recorded one, the decision no longer describes what is on disk, so it is re-offered.

Concretely: decline `whats_next.md`, change nothing, re-run - silence.
Edit `whats_next.md` and re-run - offered again, because the decision was about a file that no longer exists in that form.
Hand-edit `config/repo-state.md` after declining a re-render - offered again.

The config consumer additionally measures staleness against the **config file itself** (`version_of config/repo-state.md`), not only against the ledger, so a config restored from an older render or resolved badly in a merge is still reported stale.

Silence is never total: every run ends with a summary line naming the recorded-decision count, so "nothing to do" is a statement, not an absence.

`cksum` is POSIX and already available; it introduces no dependency, and reading it as `cksum < "$f"` keeps the filename out of the output so a rename does not change the fingerprint on its own.

## Review record

This plan was revised after a two-lens fresh-context review.
Twenty-one findings were applied in full.
Three were applied only in part, and the reason each was narrowed is recorded here rather than left implicit.

| Reviewer proposal | Verdict | Reason |
| --- | --- | --- |
| Add `--state opened` to the `glab issue list` call | Declined as written, intent adopted | The flag does not exist: `glab issue list` exposes only `-A/--all` and `-c/--closed`, and defaults to open. Task 1 instead asserts the call passes **neither** flag, which is the checkable form of the same guarantee |
| Pass `-R/--repo` on every `glab issue` call so the guard's host cannot diverge from glab's target | Declined | glab already resolves host and project from the same repo remote, so the two cannot diverge today. Adding `-R` introduces a second, independently-derivable target and a new way for them to disagree. The underlying fork-layout concern is addressed instead by fixing remote classification (Task 3) |
| Add a `setup.sh --reopen <path>` subcommand to clear one ledger line | Declined | The fingerprint trigger already reopens a decision whose subject changed, which is the real case. A hand-edit of one ledger line covers the rest, and is documented. A new CLI surface plus its tests is not earned |
| Top-level `backlog-group` may be unusable on a university-wide instance | Premise declined, check adopted | `glab issue list --group university-advancement --label idea` exits 0 against the live instance, so the rendered command works. Task 7 still fires the rendered command, because a verified command beats a plausible one |

## Dependency graph

```
Wave 1 (parallel):  Task 1 (tracker.sh)      Task 2 (gen-mirrors.sh)
                          |
Wave 2:             Task 3 (setup.sh: gitlab mode)
                          |
Wave 3:             Task 4 (setup.sh: version, ledger, universal sweep)
                          |
Wave 4:             Task 5 (migrate-tracker.sh: gitlab target)
                          |
Wave 5:             Task 6 (docs and skill sweep)
                          |
Wave 6:             Task 7 (live forge smoke - HUMAN CHECKPOINT)
```

Tasks 1 and 2 touch disjoint files and have no path between them, so they are parallel-eligible.
Tasks 3, 4, and 5 all modify `skills/loop-setup/setup.sh` and are therefore strictly sequential; that is a deliberate serialization, not a missing edge.

## Human checkpoints

1. **Before Task 7, and throughout it.**
   Task 7 writes to a live shared GitLab instance (`gitlab.code.rit.edu`, group `university-advancement`).
   Every issue-creating and issue-closing command in Task 7 is staged for the user to fire; an executor never runs them unattended.

2. **Criterion 13 of the brief (`[judgment]`).**
   "The sweep's proposed split of `whats_next.md` yields issues that each name one actionable item, with no proposal spanning two unrelated items."
   This is judged by a human reading the proposed titles in Task 7, not by any command.
   If a proposal spans two unrelated items, the split is redone before any issue is created.

3. **Any candidate file the sweep offers to archive or delete in a repo other than a scratch sandbox.**
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
| 8 | An immediate re-run offers nothing and says so | Task 4 test (criterion 8 block), Task 7 Step 6 live |
| 9 | Bumping either version re-offers exactly the affected work | Task 4 test (criterion 9a and 9b blocks) |
| 10 | Migration offered during setup, declinable, standalone identical | Task 5 test (criterion 10 block), Task 7 Step 6 live |
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

Depends on: Task 1

**Files (exclusive ownership):**

- Modify: `skills/loop-setup/setup.sh`
- Modify: `config/repo-state.template.md`
- Modify: `tests/loop-setup/acceptance.sh:56,66` (the two remote-report string assertions)
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

**Acceptance check:** `bash tests/loop-setup/gitlab-setup.sh` exits 0 `[executed-check]`

- [ ] **Step 1: Write the failing test.**
      Create `tests/loop-setup/gitlab-setup.sh` with exactly this content:

```bash
#!/usr/bin/env bash
# loop-setup in gitlab mode: remote detection and suggestion, config render with the derived
# backlog group, gitlab finalize (host-scoped auth, idea label), and repair of a false
# "Remote: none" line inherited from a local-mode config.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SETUP="$REPO/skills/loop-setup/setup.sh"
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

# ---------- scenario B: an existing local config with a FALSE "Remote: none" line ----------
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

# ---------- scenario D: an unknown mode answer is rejected ----------
D="$(mktemp -d)"; trap 'rm -rf "$BIN" "$A" "$B" "$C" "$D"' EXIT
( cd "$D" && git init -q )
( cd "$D" && LOOP_TRACKER_ANSWER=bitbucket "$SETUP" </dev/null >/dev/null 2>&1 ) \
  && fail "setup accepted an unknown tracker mode"

# ---------- scenario E: THE FORGE CASE - a declared mode that disagrees with the remote ----------
# This is the shape of /home/jjrdar/claude/forge: tracker: local declared, GitLab remote present.
# Before this fix, setup.sh short-circuited at line 203 and none of the above was reachable there.
E="$(mktemp -d)"; trap 'rm -rf "$BIN" "$A" "$B" "$C" "$D" "$E"' EXIT
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

# ---------- scenario F: gitlab mode refuses a vendored tracker.sh that predates it ----------
F="$(mktemp -d)"; trap 'rm -rf "$BIN" "$A" "$B" "$C" "$D" "$E" "$F"' EXIT
( cd "$F" && git init -q && git remote add origin 'ssh://git@gitlab.example.com:2222/grp/repo.git' )
mkdir -p "$F/scripts"
# A pre-gitlab tracker.sh: no 'gitlab)' case anywhere. It must report NO declared mode, so the
# run reaches determine_mode and resolves to gitlab; a stub that echoed a mode would short-circuit
# at line 203 and the guard under test would never be reached.
printf '#!/usr/bin/env bash\n# legacy: predates the gitlab backend\nexit 1\n' > "$F/scripts/tracker.sh"
chmod +x "$F/scripts/tracker.sh"
# LOOP_ASSUME_NO declines the drift refresh, so the legacy copy survives into the finalize.
out="$( cd "$F" && LOOP_TRACKER_ANSWER=gitlab LOOP_ASSUME_NO=1 "$SETUP" </dev/null 2>&1 )" \
  && fail "gitlab mode ran against a tracker.sh that predates the gitlab backend"
printf '%s\n' "$out" | grep -q 'predates the gitlab backend' \
  || fail "the stale-tracker.sh refusal did not name the cause or the fix"

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
     - Add one line to the Local tracker section's migration paragraph naming gitlab as a migration target: `Migration targets either remote backend; `scripts/migrate-tracker.sh --to gitlab` recreates every local issue as a GitLab issue.`

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
     Also update `render_github` and `render_local` to substitute `{{BACKLOG_GROUP}}`: `render_github` with the derived group (empty is acceptable and yields an empty value), `render_local` with `n/a (local tracker)`.

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
     - Always call `report_remote`, so the remote is stated on every run rather than only on first setup.
     - When `remote_kind` is `github` or `gitlab` and it differs from `existing_mode`, print
       `declared tracker: <existing_mode>, but the remote is <remote_kind>: <url>`
       and offer, via the existing `ask`, `switch this repo to tracker: <remote_kind>?`.
     - On accept, run `scripts/tracker.sh mode set "<remote_kind>"`, set `MODE` to it, and let `reconcile_config` render the correct config on the same run.
     - On decline, leave everything untouched and record the decision in the ledger as `mode|<remote_kind>|declined` (Task 4 supplies `ledger_record`; until Task 4 lands, decline simply leaves it alone and the offer repeats).
     A `remote_kind` of `other` or `none` never triggers the offer: there is nothing to suggest.

  g3. **Refuse to run gitlab against a vendored `tracker.sh` that predates it.**
     `setup.sh` drives the target repo's own `scripts/tracker.sh`, and the drift refresh at lines 75-87 is declinable per file.
     Declining it while choosing gitlab leaves a two-branch `tracker.sh` whose `else` treats `gitlab` as local, so every issue lands in `docs/issues/` while the run reports success, and line 219 pipes `mode set` to `/dev/null` so nothing surfaces.
     After the mode is resolved and before the finalize, add:
     ```bash
     if [ "$MODE" = gitlab ] && ! grep -q 'gitlab)' scripts/tracker.sh; then
       fail "scripts/tracker.sh predates the gitlab backend; re-run loop-setup and accept the drift refresh"
     fi
     ```
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

  i. Update the header comment on lines 2-4 to name the gitlab finalize.

  j. In `tests/loop-setup/acceptance.sh`, update line 56's expected string to `GitHub remote found` (unchanged) and line 66's to `No remote found`, matching the new wording.

- [ ] **Step 4: Run it.**
      `bash tests/loop-setup/gitlab-setup.sh` - expect PASS.
      Then `bash tests/loop-setup/acceptance.sh`, `bash tests/loop-setup/reconcile.sh`, `bash tests/loop-setup/distribution.sh`, `bash tests/loop-setup/import.sh` - expect PASS.
      Note: `tests/loop-setup/reconcile.sh` compares an accepted re-render against a fresh render, so it passes across the template bump without editing.

- [ ] **Step 5: Commit.**
      ```bash
      git add skills/loop-setup/setup.sh config/repo-state.template.md \
              tests/loop-setup/gitlab-setup.sh tests/loop-setup/acceptance.sh
      git commit -m "loop-setup: gitlab mode with remote suggestion, derived backlog group, and glab finalize"
      ```

---

### Task 4: `setup.sh` re-run idempotence - one repo version, a decision ledger, a universal sweep

Depends on: Task 3

**Files (exclusive ownership):**

- Modify: `skills/loop-setup/setup.sh`
- Modify: `tests/loop-setup/reconcile.sh` (the decline-then-accept sequence, per step i)
- Modify: `tests/loop-setup/import.sh` (the sweep now runs in every mode and asks a gate question first)
- Modify: `tests/repo-state/config.sh` (assert the ledger is not gitignored, per step j2)
- Modify: `.gitignore` only if a rule would otherwise capture `config/loop-setup-state.md`; the ledger must remain committed
- Test: `tests/loop-setup/idempotence.sh` (create)

**Interfaces:**

Consumes, from Task 3: `render_gitlab`, the repaired `reconcile_config`, `report_remote`, `version_of`.

Produces, for Tasks 5 through 7:

- `config/loop-setup-state.md`, the machine-written ledger, **committed, never gitignored** (a fresh clone that lost it would re-offer and re-import every candidate, duplicating issues on the remote with no dedupe).
  It carries a line-anchored `loop-setup-version: N` key and zero or more decision lines of the form `<kind>|<key>|<verdict>|<date>|<ref>|<fingerprint>`.
  Three kinds exist:
  - `import` - key is the repo-relative candidate path, verdict is `imported`, `declined`, or `archived`, fingerprint is `cksum < <path>`.
  - `config` - key is `repo-state.md`, verdict is `rendered` or `declined`, fingerprint is `cksum < config/repo-state.md` as it stood when the decision was made.
  - `migrate` - key is the target backend, verdict is `offered`, fingerprint is `-`.

  `<ref>` is `#<number>` or `-`.
  There is exactly **one** line per `<kind>|<key>`: `ledger_record` replaces in place rather than appending, so no reader ever has to decide which of two contradictory verdicts is current.
- Two constants at the top of `setup.sh`: `SETUP_VERSION=2` and `SWEEP_CHANGED_AT=2`.
- `repo_version` - prints the repo's recorded `loop-setup-version`, seeded from `config/repo-state.md`'s `template-version` when the ledger is absent, and `0` when both are absent.
- `fp <path>` - prints `cksum < "$path" | awk '{print $1}'`, or `-` when the path does not exist.
  Reading from stdin keeps the filename out of `cksum`'s output, so a rename alone does not change the fingerprint.
- `ledger_settled <kind> <key> <fingerprint>` - exit 0 when a record exists for that kind and key **and** its recorded fingerprint matches. A record whose fingerprint differs is not settled: the subject moved.
- `ledger_record <kind> <key> <verdict> <ref> <fingerprint>` - writes one line, replacing any existing line for that kind and key.
- `reconcile_import` now runs in all three modes and additionally scans repo-root `*.md` non-recursively.
- A new non-interactive hook, `LOOP_SWEEP_ANSWER=y|n`, answering the sweep's **gate** question only.
  It exists because `LOOP_ASSUME_YES` / `LOOP_ASSUME_NO` answer every `ask` with one value, which makes "accept the gate, then decline each item" unreachable in a test.
  When unset, the gate falls through to the normal `ask`.
- A second new hook, `LOOP_IMPORT_REMOTE=1`, required in addition to `LOOP_ASSUME_YES` before an unattended run may create issues on a **remote** backend.
  Local mode ignores it.
  It exists because ungating the sweep changed the unattended blast radius from "writes local markdown" to "files an issue per candidate on a shared instance", and that escalation should be opted into explicitly rather than inherited from a blanket yes.

**Acceptance check:** `bash tests/loop-setup/idempotence.sh` exits 0 `[executed-check]`

- [ ] **Step 1: Write the failing test.**
      Create `tests/loop-setup/idempotence.sh` with exactly this content:

```bash
#!/usr/bin/env bash
# Criteria 7, 8, 9: the sweep runs in all three modes behind one gate question then per-item
# confirmation; a settled repo offers nothing on re-run and SAYS so; bumping either the config
# template-version or the sweep's changed-at constant re-offers exactly the affected work.
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
  printf '# The plan\nLabel: idea\ndo the work\n'        > "$1/docs/some-plan.md"
}

# ---------- criterion 7: gate question, then per-item, in local mode ----------
A="$(mktemp -d)"; trap 'rm -rf "$A"' EXIT
mk "$A"
out="$( cd "$A" && LOOP_TRACKER_ANSWER=local LOOP_ASSUME_YES=1 "$SETUP" </dev/null 2>/dev/null )" \
  || fail "local sweep run exited non-zero"
printf '%s\n' "$out" | grep -qi 'import candidate' || fail "sweep offered no candidates in local mode"
# the ROOT file is reached - the current scan roots miss it, which is the forge bug
printf '%s\n' "$out" | grep -q 'whats_next.md' || fail "sweep did not reach the repo-root whats_next.md"
printf '%s\n' "$out" | grep -q 'docs/some-plan.md' || fail "sweep did not reach docs/some-plan.md"
[ "$(ls "$A/docs/issues"/*.md 2>/dev/null | wc -l)" -eq 2 ] || fail "accept-all did not create two issues"

# ---------- criterion 8: an immediate re-run offers nothing AND says so ----------
out2="$( cd "$A" && "$SETUP" </dev/null 2>/dev/null )" || fail "second run exited non-zero"
printf '%s\n' "$out2" | grep -qi 'import candidate' && fail "settled repo re-offered a candidate"
printf '%s\n' "$out2" | grep -qi 'stale'            && fail "settled repo re-offered a config re-render"
printf '%s\n' "$out2" | grep -qi 'nothing to do'    || fail "settled repo went quiet instead of saying nothing to do"
grep -q '^loop-setup-version:' "$A/config/loop-setup-state.md" \
  || fail "the ledger records no loop-setup-version"
# accept-all also accepts the archive move, so the verdict is 'archived'; either is a settled import
grep -qE '^import\|whats_next\.md\|(imported|archived)\|' "$A/config/loop-setup-state.md" \
  || fail "the ledger did not record a settled verdict for the imported root candidate"
[ "$(grep -c '^import|whats_next.md|' "$A/config/loop-setup-state.md")" -eq 1 ] \
  || fail "the ledger holds more than one verdict for whats_next.md (records must replace, not append)"
grep -qE '^config\|repo-state\.md\|rendered\|' "$A/config/loop-setup-state.md" \
  || fail "the ledger did not record the accepted config re-render"

# ---------- a DECLINED candidate is a recorded decision, not a deferral ----------
# LOOP_SWEEP_ANSWER=y accepts the GATE; LOOP_ASSUME_NO=1 then declines each ITEM.
B="$(mktemp -d)"; trap 'rm -rf "$A" "$B"' EXIT
mk "$B"
( cd "$B" && LOOP_TRACKER_ANSWER=local LOOP_SWEEP_ANSWER=y LOOP_ASSUME_NO=1 "$SETUP" </dev/null >/dev/null 2>&1 ) \
  || fail "decline-all run exited non-zero"
grep -qF 'import|whats_next.md|declined|' "$B/config/loop-setup-state.md" \
  || fail "a declined candidate was not recorded in the ledger"
out3="$( cd "$B" && "$SETUP" </dev/null 2>/dev/null )" || fail "post-decline re-run exited non-zero"
printf '%s\n' "$out3" | grep -qi 'import candidate' && fail "a declined candidate was re-offered"
[ -f "$B/whats_next.md" ] || fail "a declined candidate file was touched"

# ---------- a NEW candidate appearing later is still offered ----------
printf '# Todo\nLabel: idea\nnew work\n' > "$B/docs/late-todo.md"
out4="$( cd "$B" && LOOP_SWEEP_ANSWER=y LOOP_ASSUME_NO=1 "$SETUP" </dev/null 2>/dev/null )" \
  || fail "new-candidate run exited non-zero"
printf '%s\n' "$out4" | grep -q 'docs/late-todo.md' || fail "a newly added candidate was not offered"
printf '%s\n' "$out4" | grep -q 'whats_next.md'     && fail "an already-decided candidate was re-offered"

# ---------- criterion 9a: bumping the sweep constant re-offers imports, NOT the config ----------
C="$(mktemp -d)"; trap 'rm -rf "$A" "$B" "$C"' EXIT
mk "$C"
( cd "$C" && LOOP_TRACKER_ANSWER=local LOOP_SWEEP_ANSWER=y LOOP_ASSUME_NO=1 "$SETUP" </dev/null >/dev/null 2>&1 ) \
  || fail "C first run failed"
grep -qF 'import|whats_next.md|declined|' "$C/config/loop-setup-state.md" \
  || fail "C first run did not settle its candidates"
sed -i.bak -E 's/^loop-setup-version:.*/loop-setup-version: 1/' "$C/config/loop-setup-state.md"
out5="$( cd "$C" && LOOP_SWEEP_ANSWER=y LOOP_ASSUME_NO=1 "$SETUP" </dev/null 2>/dev/null )" \
  || fail "C bumped run exited non-zero"
printf '%s\n' "$out5" | grep -q 'whats_next.md' \
  || fail "an older recorded version did not re-offer settled import candidates (criterion 9)"

# ---------- criterion 9b: an older version re-offers the config re-render ----------
printf '%s\n' "$out5" | grep -qi 'stale' \
  || fail "an older recorded version did not re-offer the config re-render (criterion 9)"

# ---------- the two constants are coherent ----------
sv="$(grep -E '^SETUP_VERSION=' "$SETUP" | head -1 | cut -d= -f2)"
sc="$(grep -E '^SWEEP_CHANGED_AT=' "$SETUP" | head -1 | cut -d= -f2)"
tv="$(grep -E '^template-version:' "$REPO/config/repo-state.template.md" | head -1 | sed -E 's/^[^:]+:[[:space:]]*//')"
[ -n "$sv" ] && [ -n "$sc" ] && [ -n "$tv" ] || fail "a version constant is missing"
[ "$sv" -ge "$sc" ] || fail "SETUP_VERSION ($sv) is behind SWEEP_CHANGED_AT ($sc)"
[ "$sv" -ge "$tv" ] || fail "SETUP_VERSION ($sv) is behind the template-version ($tv)"

# ---------- criterion 7: the sweep also runs in github mode ----------
D="$(mktemp -d)"; FIX="$REPO/tests/repo-state/fixtures/issues.json"
trap 'rm -rf "$A" "$B" "$C" "$D"' EXIT
mk "$D"
( cd "$D" && git remote add origin https://github.com/acme/x.git )
out6="$( cd "$D" && LOOP_TRACKER_ANSWER=github MIRRORS_JSON_FILE="$FIX" \
         LOOP_SWEEP_ANSWER=y LOOP_ASSUME_NO=1 \
         "$SETUP" --dry-run-remote </dev/null 2>/dev/null )" || fail "github sweep run exited non-zero"
printf '%s\n' "$out6" | grep -qi 'import candidate' \
  || fail "the sweep did not run in github mode (criterion 7)"

# ---------- criterion 7: the sweep also runs in gitlab mode, and creates through tracker.sh ----------
BIN="$(mktemp -d)"; E="$(mktemp -d)"
trap 'rm -rf "$A" "$B" "$C" "$D" "$BIN" "$E"' EXIT
cat > "$BIN/glab" <<EOF
#!/usr/bin/env bash
if [ "\$1" = auth ] && [ "\$2" = status ]; then
  for a in "\$@"; do [ "\$a" = --hostname ] && exit 0; done
  exit 1
fi
if [ "\$1" = issue ] && [ "\$2" = list ]; then exit 0; fi
if [ "\$1" = issue ] && [ "\$2" = create ]; then
  n=\$(( \$(cat "$BIN/n" 2>/dev/null || echo 200) + 1 )); echo "\$n" > "$BIN/n"
  echo "https://gitlab.example.com/grp/repo/-/issues/\$n"; exit 0
fi
if [ "\$1" = label ] && [ "\$2" = list ]; then echo "[]"; exit 0; fi
exit 0
EOF
chmod +x "$BIN/glab"
mk "$E"
( cd "$E" && git remote add origin 'ssh://git@gitlab.example.com:2222/grp/repo.git' )
# SAFETY FIRST: LOOP_ASSUME_YES alone must NOT create issues on a remote instance.
out7="$( cd "$E" && PATH="$BIN:$PATH" LOOP_TRACKER_ANSWER=gitlab LOOP_ASSUME_YES=1 \
         "$SETUP" </dev/null 2>&1 )" || fail "gitlab sweep run exited non-zero"
printf '%s\n' "$out7" | grep -qi 'import candidate' \
  || fail "the sweep did not run in gitlab mode (criterion 7)"
printf '%s\n' "$out7" | grep -q 'whats_next.md' \
  || fail "the gitlab-mode sweep did not reach the repo-root candidate"
printf '%s\n' "$out7" | grep -q 'set LOOP_IMPORT_REMOTE=1' \
  || fail "unattended remote import was neither performed nor explained"
grep -qE '^import\|' "$E/config/loop-setup-state.md" \
  && fail "LOOP_ASSUME_YES alone created remote issues without LOOP_IMPORT_REMOTE"

# With the explicit opt-in, the sweep creates through the glab backend and records the real iid.
out8="$( cd "$E" && PATH="$BIN:$PATH" LOOP_ASSUME_YES=1 LOOP_IMPORT_REMOTE=1 \
         "$SETUP" </dev/null 2>&1 )" || fail "opted-in gitlab sweep exited non-zero"
grep -qE '^import\|whats_next\.md\|(imported|archived)\|[0-9-]+\|#[0-9]+\|[0-9]+$' \
  "$E/config/loop-setup-state.md" \
  || fail "the gitlab sweep did not record a verdict, a numeric iid, and a fingerprint"
[ -d "$E/docs/issues" ] && [ -n "$(ls -A "$E/docs/issues" 2>/dev/null)" ] \
  && fail "gitlab mode wrote local issue files instead of creating remote issues"

# ---------- the subject moving reopens a settled decision ----------
G="$(mktemp -d)"; trap 'rm -rf "$A" "$B" "$C" "$D" "$BIN" "$E" "$F" "$G"' EXIT
mk "$G"
( cd "$G" && LOOP_TRACKER_ANSWER=local LOOP_SWEEP_ANSWER=y LOOP_ASSUME_NO=1 "$SETUP" </dev/null >/dev/null 2>&1 ) \
  || fail "G first run failed"
out9="$( cd "$G" && LOOP_SWEEP_ANSWER=y LOOP_ASSUME_NO=1 "$SETUP" </dev/null 2>/dev/null )" \
  || fail "G unchanged re-run exited non-zero"
printf '%s\n' "$out9" | grep -q 'whats_next.md' && fail "an unchanged declined candidate was re-offered"

printf '\nsomething new was added to this file\n' >> "$G/whats_next.md"
out10="$( cd "$G" && LOOP_SWEEP_ANSWER=y LOOP_ASSUME_NO=1 "$SETUP" </dev/null 2>/dev/null )" \
  || fail "G changed-subject run exited non-zero"
printf '%s\n' "$out10" | grep -q 'whats_next.md' \
  || fail "editing a declined candidate did not reopen the decision (the subject moved)"
printf '%s\n' "$out10" | grep -q 'docs/some-plan.md' \
  && fail "an untouched sibling candidate was reopened along with the changed one"

# ---------- the same rule applies to the config decision ----------
printf '\nhand-edited line\n' >> "$G/config/repo-state.md"
out11="$( cd "$G" && LOOP_ASSUME_NO=1 "$SETUP" </dev/null 2>/dev/null )" \
  || fail "G config-edit run exited non-zero"
printf '%s\n' "$out11" | grep -qi 'stale' \
  || fail "hand-editing a config with a declined re-render did not reopen the offer"

# ---------- the gate question is asked ONCE, before any per-item offer ----------
F="$(mktemp -d)"; trap 'rm -rf "$A" "$B" "$C" "$D" "$BIN" "$E" "$F"' EXIT
mk "$F"
( cd "$F" && LOOP_TRACKER_ANSWER=local LOOP_ASSUME_NO=1 "$SETUP" </dev/null >/dev/null 2>"$F/err" )
grep -c 'review them?' "$F/err" | grep -qx 1 || fail "the sweep gate question was not asked exactly once"
grep -qF 'import|' "$F/config/loop-setup-state.md" \
  && fail "a declined GATE recorded per-item verdicts (the gate must record nothing)"

echo "PASS: loop-setup re-run idempotence"
```

- [ ] **Step 2: Run it.**
      `bash tests/loop-setup/idempotence.sh`
      Expect FAIL with `sweep did not reach the repo-root whats_next.md`, because `reconcile_import` scans only `docs`, `.planning`, `.ralph`, and `.scratch/*/issues`.

- [ ] **Step 3: Implement.**
      Edit `skills/loop-setup/setup.sh` only (plus the two test files named below).

  a. Add near the top, after `version_of`:
     ```
     SETUP_VERSION=2       # current loop-setup bundle version; bump on every release
     SWEEP_CHANGED_AT=2    # last SETUP_VERSION at which import-sweep logic changed
     LEDGER="config/loop-setup-state.md"
     ```
     The config consumer's changed-at is not a constant here: it is the template's own `template-version`, read via `version_of "$TPL"`.

  b. Add the ledger helpers.
     `repo_version` prints, in order of preference: the ledger's `loop-setup-version:` value, else `config/repo-state.md`'s `template-version:` value, else `0`.
     `ledger_init` creates the file with a header if absent:
     ```
     # loop-setup state

     Machine-written by loop-setup. Do not hand-edit.
     Delete this file to re-open every decision it records.

     loop-setup-version: 0

     ## Import decisions
     ```
     ```bash
     fp() { [ -f "$1" ] && cksum < "$1" | awk '{print $1}' || printf '%s' '-'; }
     ledger_settled() {   # kind key fingerprint -> 0 when a record exists AND its fingerprint matches
       local line
       line="$(grep -F "$1|$2|" "$LEDGER" 2>/dev/null | head -1)" || return 1
       [ -n "$line" ] || return 1
       [ "${line##*|}" = "$3" ]
     }
     ledger_record() {    # kind key verdict ref fingerprint -> replace in place, never append
       local tmp; tmp="$(mktemp)"
       grep -vF "$1|$2|" "$LEDGER" 2>/dev/null > "$tmp" || true
       printf '%s|%s|%s|%s|%s|%s\n' "$1" "$2" "$3" "$(date +%F)" "$4" "$5" >> "$tmp"
       mv "$tmp" "$LEDGER"
     }
     ```
     `ledger_set_version <n>` rewrites the single `loop-setup-version:` line in place.
     Leave a `# ponytail:` comment noting that `|` is the field delimiter, so a candidate path containing a literal `|` is not supported, and naming `printf %q` as the upgrade path.

     Note that `ledger_record` rewrites the whole file, so the `loop-setup-version:` line and the header must survive the `grep -vF` filter; they do, because neither contains `<kind>|<key>|`.

  c. Capture the version once, before any consumer runs, near the mode-resolution block:
     `RV="$(repo_version)"`.

  d. Gate `reconcile_config` on both triggers, measuring staleness against the **config file itself** as well as the ledger.
     A version-only gate would mean a config restored from an older render, hand-edited, or badly merged is never reported stale, because the ledger would still read `2`.

     ```bash
     cv="$(version_of config/repo-state.md)"
     # trigger 1: a version moved. trigger 2: the file is stale AND no decision covers it as it stands now.
     if [ "$RV" -ge "$tv" ] 2>/dev/null && { [ "$cv" = "$tv" ] || ledger_settled config repo-state.md "$(fp config/repo-state.md)"; }; then
       return 0
     fi
     ```

     Keep the diff, the destructive-replace warning, and the `ask` exactly as they are.
     Change the announcement to `config/repo-state.md is stale (file at template-version '${cv:-none}', template at '$tv'); proposed re-render:`.
     On accept, after writing the file, `ledger_record config repo-state.md rendered - "$(fp config/repo-state.md)"`.
     On decline, `ledger_record config repo-state.md declined - "$(fp config/repo-state.md)"`, fingerprinting the file **as it stands declined**, so editing it afterwards reopens the offer.

  e. Rework `reconcile_import` into the universal sweep.
     - Add the repo root as a non-recursive root: collect `*.md` at depth 1 via a separate `find . -maxdepth 1 -type f -name '*.md'` pass, merged with the existing recursive `find` over the other roots.
     - **Normalize every path with `f="${f#./}"` before `is_excluded`, `ledger_settled`, and `ledger_record`.**
       The root pass yields `./whats_next.md` while the recursive pass yields `docs/some-plan.md`; without normalization the ledger records the same file under two spellings and re-offers work already decided.
       Ledger keys are always repo-relative with no leading `./`.
     - Extend `is_excluded`: add `config/loop-setup-state.md` so the ledger never offers itself, and add these root basenames, which are project documents rather than issue candidates:
       `README.md`, `CLAUDE.md`, `AGENTS.md`, `PLAN.md`, `CHANGELOG.md`, `LICENSE.md`, `CONTRIBUTING.md`.
       Measured in this repo, the root pass without these exclusions surfaces `PLAN.md` by filename keyword and `fixing-agent-errors.md` by content shape, taking the candidate count from 6 to 9.
       `fixing-agent-errors.md` is deliberately still offered: it is a repo-specific document, not a conventional project file, and declining it is one keystroke that the ledger then makes permanent.
     - Build the candidate list first, dropping anything `ledger_settled import "$f" "$(fp "$f")"` already covers.
       A candidate whose recorded fingerprint no longer matches its content is **not** dropped: the file changed, so the decision no longer describes it.
       When `[ "$RV" -lt "$SWEEP_CHANGED_AT" ]`, skip the drop entirely and re-offer every candidate, superseding prior verdicts.
     - When the filtered list is empty, return without printing an offer.
     - Otherwise ask the single gate question `found N import candidates - review them?` exactly once.
       Answer resolution for this one question is `LOOP_SWEEP_ANSWER` first (`y` accepts, anything else declines), falling through to the existing `ask` when the variable is unset.
       A declined gate records nothing and returns, so the gate is asked again next run.
     - For each candidate, print the existing `import candidate: <path> (title: <title>, label: <label>)` line and ask per item, exactly as today.
     - **The per-item confirmation is not satisfied by `LOOP_ASSUME_YES` alone when `MODE` is `github` or `gitlab`.**
       Until now the worst an unattended sweep could do was write local markdown; ungating it means a single `LOOP_ASSUME_YES=1` files an issue per candidate on a shared corporate instance, which in this repo is 9 issues and in forge is the `university-advancement` group.
       Remote creation additionally requires `LOOP_IMPORT_REMOTE=1`; without it, a `LOOP_ASSUME_YES` run in a remote mode prints `skipping remote import of <path> (set LOOP_IMPORT_REMOTE=1 to allow unattended remote creation)` and records nothing, so the candidate is offered again next run.
       Local mode is unaffected.
     - On accept, guard the create - the code being replaced has `&& echo "imported $f"` and the rewrite must not lose it:
       ```bash
       num="$(scripts/tracker.sh create --label "$label" --title "$title" --body "$body")" \
         || { echo "create failed for $f; leaving it unrecorded" >&2; continue; }
       [ -n "$num" ] || { echo "create returned no issue number for $f; leaving it unrecorded" >&2; continue; }
       ledger_record import "$f" imported "#$num" "$(fp "$f")"
       ```
       Recording a failed create as `imported` would permanently claim work that does not exist; on a shared instance a create can fail for label, permission, or rate reasons partway through a multi-candidate sweep.
     - Then ask `move <path> to docs/archive/?`; on accept `mkdir -p docs/archive` and `git mv` when the file is tracked else `mv`, then `ledger_record import "docs/archive/<basename>" archived "#$num" "$(fp docs/archive/<basename>)"` **and** re-record the original path as `archived` so the old key does not read as a live import.
     - On decline: `ledger_record import "$f" declined - "$(fp "$f")"`.
     - Keep the frontmatter-versus-prose title and label extraction unchanged.
     - The create call is backend-agnostic because it routes through `scripts/tracker.sh`, so the sweep needs no per-mode branch of its own beyond the `LOOP_IMPORT_REMOTE` gate.

  f. Remove the `[ "$MODE" = local ]` gate at line 240 so `reconcile_import` runs in every mode.

  g. At the very end of the script, after `"$TIDY"`, and only if every prior step succeeded, call `ledger_set_version "$SETUP_VERSION"`.
     Then replace the final `echo "loop-setup complete"` with a summary, tracked by a counter that `reconcile_config` and the sweep each increment when they make an offer.
     When the counter is zero, print
     `loop-setup complete - nothing to do (repo at loop-setup-version <n>, <k> decisions on file)`.
     The decision count is `grep -c '|' "$LEDGER"` minus the header, and it exists so quiet is a statement rather than an absence: the brief asks for "finds nothing to do and **says so**", and a run that has silently accumulated decisions should say how many it is sitting on.

  h. Do not edit `config/repo-state.template.md` in this task.
     The ledger's lane row is added by Task 6, which owns the doc sweep.
     The ledger works without being declared in the lane table; declaring it is documentation, not wiring.

  i. Update `tests/loop-setup/reconcile.sh`.
     Its two `grep -q '^template-version:'` assertions on rendered configs still hold, because the stamp is still rendered into the config.

     Its **decline-then-accept sequence at lines 105-113 breaks**, and this is a deliberate behavior change rather than a test to paper over.
     That sequence declines in `$S` with `LOOP_ASSUME_NO=1`, then re-runs the same sandbox with `LOOP_ASSUME_YES=1` and expects the re-render to happen.
     Under the new rule, the decline is recorded against the config's fingerprint, and the second run finds the subject unchanged and stays quiet, so the `diff "$REF/..." "$S/..."` never matches.

     The original decline semantics came from `docs/plans/2026-08-07-loop-setup-reconcile-plan.md:194`, where "decline" meant **the file is not mutated** - a file-safety property, not a promise to re-ask.
     That property is untouched here; only the re-ask is.

     Fix the test by making the accept scenario a decision on a moved subject rather than a repeat of the same question: between the two runs, delete `config/loop-setup-state.md` in `$S`.
     Add a comment stating why, and keep the byte-identical assertion after the decline exactly as it is, since that is the property the grandparent plan was actually protecting.

  j2. Add to `tests/repo-state/config.sh` an assertion that `.gitignore` does **not** list `config/loop-setup-state.md`, mirroring in reverse the existing `docs/chain-state.md` assertion.
     The ledger is committed; a repo that lost it on clone would re-offer and re-import every candidate, duplicating issues on the remote with no dedupe.

  j. Update `tests/loop-setup/import.sh`.
     Its `LOOP_ASSUME_YES=1` scenarios accept the new gate and are unaffected.
     Every `LOOP_ASSUME_NO=1` scenario that asserts on per-item offer output must gain `LOOP_SWEEP_ANSWER=y`, because a bare `LOOP_ASSUME_NO=1` now declines the gate and no item is ever offered.
     Add one assertion to the accept-all scenario that `config/loop-setup-state.md` records a verdict for every offered candidate, and update the header comment to say the sweep is no longer local-mode-only.

- [ ] **Step 4: Run it.**
      `bash tests/loop-setup/idempotence.sh` - expect PASS.
      Then `bash tests/loop-setup/import.sh`, `bash tests/loop-setup/reconcile.sh`, `bash tests/loop-setup/acceptance.sh`, `bash tests/loop-setup/gitlab-setup.sh` - expect PASS.

- [ ] **Step 5: Commit.**
      ```bash
      git add skills/loop-setup/setup.sh tests/loop-setup/idempotence.sh \
              tests/loop-setup/import.sh tests/loop-setup/reconcile.sh
      git commit -m "loop-setup: single repo version, decision ledger, and a universal import sweep"
      ```

---

### Task 5: `migrate-tracker.sh` gitlab target, offered during setup

Depends on: Task 4

**Files (exclusive ownership):**

- Modify: `scripts/migrate-tracker.sh`
- Modify: `skills/loop-setup/setup.sh` (add the migration offer only)
- Test: `tests/repo-state/migrate-gitlab.sh` (create)

**Interfaces:**

Consumes, from Task 1: `scripts/tracker.sh mode set gitlab`, `scripts/tracker.sh host`.
Consumes, from Task 4: the ledger helpers, for recording that migration was offered.

Produces:

- `scripts/migrate-tracker.sh [--to github|gitlab]`, defaulting to `github` so every existing invocation behaves identically.
- The same operation offered from `setup.sh` when the declared mode is `local` and `docs/issues/` is non-empty, declinable, and recorded in the ledger as `migrate|offered|<date>` so it is not re-offered until the version moves.

**Acceptance check:** `bash tests/repo-state/migrate-gitlab.sh` exits 0 `[executed-check]`

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

# --- the default target is still github (no behavior change for existing callers) ---
out2="$( cd "$SB" && MIGRATE_DRY_RUN=1 "$M" 2>&1 )" || true
printf '%s\n' "$out2" | grep -q 'glab issue create' && fail "the default target became gitlab"

# --- an unknown target is rejected ---
( cd "$SB" && MIGRATE_DRY_RUN=1 "$M" --to bitbucket >/dev/null 2>&1 ) && fail "an unknown target was accepted"

# ---------- criterion 10: the identical operation is OFFERED during loop-setup and is declinable ----------
SETUP="$REPO/skills/loop-setup/setup.sh"
mkls() {   # $1 = dir; a local-mode repo with one local issue and a gitlab remote
  mkdir -p "$1/docs/issues"
  ( cd "$1" && git init -q && git remote add origin 'ssh://git@gitlab.example.com:2222/grp/repo.git' )
  cat > "$1/docs/issues/001-thing.md" <<'EOS'
---
number: 1
title: a local thing
labels: idea
state: open
updated: 2026-08-01T00:00:00Z
---
body
EOS
}

# declined: nothing migrates, the mode stays local, and the standalone command is named
P="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB" "$P"' EXIT
mkls "$P"
out3="$( cd "$P" && LOOP_TRACKER_ANSWER=local LOOP_ASSUME_NO=1 "$SETUP" </dev/null 2>&1 )" \
  || fail "setup with a migration offer exited non-zero"
printf '%s\n' "$out3" | grep -q 'migrate 1 local issues to gitlab' \
  || fail "loop-setup did not offer the migration (criterion 10)"
printf '%s\n' "$out3" | grep -q 'scripts/migrate-tracker.sh --to gitlab' \
  || fail "the offer did not name the identical standalone command (criterion 10)"
[ "$(grep '^tracker:' "$P/config/repo-state.md")" = "tracker: local" ] \
  || fail "a DECLINED migration offer still flipped the mode"
grep -q '^migrated:' "$P/docs/issues/001-thing.md" && fail "a declined migration still created issues"
grep -qF 'migrate|gitlab|offered|' "$P/config/loop-setup-state.md" \
  || fail "the declined migration offer was not recorded in the ledger"

# a declined offer is not re-offered on the next run
out4="$( cd "$P" && "$SETUP" </dev/null 2>&1 )" || fail "post-decline setup re-run exited non-zero"
printf '%s\n' "$out4" | grep -q 'migrate 1 local issues' && fail "the migration offer was repeated after a decision"

# accepted: the identical operation runs, with the same result as the standalone command
Q="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB" "$P" "$Q"' EXIT
mkls "$Q"
( cd "$Q" && LOOP_TRACKER_ANSWER=local LOOP_ASSUME_YES=1 "$SETUP" </dev/null >/dev/null 2>&1 ) \
  || fail "accepted migration offer exited non-zero"
[ "$(grep '^tracker:' "$Q/config/repo-state.md")" = "tracker: gitlab" ] \
  || fail "an accepted migration offer did not flip the mode to gitlab"
grep -q '^migrated: https://gitlab.example.com' "$Q/docs/issues/001-thing.md" \
  || fail "an accepted migration offer did not migrate the local issue"
# The nested "git rm the migrated ledger file(s)?" question is a SEPARATE destructive decision.
# setup.sh strips LOOP_ASSUME_* before invoking the migration, so one "yes" to "migrate?" must
# not also stage deletion of every local issue file.
[ -f "$Q/docs/issues/001-thing.md" ] || fail "the migrated ledger file was deleted from disk"
( cd "$Q" && git diff --cached --name-only 2>/dev/null | grep -q 'docs/issues/001-thing.md' ) \
  && fail "one yes to 'migrate?' auto-accepted the nested destructive git rm prompt"

# ---------- --dry-run-remote must never fire the migration offer ----------
R="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB" "$P" "$Q" "$R"' EXIT
mkls "$R"
: > "$BIN/glab.calls"
out6="$( cd "$R" && LOOP_TRACKER_ANSWER=local LOOP_ASSUME_YES=1 \
         "$SETUP" --dry-run-remote </dev/null 2>&1 )" || fail "dry-run-remote run exited non-zero"
printf '%s\n' "$out6" | grep -qi 'migrate 1 local issues' \
  && fail "--dry-run-remote offered a migration, and LOOP_ASSUME_YES would have executed it"
grep -q 'GLAB CALLED: issue create' "$BIN/glab.calls" \
  && fail "--dry-run-remote created real issues (the flag means make no remote calls)"
grep -q '^migrated:' "$R/docs/issues/001-thing.md" \
  && fail "--dry-run-remote migrated a local issue"

# a local repo with NO remote is never offered a migration
N="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB" "$P" "$Q" "$R" "$N"' EXIT
mkdir -p "$N/docs/issues"; ( cd "$N" && git init -q )
cp "$Q/docs/issues/001-thing.md" "$N/docs/issues/001-thing.md"
sed -i.bak '/^migrated:/d; s/^state: migrated/state: open/' "$N/docs/issues/001-thing.md"
out5="$( cd "$N" && LOOP_TRACKER_ANSWER=local LOOP_ASSUME_YES=1 "$SETUP" </dev/null 2>&1 )" \
  || fail "remoteless local setup exited non-zero"
printf '%s\n' "$out5" | grep -qi 'migrate .* local issues' \
  && fail "a remoteless repo was offered a migration with nowhere to migrate to"

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

  e2. Add `migrate-tracker.sh` to the scripts `setup.sh` vendors into the target repo.
     `setup.sh` currently copies and drift-refreshes only `gen-mirrors.sh`, `tracker.sh`, and `graduate-parking.sh` (lines 51-87), so step (f)'s `scripts/migrate-tracker.sh` would resolve to a path that does not exist in any repo loop-setup has set up.
     Add a `MIG="$REPO/scripts/migrate-tracker.sh"` resolution with the same `[ -x ]` check, the same skip-if-exists copy, and a fourth entry `"migrate-tracker.sh:$MIG"` in the drift-refresh `for pair` loop.
     This must land **before** step (f), or the offer is unrunnable.

  f. In `skills/loop-setup/setup.sh`, after the sweep and before `"$TIDY"`, add the migration offer.
     It fires only when **all** of these hold:
     - `docs/issues/` holds at least one `*.md` whose `state:` is not already `migrated`
     - `origin` exists and `remote_kind` is `github` or `gitlab`; `target` is `remote_kind`
     - **`DRY_REMOTE` is 0**
     - `ledger_settled migrate "$target" -` is false, or `RV` is behind `SWEEP_CHANGED_AT`

     The trigger is **local issue files plus a remote**, deliberately not `MODE = local`.
     Task 3's g2 lets a user switch a repo from `local` to `gitlab` in the same run; keying on `MODE = local` would then skip the migration offer at exactly the moment it is most needed, silently stranding every existing `docs/issues/*.md` outside the tracker the repo now points at.
     Whether they accepted the switch or declined it, the unmigrated local issues and the remote both still exist, and that is the condition the offer is about.

     The `DRY_REMOTE` condition is not optional.
     `--dry-run-remote` means "make no remote calls" - it is why the github and gitlab finalizes are already gated on it - and without this condition a `--dry-run-remote` run on any local repo with issues would offer, and under `LOOP_ASSUME_YES=1` execute, real `gh label create` and `gh issue create`.
     Under dry-run, echo `dry-run-remote: skipping the migration offer`.

     A `remote_kind` of `other` or `none` skips the offer silently: there is nowhere to migrate to.
     It prints `preview: scripts/migrate-tracker.sh --to <target>` followed by that command's `MIGRATE_DRY_RUN=1` output, then asks `migrate <n> local issues to <target> now? (declining leaves them local; scripts/migrate-tracker.sh --to <target> runs the identical operation later)`.

     On accept, invoke it with the inherited blanket answers stripped:
     ```bash
     env -u LOOP_ASSUME_YES -u LOOP_ASSUME_NO scripts/migrate-tracker.sh --to "$target"
     ```
     `migrate-tracker.sh` asks its own question at the end - `git rm the N migrated ledger file(s)?` - and that is a distinct, destructive decision about deleting every local issue file.
     Passing `LOOP_ASSUME_YES` straight through would let one "yes" to "migrate?" silently stage those deletions too.
     Stripping the variables makes the second question be asked on its own merits.

     Either way, `ledger_record migrate "$target" offered - -`, so a decision is never re-offered until the version moves.

- [ ] **Step 4: Run it.**
      `bash tests/repo-state/migrate-gitlab.sh` - expect PASS.
      Then `bash tests/repo-state/migrate.sh`, `bash tests/repo-state/migrate-unlabeled.sh`, `bash tests/loop-setup/idempotence.sh` - expect PASS.

- [ ] **Step 5: Commit.**
      ```bash
      git add scripts/migrate-tracker.sh skills/loop-setup/setup.sh tests/repo-state/migrate-gitlab.sh
      git commit -m "migrate-tracker: --to gitlab target, offered and declinable during loop-setup"
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
- Modify: `config/repo-state.md` (this repo's own config: backfill to template-version 2, add the ledger lane)
- Modify: `config/repo-state.template.md` (add the `config/loop-setup-state.md` lane row only)
- Test: `tests/loop-setup/docs-gitlab.sh` (create)

**Interfaces:**

Consumes: the finished behavior of Tasks 1 through 5.
Produces: no code surface; this task exists so the documentation stops asserting github-only behavior that is no longer true.

**Acceptance check:** `bash tests/loop-setup/docs-gitlab.sh` exits 0 `[executed-check]`

- [ ] **Step 1: Write the failing test.**
      Create `tests/loop-setup/docs-gitlab.sh` with exactly this content:

```bash
#!/usr/bin/env bash
# The docs no longer assert github-only behavior, the triage reference exists and is pointed at,
# this repo's own config is at the current template-version, and the ledger lane is declared.
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

# loop-setup SKILL.md documents all three modes and points at the triage reference
for w in github gitlab local; do
  grep -q "$w" "$SK" || fail "loop-setup SKILL.md does not mention $w"
done
grep -q 'references/import-triage.md' "$SK" || fail "SKILL.md does not point at the triage reference"
grep -q 'loop-setup-state.md' "$SK" || fail "SKILL.md does not document the decision ledger"
grep -q 'LOOP_SWEEP_ANSWER' "$SK" || fail "SKILL.md does not document the LOOP_SWEEP_ANSWER hook"
grep -q 'LOOP_IMPORT_REMOTE' "$SK" \
  || fail "SKILL.md does not document the LOOP_IMPORT_REMOTE guard on unattended remote creation"
grep -q 'LOOP_TRACKER_ANSWER=gitlab' "$SK" || fail "SKILL.md does not document the gitlab non-interactive answer"
grep -qi 'but the remote is' "$SK" || fail "SKILL.md does not document the mode-switch offer"
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

# this repo's own config is current and declares the ledger lane
grep -q '^template-version: 2$' "$CFG" || fail "config/repo-state.md is not at template-version 2"
grep -q 'loop-setup-state.md' "$CFG"   || fail "config/repo-state.md does not declare the ledger lane"
grep -q 'loop-setup-state.md' "$TPL"   || fail "the template does not declare the ledger lane"
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

  b. `config/repo-state.template.md`: add one lane row, `| Setup state | `config/loop-setup-state.md` | Machine-written by loop-setup; delete to re-open decisions. |`.
     Do not touch anything else in this file; Task 3 owns the rest of it.

  c. `config/repo-state.md` (this repo): bring it to the current render.
     Add `template-version: 2` above the `Remote:` line, add the ledger lane row, add the `backlog-group:` line with an empty-or-`n/a` value appropriate for a github repo, add the gitlab backlog-view lines, and widen the two "github or local" sentences to name gitlab.
     **Also rewrite its Local-tracker lines 56 and 58-60**, which the earlier draft of this task missed: line 56's `wayfinder requires \`tracker: github\`` and the "Migration to GitHub" paragraph both still assert github-only behavior.
     This is the file an agent orienting in the repo actually reads, so leaving it stale would have it contradict both the template and `skills/wayfinder/SKILL.md` while the test still passed.
     Match the template's new wording exactly in all four places.
     Do not change `tracker: github`.

  d. `skills/loop-improve/SKILL.md:60-61`: state that `tracker.sh list` returns gh-shaped JSON in all three modes, and add the gitlab read path `glab issue view N` next to the existing `gh issue view N` and `docs/issues/NNN-*.md`.

  e. `skills/loop-review/SKILL.md:40`: add the gitlab equivalent, so the line reads that the referenced issue is fetched with `gh issue view <n>` in github mode or `glab issue view <n>` in gitlab mode, when that CLI is available and authenticated.

  f. Create `skills/loop-setup/references/import-triage.md`.
     It carries the split-and-merge judgment the brief assigned to prose rather than to bash, and it is the only home for that judgment.
     Contents, in the house style, one sentence per line:
     - The rule: one issue names one actionable item; a proposal spanning two unrelated items is wrong and gets split before anything is created.
     - When to split: a candidate file is a list, its sections are independently actionable, or its title needs an "and" to describe it.
     - When to merge: two candidates restate the same work, or one is strictly a subset of the other; merge into the one with the better restart context and record the other as declined.
     - When to leave: the file is reference material, a log, or a completed record; decline it, which is a recorded decision, not a deferral.
     - Titling: the title is the action, in the imperative, readable without the body.
     - Labelling: `idea` for anything parked by decision; no label for active work; the `idea` label is the one load-bearing label.
     - The disclosure requirement: every proposed split is shown to the human with its proposed titles before any issue is created, because this is criterion 13 of the source brief and it is a judgment, not a check.

  g. `skills/loop-setup/SKILL.md`: update it to describe what now exists.
     Add the `gitlab` finalize alongside github and local, quote the four exact `report_remote` strings, document the mode-switch offer when a declared mode disagrees with the remote, document all three non-interactive hooks (`LOOP_TRACKER_ANSWER=gitlab`; `LOOP_SWEEP_ANSWER=y|n` for the sweep gate only; `LOOP_IMPORT_REMOTE=1`, required alongside `LOOP_ASSUME_YES` before an unattended run may create issues on a remote backend), describe the decision ledger and the single `loop-setup-version` with its per-consumer changed-at constants, describe the sweep's gate-then-per-item shape and its repo-root scan, describe the declinable archive move and the declinable migration offer, and link `references/import-triage.md` as the home of the split-and-merge judgment.
     Keep it short; detail belongs in the reference file.

- [ ] **Step 4: Run it.**
      `bash tests/loop-setup/docs-gitlab.sh` - expect PASS.
      Then `bash tests/repo-state/config.sh` - expect PASS, proving the template and this repo's config still declare the same lane set.

- [ ] **Step 5: Commit.**
      ```bash
      git add skills/loop-setup/SKILL.md skills/loop-setup/references/import-triage.md \
              skills/wayfinder/SKILL.md skills/loop-improve/SKILL.md skills/loop-review/SKILL.md \
              config/repo-state.md config/repo-state.template.md tests/loop-setup/docs-gitlab.sh
      git commit -m "docs: gitlab as a peer backend across wayfinder, loop-improve, loop-review, and loop-setup"
      ```

---

### Task 7: Live forge smoke `[HUMAN CHECKPOINT - every write is the user's to fire]`

Depends on: Task 6

**Files (exclusive ownership):**

- Modify: `/home/jjrdar/claude/forge/config/repo-state.md` (via the tooling, not by hand)
- Create: `/home/jjrdar/claude/forge/config/loop-setup-state.md` (via the tooling)
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

      Expected, in order: `GitLab remote found: ssh://git@gitlab.code.rit.edu:2222/university-advancement/crm/forge.git - suggesting tracker: gitlab`; then, because forge already declares `tracker: local`, `declared tracker: local, but the remote is gitlab: <url>` and the offer to switch; a drift-refresh offer per vendored script; a config re-render offer that replaces `Remote: none (local tracker; see the Local tracker section)` with the real URL and adds `backlog-group: university-advancement`; then the import sweep's gate question naming `whats_next.md` among its candidates.

      If the mode-switch offer does not appear, stop: Task 3's g2 did not land, and everything downstream of it in forge is unreachable.

- [ ] **Step 3: Criterion 13 - the human judgment, before any issue exists.**
      Read `/home/jjrdar/claude/forge/whats_next.md` (7433 bytes) against `skills/loop-setup/references/import-triage.md`.
      Propose a split into issues, one actionable item each, and show the proposed titles to the user **before** creating anything.
      If any proposed issue spans two unrelated items, redo the split.
      The user approves the title list; only then do the per-item confirmations proceed.

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

      Expect exit 0.
      Both this top-level form and the subgroup form were confirmed working during planning, so a non-zero exit here means the derivation produced the wrong group, not that the approach is wrong: change Task 1's `gitlab_group` to keep all path segments except the last (`university-advancement/crm`) and re-render.

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

      Expect `loop-setup complete - nothing to do (repo at loop-setup-version 2)` and zero `import candidate:` lines.
      Then confirm the standalone migration path prints the identical operation without running it:

      ```bash
      cd /home/jjrdar/claude/forge
      MIGRATE_DRY_RUN=1 scripts/migrate-tracker.sh --to gitlab
      ```

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

      GitLab issue deletion requires owner rights and is not exposed by `glab issue`; if the user has them, delete via the API, one iid at a time, each confirmed:

      ```bash
      glab api --method DELETE "projects/:id/issues/<iid>"
      ```

      If deletion is unavailable or unwanted, rename each to mark it clearly instead:

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
      git add config/repo-state.md config/loop-setup-state.md scripts/ ISSUES.md BACKLOG.md
      git status --short
      git commit -m "loop-setup: adopt the gitlab tracker backend"
      ```

      Whether `whats_next.md` is archived, deleted, or kept is the user's call, recorded in forge's ledger by the sweep.
