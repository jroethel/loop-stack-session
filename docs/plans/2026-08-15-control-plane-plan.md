# Tracker as Control Plane Implementation Plan

> For executors: tasks use checkbox syntax; execute in dependency order; a task is done when its
> acceptance check passes. No specific tooling, harness, or skills are assumed.

**Goal:** Move the stack's spine from a session that must stay alive to a tracker that outlives sessions, with every transition to Done gated by executed-check evidence and every killed unit reclaimable from tracker + git alone.

**Approach:** Add the Open Engine control-plane shape (status labels, claim locks with an explicit reclaim path, a one-per-run queue runner that resurfaces stale work, run-state on tickets) through the existing `scripts/tracker.sh` backend seam so all three backends (github/gitlab/local) support it, and marry it to loop-stack's executed checks so `agent:done` requires proof, not a self-report. Reconciliation still trusts git over any state record (P11 unchanged).

**Tech stack:** POSIX-ish bash (bash 3.2 compatible, macOS), the `gh`/`glab` CLIs for remote backends, markdown files for the local backend, the existing PATH-stub test harness.

**Source brief:** `docs/briefs/2026-08-15-control-plane-brief.md`

**Rubix disposition (2026-08-15):** revised after a two-lens review (Lens A impacted-operator at Opus, Lens B cold-craft at Fable). The kill/resume path, the evidence-guard bypass doors, the remote-backend test gap, and the lint's archivable signal were all reworked here. The lint is grounded on **superseded + unlinked** (owner decision), not checkbox-completeness, because loop-drive never ticks plan checkboxes back (verified: the six real plans carry 0 checked / 20-40 unchecked boxes).

## Global constraints

- /workflows stays off (verified 2026-08-15); do not design around it.
- Portability is standing: the stack must run outside Claude Code; ringer is the spine, native primitives the optional lane.
- The control plane must work on the `local` tracker backend too - no hard remote dependency; it is the spine and must run anywhere.
- Ticket records stay portable prose: no Claude-Code-specific fields in any label, comment, or receipt.
- Do not worsen: the `~/repos/ringer` hardcode, absolute-path symlinks, `claude-zai.sh` env specifics, the /dev/tty question (#28), macOS/Linux/WSL differences.
- Single-home-plus-pointers is mandatory in anything touched: the status vocabulary is documented in exactly one place (`config/repo-state.md`) and pointed to elsewhere.
- Packaging comes later; do not restructure for distribution now.
- Fable is never spawned as a worker; effort capped at high.
- Never manually edit `docs/gate-registry.md` (generated) or any CHANGELOG.
- House style: plain `-` never the em dash; one sentence per physical line in prose; aligned pipe tables; plain commit messages with no co-author line.

## Dependency graph

```
Task 1 (tracker.sh: labels + comment)
   |
Task 2 (tracker.sh: claim + reclaim + status + done-guard)   [depends 1]
   |
Task 3 (tracker.sh: next-eligible incl. stale-working sweep)  [depends 1,2]
   |
   +--> Task 4 (queue-runner reference)             [depends 3]      \
   +--> Task 5 (run-state on tickets + kill-test)   [depends 2,3]     >  parallel wave, disjoint files
   +--> Task 6 (lifecycle lint, superseded+unlinked) [depends 2]     /
          |
Task 7 (integration: install, full suite, registry drift, kill demo, archive demo)  [depends 4,5,6]
```

Tasks 1-3 mutate the single file `scripts/tracker.sh` and therefore run strictly in sequence.
Tasks 4, 5, 6 own disjoint files and are the plan's only real parallel width (3-wide).

## Human checkpoints

- **Kill-test prose-follow (judgment):** the mechanical claim/reclaim/reconcile guarantees are executed-checks (Tasks 2, 5); whether a fresh session *following the prose queue-runner prompt* actually claims and relaunches the half-done unit is verified once as an explicit demo step in Task 7 (Step 4) and recorded as a human verdict.
- **Lint demo issue-closures (STOP, outward-facing):** the lint's acceptance demo archives the flagged plan-set files for real (in-worktree, git-revertible), but any real-GitHub issue **close** is outward-facing and not worktree-isolated. It is staged with the exact command for the owner to fire, never auto-fired (Task 7 Step 6). This is the owner-chosen scope from planning.
- **Merge gate:** nothing in this branch goes live until the owner fires the cycle-end merge gate from the main checkout; not an executor action.

## How to run

```
./install.sh                 # symlinks skills/* and scripts/*; picks up new subcommands automatically
tests/run.sh                 # full suite; must end "N passed, 0 failed"
tests/run.sh 2>&1 | grep -i tracker   # the control-plane suites specifically
scripts/gen-gate-registry.sh .        # regenerate the gate registry (drift check)
```

Backend note for every tracker test: the harness puts a fake `gh`/`glab` at the front of `PATH` that records each invocation to a call-log and mimics the CLI contract; local mode is proven CLI-free by asserting the call-log stayed empty. Copy this pattern from `tests/repo-state/tracker.sh` and `tests/repo-state/tracker-gitlab.sh`. **Every new tracker suite covers all three backends** - local for behavior, github + gitlab as stub-pinned call-contract assertions - because this repo runs `tracker: github` in production and a local-only test proves nothing about the path that actually runs.

---

## Task 1: Status labels + label/comment primitives

Depends on: none

**Files (exclusive ownership):**
- Modify: `scripts/tracker.sh` (add `label` and `comment` subcommand arms + usage lines)
- Test: `tests/repo-state/tracker-labels.sh` (create)

**Interfaces:**
- Produces (new `tracker.sh` subcommands, all dispatching `case "$mode"` in github/gitlab/local + `*) fail`):
  - `tracker.sh label ensure <name>` - idempotently make the label exist. github: `gh label create "<name>" 2>/dev/null || true`; gitlab: `glab label create --name "<name>" 2>/dev/null || true`; local: no-op (labels are frontmatter text, no registry) printing `note: local labels are frontmatter, nothing to ensure` to stderr, exit 0.
  - `tracker.sh label add <num> <name>` - attach a label. **Reject `agent:done`** with exit 6 and message `agent:done is reachable only through 'tracker.sh done' (evidence-gated)` - this closes the guard bypass. github: `gh issue edit <num> --add-label "<name>"`; gitlab: `glab issue update <num> --label "<name>"`; local: rewrite the `labels:` frontmatter line to include `<name>` (comma list, de-duplicated) and refresh `updated:`, inside the first frontmatter block only.
  - `tracker.sh label remove <num> <name>` - the inverse. github: `--remove-label`; gitlab: `glab issue update <num> --unlabel "<name>"`; local: drop `<name>` from the `labels:` list, refresh `updated:`.
  - `tracker.sh comment <num> <text>` - append a durable comment/receipt. github: `gh issue comment <num> --body "<text>"`; gitlab: `glab issue note <num> --message "<text>"`; local: append a line `> comment <ISO-8601-UTC>: <text>` after the body and refresh `updated:`. Receipts are prose consistent with the handoff skill's discipline (summary + redaction, no secrets), portable, no harness-specific fields.
- Consumes: the existing `tracker_mode_get`, `gh_guard`, `glab_guard`, `find_issue_file`, `local_set_state`'s frontmatter-rewrite pattern (awk over the first `---`..`---` block), `json_escape`.

**Reuse note:** the local `labels:`/`updated:` rewrite mirrors `local_set_state` (tracker.sh:118-129) exactly - one awk pass, `d==1` guard so only the first frontmatter block is touched, never a body line that happens to start `labels:`.

**Acceptance check:** `tests/repo-state/tracker-labels.sh` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test verbatim:

```bash
#!/usr/bin/env bash
# tracker.sh label + comment primitives across all three backends: local mutates frontmatter with
# zero gh/glab; github/gitlab emit the exact CLI calls; comment appends a durable receipt; and
# label add refuses agent:done (bypass closed). bash 3.2 safe.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; REPO="$(cd "$HERE/../.." && pwd)"; T="$REPO/scripts/tracker.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$T" ] || fail "scripts/tracker.sh missing or not executable"

BIN="$(mktemp -d)"; SB="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB"' EXIT
LOG="$BIN/cli.calls"
# fake gh/glab: 'auth' subcommand passes the guards, everything else is recorded (bash 3.2 safe)
cat > "$BIN/gh"  <<EOF
#!/usr/bin/env bash
[ "\$1" = auth ] && exit 0
echo "GH CALLED: \$*" >> "$LOG"; exit 0
EOF
cat > "$BIN/glab" <<EOF
#!/usr/bin/env bash
[ "\$1" = auth ] && exit 0
echo "GLAB CALLED: \$*" >> "$LOG"; exit 0
EOF
chmod +x "$BIN/gh" "$BIN/glab"; export PATH="$BIN:$PATH"
cd "$SB" && git init -q && mkdir -p config

# --- LOCAL backend: real frontmatter mutation, zero CLI ---
"$T" mode set local >/dev/null
n="$("$T" create --label agent:todo --title "Spine ticket" --body "do the thing")"
[ "$n" = "1" ] || fail "local create did not return #1"
f="docs/issues/001-spine-ticket.md"
"$T" label add 1 agent:working    || fail "label add failed"
grep -qE '^labels: .*agent:working' "$f" || fail "label add did not write agent:working to frontmatter"
"$T" label add 1 agent:working    # idempotent
[ "$(grep -o 'agent:working' "$f" | wc -l | tr -d ' ')" = "1" ] || fail "label add duplicated agent:working"
"$T" label remove 1 agent:todo    || fail "label remove failed"
grep -qE '^labels:.*agent:todo' "$f" && fail "label remove left agent:todo behind"
"$T" comment 1 "AGENT CLAIMED sess-x 2026-08-15T00:00:00Z" || fail "comment failed"
grep -q 'AGENT CLAIMED sess-x' "$f" || fail "comment did not append receipt to local body"
# bypass closed: label add refuses agent:done
"$T" label add 1 agent:done >/dev/null 2>&1; rc=$?
[ "$rc" -eq 6 ] || fail "label add agent:done was not rejected (rc=$rc)"
grep -qE '^labels:.*agent:done' "$f" && fail "rejected label add still wrote agent:done"
"$T" label ensure agent:review >/dev/null || fail "label ensure nonzero in local mode"
[ ! -s "$LOG" ] || { cat "$LOG"; fail "local mode touched gh/glab"; }

# --- GITHUB backend: exact CLI dispatch ---
: > "$LOG"; "$T" mode set github >/dev/null
"$T" label ensure agent:review  >/dev/null
"$T" label add 7 agent:review    >/dev/null
"$T" label remove 7 agent:todo   >/dev/null
"$T" comment 7 "receipt body"   >/dev/null
grep -q 'GH CALLED: label create agent:review'                "$LOG" || fail "github label ensure wrong call"
grep -q 'GH CALLED: issue edit 7 --add-label agent:review'    "$LOG" || fail "github label add wrong call"
grep -q 'GH CALLED: issue edit 7 --remove-label agent:todo'   "$LOG" || fail "github label remove wrong call"
grep -q 'GH CALLED: issue comment 7 --body receipt body'      "$LOG" || fail "github comment wrong call"

# --- GITLAB backend: exact CLI dispatch, incl. --unlabel ---
: > "$LOG"; "$T" mode set gitlab >/dev/null
git remote add origin 'ssh://git@gitlab.example.com:2222/grp/repo.git'
"$T" label ensure agent:review  >/dev/null
"$T" label add 7 agent:review    >/dev/null
"$T" label remove 7 agent:todo   >/dev/null
"$T" comment 7 "receipt body"   >/dev/null
grep -q 'GLAB CALLED: label create --name agent:review'       "$LOG" || fail "gitlab label ensure wrong call"
grep -q 'GLAB CALLED: issue update 7 --label agent:review'    "$LOG" || fail "gitlab label add wrong call"
grep -q 'GLAB CALLED: issue update 7 --unlabel agent:todo'    "$LOG" || fail "gitlab label remove wrong call"
grep -q 'GLAB CALLED: issue note 7 --message receipt body'    "$LOG" || fail "gitlab comment wrong call"

echo "PASS: label ensure/add/remove (+agent:done bypass closed) + comment across local, github, gitlab"
```

- [ ] Step 2: Run it - `bash tests/repo-state/tracker-labels.sh`, expected FAIL with an early usage/unknown-arg error (subcommands do not exist yet).
- [ ] Step 3: Implement the four subcommand arms in `scripts/tracker.sh` against the Interfaces contract; add usage() lines. Follow the existing arm shape (mode bound in parent scope, `case "$mode"` with `*) fail`). Reuse the `local_set_state` awk pattern for local frontmatter edits.
- [ ] Step 4: Run it - expected PASS.
- [ ] Step 5: Commit - `git add scripts/tracker.sh tests/repo-state/tracker-labels.sh && git commit -m "control-plane: tracker.sh label + comment primitives, three backends, agent:done bypass closed"`

---

## Task 2: Claim-lock, reclaim, status transition, and the close-guard

Depends on: Task 1

**Files (exclusive ownership):**
- Modify: `scripts/tracker.sh` (add `claim`, `status`, `done` subcommand arms + usage lines)
- Test: `tests/repo-state/tracker-claim-done.sh` (create)

**Interfaces:**
- Produces:
  - `tracker.sh status <num> <state>` where `state` in `todo|working|needs-input|review` - set exactly one active status: remove any other `agent:<other>` status label, then `label add <num> agent:<state>`. Remote clears the others by issuing a targeted `label remove` for each of the four sibling statuses (blind removes are safe and need no current-labels fetch); local edits the frontmatter list directly. `done` is NOT reachable through `status` (it routes through the guarded `done` below).
  - `tracker.sh claim <num> <session-id> [--reclaim]` - the Open Engine claim sequence, **receipt-before-flip** so a mid-claim death never leaves a receiptless working ticket:
    1. append `AGENT CLAIMED <session-id> <ISO-8601-UTC>` via `comment` (or, with `--reclaim`, `AGENT RECLAIMED <session-id> <ISO-8601-UTC>` - this resets the claim baseline, explicitly superseding a known-dead session's prior claims);
    2. `status <num> working`;
    3. re-read the issue and gather the **active** claim receipts (those at or after the most recent `AGENT RECLAIMED`, or all `AGENT CLAIMED` if none), anchored to line shape (`^> comment .*: AGENT CLAIMED` locally, comment bodies remotely) so a receipt merely quoting the phrase is not counted;
    4. the **owner** is the earliest active claim by timestamp, ties broken by lexicographically-least session-id. If the current session is the owner (or reclaimed), print the session-id, exit 0. Otherwise print `RACE: #<num> owned by <owner>` to stderr and exit 4; the losing session's receipt is inert history the owner ignores (no cleanup needed).
  - Remote re-read (step 3) fetches comments: github `gh issue view <num> --json comments -q '.comments[].body'`; gitlab `glab issue view <num> --comments` (or `glab issue note list`); local reads the issue file.
  - `tracker.sh done <num> --receipt <text> [--ran <cmd>]` - the guarded completion path.
    - If `--ran <cmd>` is given, execute `<cmd>`, capture its exit code, and append it to the receipt as `exit <code>` - real evidence, not a pasted claim; a nonzero captured exit routes to `status <num> review` (not done) and exits 7.
    - Otherwise validate `<text>`: it passes only if `printf '%s\n' "$text" | grep -qE '(exit( status)? 0( |$)|[0-9]+ passed|0 failed|https?://[^ ]+)'` - i.e. a zero exit, a passing test summary, or an artifact URL. A **failing** exit (`exit 1`) and an evidence-free receipt are both rejected (exit 5, message `agent:done requires executed-check evidence of a PASSING run (exit 0 / N passed / 0 failed / artifact link)`).
    - On pass: `comment <num> "<receipt>"`, clear the status label, `label add`-equivalent set of `agent:done` (via the internal path that bypasses the `label add` agent:done guard - the guard blocks the public verb, not this internal completion), then `close <num>`.
  - `close <num>` stays the unguarded human/manual path but its usage line is documented **human-only**; agents complete solely through `done`. Lint class (c) (Task 6) catches any ticket closed without an evidence receipt, so a human `close` that should have been an evidenced `done` is still surfaced.
- Consumes: Task 1's `label add/remove`, `comment`; the existing `close`, `find_issue_file`, `local_list`.

**Evidence rule (the P2 marriage):** the guard proves a receipt cites a PASSING run - a zero exit, a passing test summary, or an artifact link - or, with `--ran`, re-executes the cited command and captures the real exit. This is where loop-stack's executed checks fix Open Engine's `AGENT DONE` self-report weakness, with the three side doors (`label add agent:done`, a nonzero exit, a bare `close`) all closed or surfaced.
`# ponytail: without --ran, evidence is a regex proving a receipt CITES a passing run, not that it happened. --ran is the strong path (re-execute + capture). Upgrade: make --ran mandatory in autonomous queue-runner mode if forgery ever matters.`

**Acceptance check:** `tests/repo-state/tracker-claim-done.sh` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test verbatim:

```bash
#!/usr/bin/env bash
# claim (receipt-before-flip) + race (later claimer loses, exit 4) + reclaim takeover (exit 0);
# status enforces one active label; done REJECTS evidence-free AND failing-exit receipts, ACCEPTS a
# passing one, --ran re-executes; agent:done unreachable by side doors. Local behavior + github race stub.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; REPO="$(cd "$HERE/../.." && pwd)"; T="$REPO/scripts/tracker.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
BIN="$(mktemp -d)"; SB="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB"' EXIT
GHLOG="$BIN/gh.calls"
cat > "$BIN/gh" <<EOF
#!/usr/bin/env bash
echo "GH CALLED: \$*" >> "$GHLOG"; exit 1
EOF
chmod +x "$BIN/gh"; export PATH="$BIN:$PATH"
cd "$SB" && git init -q && mkdir -p config && "$T" mode set local >/dev/null

n="$("$T" create --label agent:todo --title "Claimable" --body "body")"; f="docs/issues/001-claimable.md"

# status enforces exactly one agent:* label
"$T" status 1 working || fail "status working failed"
grep -qE '^labels:.*agent:working' "$f" || fail "status did not set agent:working"
grep -qE '^labels:.*agent:todo'    "$f" && fail "status did not clear agent:todo"

# claim: receipt-before-flip, clean single claim exits 0 and leaves a receipt BEFORE working is set
"$T" create --label agent:todo --title "Second" --body "b" >/dev/null
sid="$("$T" claim 2 sess-A)" || fail "clean claim exited nonzero"
[ "$sid" = "sess-A" ] || fail "claim did not echo owner session id"
grep -q 'AGENT CLAIMED sess-A' docs/issues/002-second.md || fail "claim left no receipt"

# race: a LATER second claimer loses (exit 4); the earlier claimer remains owner
"$T" claim 2 sess-B >/dev/null 2>&1; rc=$?
[ "$rc" -eq 4 ] || fail "later claimer not rejected as race (rc=$rc)"

# reclaim: explicit takeover of a known-dead session succeeds (exit 0) and re-owns
own="$("$T" claim 2 sess-C --reclaim)" || fail "reclaim exited nonzero"
[ "$own" = "sess-C" ] || fail "reclaim did not take ownership"

# done-guard: evidence-free receipt REJECTED (exit 5), issue stays open
"$T" done 1 --receipt "did the work, looks good" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 5 ] || fail "evidence-free done not rejected (rc=$rc)"
grep -q '^state: open' "$f" || fail "rejected done closed the issue"
grep -qE '^labels:.*agent:done' "$f" && fail "rejected done applied agent:done"

# done-guard: a FAILING exit is REJECTED too (exit 5)
"$T" done 1 --receipt "ran tests; exit 1" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 5 ] || fail "failing-exit receipt not rejected (rc=$rc)"
grep -q '^state: open' "$f" || fail "failing-exit done closed the issue"

# done-guard: a PASSING receipt ACCEPTED - sets agent:done and closes
"$T" done 1 --receipt "ran tests/run.sh; exit 0" || fail "passing receipt rejected"
grep -qE '^labels:.*agent:done' "$f" || fail "evidenced done did not apply agent:done"
grep -q '^state: closed' "$f" || fail "evidenced done did not close the issue"

# --ran re-executes and captures the real exit: a passing command closes #2
"$T" status 2 working >/dev/null
"$T" done 2 --receipt "smoke" --ran 'true' || fail "done --ran with a passing command was rejected"
grep -q '^state: closed' docs/issues/002-second.md || fail "done --ran did not close on exit 0"
# --ran with a FAILING command routes to review (exit 7), does not close
n3="$("$T" create --label agent:working --title "Third" --body c)"
"$T" done 3 --receipt "smoke" --ran 'false' >/dev/null 2>&1; rc=$?
[ "$rc" -eq 7 ] || fail "done --ran with a failing command did not route to review (rc=$rc)"
grep -qE '^labels:.*agent:review' docs/issues/003-third.md || fail "failing --ran did not set agent:review"
grep -q '^state: closed' docs/issues/003-third.md && fail "failing --ran closed the issue"

[ ! -s "$GHLOG" ] || { cat "$GHLOG"; fail "local mode touched gh"; }

# --- GITHUB race stub: two AGENT CLAIMED comments -> a later claimer loses (exit 4) ---
BIN2="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB" "$BIN2"' EXIT
cat > "$BIN2/gh" <<'EOS'
#!/usr/bin/env bash
case "$1 $2" in
  "auth status") exit 0 ;;
esac
if [ "$1" = issue ] && [ "$2" = view ]; then
  # two prior claimers already on the remote issue
  printf '%s\n' "AGENT CLAIMED sess-EARLY 2026-08-15T00:00:00Z" "AGENT CLAIMED sess-LATE 2026-08-15T00:00:05Z"
  exit 0
fi
exit 0
EOS
chmod +x "$BIN2/gh"; PATH="$BIN2:$PATH" "$T" mode set github >/dev/null 2>&1 || true
# a fresh claimer that is neither of the priors and later than both must lose
PATH="$BIN2:$PATH" "$T" claim 9 sess-NEW >/dev/null 2>&1; rc=$?
[ "$rc" -eq 4 ] || fail "github: a later claimer over two existing claims did not lose (rc=$rc)"

echo "PASS: claim/reclaim/race, one-status, evidence-gated done (+ --ran, side doors closed), github race"
```

- [ ] Step 2: Run it - expected FAIL (subcommands absent).
- [ ] Step 3: Implement `status`, `claim` (with `--reclaim` and remote comment re-read), `done` (with `--ran`) in `scripts/tracker.sh` against the Interfaces + evidence rule; add usage() lines (mark `close` human-only); carry the ponytail evidence-ceiling comment.
- [ ] Step 4: Run it - expected PASS.
- [ ] Step 5: Commit - `git add scripts/tracker.sh tests/repo-state/tracker-claim-done.sh && git commit -m "control-plane: claim/reclaim lock, one-status, evidence-gated done with --ran (P2 guard)"`

---

## Task 3: next-eligible - stale-working sweep, then unblocked todo

Depends on: Task 1, Task 2

**Files (exclusive ownership):**
- Modify: `scripts/tracker.sh` (add `next-eligible` subcommand arm + usage line)
- Test: `tests/repo-state/tracker-eligible.sh` (create)

**Interfaces:**
- Produces:
  - `tracker.sh next-eligible [<session-id>]` - selects **at most one** actionable ticket, prints it and its reason, stops. Priority:
    1. **stale-working first** - a ticket in `agent:working` whose latest active claim/reclaim receipt is older than `STALE_CLAIM_SECS` (default 3600) and whose owner session differs from `<session-id>` (when given). This is the killed-unit resurfacing the whole kill/resume story depends on. Emit `SELECTED #<num>: stale working, relaunch`.
    2. else **unblocked todo** - open, `agent:todo`, not `agent:working`, lowest number first, whose body carries no unresolved `Blocked by: #M` (a blocker is unresolved iff `#M` is in the open-numbers set derived from `tracker.sh list`; a closed blocker never appears there). Emit `SELECTED #<num>: agent:todo, unblocked`.
    3. else `NONE ELIGIBLE: <why>`.
    Exit 0 in all three cases; it never selects more than one - the one-per-run stop is structural.
  - Algorithm detail: read `tracker.sh list` once for the open-set + labels; for a `todo` candidate, fetch ONLY that candidate's body (local: read `docs/issues/NNN-*.md`; github: `gh issue view <num> --json body -q .body`; gitlab: `glab issue view <num>`) and match `^Blocked by:` lines (anchored, body-section only). For stale detection, read the candidate's claim receipts (same anchored line shape as Task 2) and compare the newest timestamp to now.
  `# ponytail: STALE_CLAIM_SECS is a wall-clock heuristic for auto-resurfacing. Explicit 'claim --reclaim' is the operator's zero-wait override; tune the env if 1h is wrong for a given cadence.`
- Consumes: `tracker.sh list`, Task 2's receipt/claim conventions, the wayfinder `Blocked by: #N` grammar (single-homed, not reinvented).

**Acceptance check:** `tests/repo-state/tracker-eligible.sh` exits 0 `[executed-check]` - brief criterion 2 (three eligible, one run touches exactly one, reason recorded) plus the stale-working resurfacing.

- [ ] Step 1: Write the failing test verbatim:

```bash
#!/usr/bin/env bash
# next-eligible: picks exactly one unblocked todo (lowest number) with a reason; skips a blocked one;
# resurfaces a STALE agent:working ticket ahead of fresh todo; parses realistic multi-field gh JSON.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; REPO="$(cd "$HERE/../.." && pwd)"; T="$REPO/scripts/tracker.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
BIN="$(mktemp -d)"; SB="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB"' EXIT
GHLOG="$BIN/gh.calls"
cat > "$BIN/gh" <<EOF
#!/usr/bin/env bash
echo "GH CALLED: \$*" >> "$GHLOG"; exit 1
EOF
chmod +x "$BIN/gh"; export PATH="$BIN:$PATH"
cd "$SB" && git init -q && mkdir -p config && "$T" mode set local >/dev/null

"$T" create --label agent:todo --title "Alpha"   --body "work" >/dev/null   # #1
"$T" create --label agent:todo --title "Bravo"   --body "work" >/dev/null   # #2
"$T" create --label agent:todo --title "Charlie" --body "work" >/dev/null   # #3

out="$("$T" next-eligible)"; rc=$?
[ "$rc" -eq 0 ] || fail "next-eligible exited nonzero with eligible tickets"
[ "$(printf '%s\n' "$out" | grep -c '^SELECTED')" -eq 1 ] || fail "did not select exactly one"
printf '%s\n' "$out" | grep -q '^SELECTED #1:' || fail "did not select the lowest-number eligible (#1)"
printf '%s\n' "$out" | grep -qi 'todo' || fail "selection reason not recorded"

# a ticket blocked by an OPEN issue is skipped; claim #1/#2/#3 (fresh receipts, working, not stale)
"$T" create --label agent:todo --title "Delta" --body "Blocked by: #1" >/dev/null  # #4 blocked by open #1
"$T" claim 1 sess-old >/dev/null; "$T" claim 2 sess-old >/dev/null; "$T" claim 3 sess-old >/dev/null
# those three carry FRESH claims -> not stale; #4 is blocked -> nothing eligible this run
out2="$(STALE_CLAIM_SECS=3600 "$T" next-eligible sess-me)"
printf '%s\n' "$out2" | grep -q '^NONE ELIGIBLE' || fail "fresh-working + blocked queue did not report NONE"
printf '%s\n' "$out2" | grep -q '^SELECTED' && fail "selected a blocked or fresh-working ticket"

# STALE working resurfaces: backdate #2's claim receipt (no .bak left behind), then it is selected
tmp="$(mktemp)"
sed -E 's/AGENT CLAIMED sess-old [0-9T:Z-]+/AGENT CLAIMED sess-old 2000-01-01T00:00:00Z/' \
  docs/issues/002-bravo.md > "$tmp" && mv "$tmp" docs/issues/002-bravo.md
out3="$(STALE_CLAIM_SECS=3600 "$T" next-eligible sess-me)"
printf '%s\n' "$out3" | grep -q '^SELECTED #2: stale working' || fail "stale working ticket not resurfaced for relaunch"

[ ! -s "$GHLOG" ] || { cat "$GHLOG"; fail "local mode touched gh"; }

# --- GITHUB stub: realistic multi-field label JSON parses to the right lane ---
BIN2="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB" "$BIN2"' EXIT
cat > "$BIN2/gh" <<'EOS'
#!/usr/bin/env bash
[ "$1 $2" = "auth status" ] && exit 0
if [ "$1" = issue ] && [ "$2" = list ]; then
  cat <<'JSON'
[{"number":5,"title":"Echo","labels":[{"id":"a","name":"agent:todo","color":"ededed","description":""}],"updatedAt":"2026-08-15T00:00:00Z"}]
JSON
  exit 0
fi
if [ "$1" = issue ] && [ "$2" = view ]; then echo "no blockers here"; exit 0; fi
exit 0
EOS
chmod +x "$BIN2/gh"
out4="$(cd "$SB" && PATH="$BIN2:$PATH" "$T" mode set github >/dev/null 2>&1; PATH="$BIN2:$PATH" "$T" next-eligible)"
printf '%s\n' "$out4" | grep -q '^SELECTED #5: agent:todo' || fail "github multi-field JSON did not parse to a todo selection"

echo "PASS: next-eligible one-per-run, blockers honored, stale-working resurfaced, remote JSON parsed"
```

- [ ] Step 2: Run it - expected FAIL (subcommand absent).
- [ ] Step 3: Implement `next-eligible` against the contract. Parse `list` JSON with the existing no-jq brace-scan (cf. gen-mirrors.sh) so multi-field label objects do not break it; keep it bash-3.2 safe.
- [ ] Step 4: Run it - expected PASS.
- [ ] Step 5: Commit - `git add scripts/tracker.sh tests/repo-state/tracker-eligible.sh && git commit -m "control-plane: next-eligible with stale-working sweep, one-per-run stop"`

---

## Task 4: The queue-runner reference prompt

Depends on: Task 3

**Files (exclusive ownership):**
- Create: `skills/loop-drive/references/queue-runner.md`
- Test: `tests/gates/queue-runner.sh` (create)

**Interfaces:**
- Produces: a standalone, pasteable prose prompt (portable, no Claude-Code-specific fields) that a human or scheduler runs to process the queue. In order: derive a session-id (`${USER:-agent}-$$` if none supplied); read the status ledger; run `scripts/tracker.sh next-eligible <session-id>` (which prefers a stale-working relaunch over fresh todo, so a killed wave is resumed automatically); claim via `scripts/tracker.sh claim <num> <session-id>` (or `claim <num> <session-id> --reclaim` when relaunching a stale-working unit) and re-read to confirm ownership; do the scoped work; leave a receipt via `scripts/tracker.sh done <num> --ran '<the check command>'` (preferred, re-executes) or `--receipt '<passing evidence>'`, or `status <num> review|needs-input` when human judgment is required; then STOP - at most one eligible ticket per run.
- A **canonical copy-paste example** of a claim -> work -> evidenced-done cycle is included verbatim so the operator never hand-assembles the receipt.
- Boundary-first block, verbatim, five items: never **publish**, **deploy**, **delete**, **email**, or change **billing/credentials** without issue-level approval. This is a `[gate:STOP]`-class rule per loop-auto's gate classes (outward-facing unit halts and waits); documented inline here because the gate registry scrapes only `skills/loop-*/SKILL.md` and this is a reference doc - the class name makes the semantics unambiguous.

**Acceptance check:** `tests/gates/queue-runner.sh` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test verbatim:

```bash
#!/usr/bin/env bash
# The queue-runner reference exists, invokes the scripted one-per-run primitive (incl. stale relaunch),
# claims + evidenced-dones through the guard, lists all five boundary terms, and stays portable.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; REPO="$(cd "$HERE/../.." && pwd)"
Q="$REPO/skills/loop-drive/references/queue-runner.md"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -f "$Q" ] || fail "queue-runner reference missing"
grep -q 'tracker.sh next-eligible' "$Q" || fail "prompt does not invoke the scripted selection primitive"
grep -q 'tracker.sh claim'         "$Q" || fail "prompt does not claim via the claim-lock"
grep -q 'tracker.sh done'          "$Q" || fail "prompt does not complete via the evidence-gated done"
grep -qi 'reclaim'                 "$Q" || fail "prompt has no stale-working relaunch path"
grep -Eqi 'at most one|one .* per run|exactly one' "$Q" || fail "one-per-run stop rule absent"
grep -qi 'STOP' "$Q" || fail "boundary gate class (STOP) not named"
for term in publish deploy delete email billing credential; do
  grep -qi "$term" "$Q" || fail "boundary-first list missing '$term'"
done
grep -Eqi 'claude code|claude-code|claude\.ai' "$Q" && fail "prompt carries a Claude-Code-specific field (must stay portable)"
echo "PASS: queue-runner wires primitives, stale relaunch, one-per-run, full boundary list, portable"
```

- [ ] Step 2: Run it - expected FAIL (file absent).
- [ ] Step 3: Write `skills/loop-drive/references/queue-runner.md` against the Interfaces. Thin, outcome-shaped, with the canonical example.
- [ ] Step 4: Run it - expected PASS.
- [ ] Step 5: Commit - `git add skills/loop-drive/references/queue-runner.md tests/gates/queue-runner.sh && git commit -m "control-plane: queue-runner reference, stale relaunch, one-per-run, boundary-first"`

---

## Task 5: Run-state onto tickets + the kill test

Depends on: Task 2, Task 3

**Files (exclusive ownership):**
- Modify: `skills/loop-drive/SKILL.md` (run-state section), `skills/loop-drive/references/native-orchestration.md` (run-state receipt fields)
- Test: `tests/repo-state/tracker-killtest.sh` (create)

**Interfaces:**
- Produces: a documented convention that loop-drive's run-state **moves onto the claimed ticket** as receipts (owner decision), not only a session-local file. On claim and at each wave gate the orchestrator writes an `AGENT STATUS` receipt via `scripts/tracker.sh comment` carrying the unit's branch, worktree path, validator verdict, and repair count (the same fields native-orchestration.md already lists). Git remains reconciliation truth (P11): a resumed session trusts git over any receipt and **relaunches** (never resumes) a half-done unit.
- The reconciliation rule (stated in the SKILL): a fresh session finds a killed unit via `tracker.sh next-eligible` (stale-working sweep) or `claim <num> <sid> --reclaim`, reads the `AGENT STATUS` receipt + git for the unit's state, and relaunches it from scratch.

**Acceptance check:** `tests/repo-state/tracker-killtest.sh` exits 0 `[executed-check]` - the mechanical half of brief criterion 3: a killed unit is reclaimable and relaunchable from tracker + git alone. It **runs the reclaim**, it does not merely grep for prose. The prose-follow half is the Task 7 Step 4 demo.

- [ ] Step 1: Write the failing test verbatim:

```bash
#!/usr/bin/env bash
# Kill-test (mechanical): a dead session claimed #1, wrote an AGENT STATUS receipt, and committed a
# partial branch. A fresh session, from tracker + git ALONE: (a) a plain claim is refused (race guard
# still protects live tickets), (b) claim --reclaim takes over (exit 0, re-owned), (c) the run-state
# receipt + git branch are readable for relaunch. Also asserts the NEW run-state artifact is documented.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; REPO="$(cd "$HERE/../.." && pwd)"; T="$REPO/scripts/tracker.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
BIN="$(mktemp -d)"; SB="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB"' EXIT
GHLOG="$BIN/gh.calls"
cat > "$BIN/gh" <<EOF
#!/usr/bin/env bash
echo "GH CALLED: \$*" >> "$GHLOG"; exit 1
EOF
chmod +x "$BIN/gh"; export PATH="$BIN:$PATH"
cd "$SB"
git init -q -b main 2>/dev/null || { git init -q && git symbolic-ref HEAD refs/heads/main; }
git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
mkdir -p config && "$T" mode set local >/dev/null

# a dead session claimed #1, left a run-state receipt, committed a partial unit branch, then died
"$T" create --label agent:todo --title "Half done unit" --body "work" >/dev/null
"$T" claim 1 sess-DEAD >/dev/null
"$T" comment 1 "AGENT STATUS branch=unit-1 worktree=/tmp/wt verdict=pending repairs=0" >/dev/null
git checkout -q -b unit-1 && echo x > partial.txt
git -c user.email=t@t -c user.name=t add -A && git -c user.email=t@t -c user.name=t commit -q -m "partial unit-1"
git checkout -q main
f="docs/issues/001-half-done-unit.md"

# (a) a fresh plain claim is REFUSED - the race guard still protects a live-looking ticket
"$T" claim 1 sess-NEW >/dev/null 2>&1; rc=$?
[ "$rc" -eq 4 ] || fail "plain claim over an existing claim was not refused (rc=$rc)"

# (b) reclaim takes over from tracker alone
own="$("$T" claim 1 sess-NEW --reclaim)" || fail "reclaim of the dead ticket failed"
[ "$own" = "sess-NEW" ] || fail "reclaim did not re-own the ticket"
grep -qE '^labels:.*agent:working' "$f" || fail "reclaimed ticket is not agent:working"

# (c) the run-state receipt + git branch are readable for relaunch
grep -q 'AGENT STATUS branch=unit-1' "$f" || fail "run-state receipt missing from ticket"
git rev-parse --verify -q unit-1 >/dev/null || fail "git does not carry the half-done unit branch"

# the NEW run-state-onto-tickets convention is documented (not pre-existing P11 phrasing)
D="$REPO/skills/loop-drive/SKILL.md"
grep -q 'AGENT STATUS' "$D" || fail "SKILL does not document the AGENT STATUS run-state receipt"
grep -q 'tracker.sh comment' "$D" || fail "SKILL does not wire run-state onto tickets via tracker.sh comment"

[ ! -s "$GHLOG" ] || { cat "$GHLOG"; fail "local mode touched gh"; }
echo "PASS: killed unit refuses a plain claim, yields to reclaim, and is relaunchable from tracker + git"
```

- [ ] Step 2: Run it - expected FAIL: the SKILL greps (`AGENT STATUS`, `tracker.sh comment`) are for text this task introduces, absent today - unlike pre-existing P11 phrasing, so the failure genuinely isolates this task's work. (The tracker mechanics from Tasks 1-2 already pass; that is intended.)
- [ ] Step 3: Edit `skills/loop-drive/SKILL.md` and `references/native-orchestration.md`: run-state moves onto tickets as `AGENT STATUS` receipts written via `tracker.sh comment`, git stays reconciliation truth (P11), relaunch-never-resume, and a killed unit is recovered via `next-eligible`/`claim --reclaim`.
- [ ] Step 4: Run it - expected PASS.
- [ ] Step 5: Commit - `git add skills/loop-drive/SKILL.md skills/loop-drive/references/native-orchestration.md tests/repo-state/tracker-killtest.sh && git commit -m "control-plane: run-state onto tickets (AGENT STATUS), reclaim-based relaunch, git stays truth"`

---

## Task 6: Lifecycle reconciliation lint (superseded + unlinked)

Depends on: Task 2

**Files (exclusive ownership):**
- Create: `scripts/lifecycle-lint.sh`
- Modify: `config/repo-state.md` (document the `agent:` status vocabulary as single home; document the archivable rule + lint), `skills/handoff/SKILL.md` (one-line pointer to run the lint at handoff time)
- Test: `tests/repo-state/lifecycle-lint.sh` (create)

**Interfaces:**
- Produces:
  - `scripts/lifecycle-lint.sh <repo-root>` - a deterministic detector (no hooks, no daemons; run on demand and at handoff time). **Its first action is `cd "$1"`** so all `tracker.sh` calls resolve against the target repo, never the caller's cwd. It flags:
    - **(a) superseded + unlinked plan-set** - a `docs/plans/*-plan.md` whose topic-stem is NOT the newest cycle (a strictly-newer plan-set exists by date) AND that is not in `docs/archive/` AND has no OPEN tracking issue referencing its stem. This is the owner-chosen archivable signal; it replaces checkbox-completeness (dead: loop-drive never ticks boxes).
    - **(b) orphaned brief** - a brief in `docs/briefs/` whose matching plan (topic stem: strip leading `YYYY-MM-DD-` and trailing `-brief`/`-plan`/`-plan_loop`, compare the middle) is already in `docs/archive/`.
    - **(c) completed work whose linked issue is still open** - an archived plan whose stem is referenced by an OPEN issue.
    - **(d) closed issues referenced by live (non-archived) plans**.
    Output: one line per finding `LINT <class> <path-or-issue>: <why>`; exit 0 clean, exit 1 on any finding.
  - **Linking:** a plan links to an issue when an issue's title or body contains the plan's topic-stem (`<stem>` from the same strip rule). No new front-matter field required; works in local + remote.
  - **Backend-optional:** classes (a) filesystem-supersession and (b) are always computable; the OPEN-issue half of (a), and (c)/(d), query `tracker.sh list` and run only when `tracker.sh mode get` succeeds - absent a tracker mode they are skipped silently, so the lint runs in a bare repo (and the fixture test) without a backend. Under a mode, the archive/close **action** (not this script) is BATCH-class per loop-auto (auto-take + journal under `auto`, offered under `pause`); issue closure additionally requires Task 2's evidence receipt.
  - `config/repo-state.md`: a subsection documenting the `agent:` vocabulary (`agent:todo|working|needs-input|review|done`, semantics fixed) as the single schema home, and an archivable-rule line grounding it on supersession + no open link, with the lint named in the archive rules.
  - `skills/handoff/SKILL.md`: one line - at handoff time, after regenerating mirrors, run `scripts/lifecycle-lint.sh .` and surface any findings.

**Acceptance check:** `tests/repo-state/lifecycle-lint.sh` exits 0 `[executed-check]` - covers the superseded-unlinked signal (class a) and the orphan-brief signal (class b) on a fixture, with a gh stub proving no live-tracker leak.

- [ ] Step 1: Write the failing test verbatim:

```bash
#!/usr/bin/env bash
# lifecycle-lint flags a superseded+unlinked plan (a) and an orphaned brief (b), spares the newest
# cycle and a linked plan, exits 1 iff findings, cd's into its arg, and touches NO live tracker.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; REPO="$(cd "$HERE/../.." && pwd)"; L="$REPO/scripts/lifecycle-lint.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$L" ] || fail "scripts/lifecycle-lint.sh missing or not executable"
BIN="$(mktemp -d)"; SB="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB"' EXIT
GHLOG="$BIN/gh.calls"
cat > "$BIN/gh" <<EOF
#!/usr/bin/env bash
echo "GH CALLED: \$*" >> "$GHLOG"; exit 1
EOF
chmod +x "$BIN/gh"; export PATH="$BIN:$PATH"
mkdir -p "$SB/docs/plans" "$SB/docs/briefs" "$SB/docs/archive"
# NO config/repo-state.md tracker mode in the fixture -> issue-classes must be skipped, not error

# an OLD plan-set, superseded by a newer one, not archived, no open issue -> class (a)
echo "# Old thing plan"   > "$SB/docs/plans/2026-08-04-old-thing-plan.md"
# the newest cycle -> must NOT be flagged
echo "# New thing plan"   > "$SB/docs/plans/2026-08-15-new-thing-plan.md"
# a brief whose plan is already archived -> class (b)
echo "# Orphan brief"     > "$SB/docs/briefs/2026-08-01-orphan-brief.md"
echo "# Orphan plan"      > "$SB/docs/archive/2026-08-01-orphan-plan.md"

out="$("$L" "$SB")"; rc=$?
[ "$rc" -eq 1 ] || fail "lint did not exit 1 with findings (rc=$rc)"
printf '%s\n' "$out" | grep -q '^LINT a .*old-thing'  || fail "did not flag the superseded+unlinked plan"
printf '%s\n' "$out" | grep -q '^LINT b .*orphan-brief' || fail "did not flag the orphaned brief"
printf '%s\n' "$out" | grep -q 'new-thing' && fail "flagged the newest cycle's plan (should be spared)"

# clean tree: remove the two offenders -> exit 0
rm "$SB/docs/plans/2026-08-04-old-thing-plan.md" "$SB/docs/briefs/2026-08-01-orphan-brief.md"
"$L" "$SB" >/dev/null; rc=$?
[ "$rc" -eq 0 ] || fail "lint flagged a clean tree (rc=$rc)"

[ ! -s "$GHLOG" ] || { cat "$GHLOG"; fail "lint leaked to a live tracker with no mode declared"; }
echo "PASS: lifecycle-lint flags a+b, spares newest cycle, exit-codes right, no live-tracker leak"
```

- [ ] Step 2: Run it - expected FAIL (script absent).
- [ ] Step 3: Write `scripts/lifecycle-lint.sh` against the contract (cd into `$1` first; classes a/b filesystem + optional issue query gated on `tracker.sh mode get`). Add the `config/repo-state.md` vocabulary + archivable-rule subsection and the `skills/handoff/SKILL.md` pointer.
- [ ] Step 4: Run it - expected PASS.
- [ ] Step 5: Commit - `git add scripts/lifecycle-lint.sh config/repo-state.md skills/handoff/SKILL.md tests/repo-state/lifecycle-lint.sh && git commit -m "control-plane: lifecycle lint (superseded+unlinked) + agent: vocabulary single-home"`

---

## Task 7: Integration - install, full suite, registry drift, kill demo, archive demo

Depends on: Task 4, Task 5, Task 6

**Files (exclusive ownership):**
- Modify: `docs/gate-registry.md` (regenerated, only if tags changed), plus the real archival moves of the flagged plan-sets (`docs/plans/` -> `docs/archive/`) performed as the acceptance demo
- Test: none new; runs the whole suite and the demos

**Interfaces:**
- Consumes: every prior task.
- Produces: a clean install, a green full suite, a drift-free gate registry, a verified kill/resume demo, and the archive demo (real file archival, issue-closes staged).

**Acceptance check:** `./install.sh && tests/run.sh` ends `0 failed`; `scripts/gen-gate-registry.sh .` leaves `docs/gate-registry.md` drift-free (or the change is committed); `scripts/lifecycle-lint.sh .` flags the real superseded+unlinked plan-sets `[executed-check]`

- [ ] Step 1: `./install.sh` then `tests/run.sh` - expected all suites pass, `0 failed`.
- [ ] Step 2: `scripts/gen-gate-registry.sh .` then `git diff --exit-code docs/gate-registry.md` - commit the regenerated registry if it changed, else it is drift-free.
- [ ] Step 3: **gen-mirrors lane check (brief task 6):** on a scratch local-mode repo, create an `agent:working`-labelled non-idea issue, run `scripts/gen-mirrors.sh .`, and confirm it lands in `ISSUES.md` (not `BACKLOG.md`) - `agent:*` is orthogonal to the `idea` lane. Note in the run log that status transitions refresh `updated:` and so churn the mirrors (expected).
- [ ] Step 4: **Kill/resume demo (judgment checkpoint, brief criterion 3 prose half):** seed a claimed-then-dead ticket per the `tracker-killtest.sh` fixture; hand a fresh session ONLY `skills/loop-drive/references/queue-runner.md`; record the human verdict that it selected the stale-working ticket, reclaimed it, and relaunched the unit from tracker + git.
- [ ] Step 5: **Archive demo (real, in-worktree per the owner's scope decision):** run `scripts/lifecycle-lint.sh .` in this repo; confirm it flags the superseded+unlinked plan-sets (the six 2026-08-04 -> 2026-08-10 sets at minimum; it may honestly flag the 08-12 pair too - a superset still satisfies "the six are flagged"). Archive each flagged set (move the plan, its `_loop` twin, and its travelling brief from `docs/plans/`/`docs/briefs/` to `docs/archive/`), announcing each moved file (rule 5). Real files, git-revertible, worktree-isolated.
- [ ] Step 6: **STOP - human checkpoint (outward-facing):** for lint classes (c)/(d) that would CLOSE a real GitHub issue, do not fire. Print the exact `scripts/tracker.sh done <num> --receipt "..."` (or human `close`) command per issue and hand it to the owner; the owner fires these.
- [ ] Step 7: Commit - `git add -A && git commit -m "control-plane: integration green, plan-sets archived, issue-closes staged for owner"`

---

## Brief criteria coverage map

| Brief criterion                                                        | Task  | Executed-check                                        |
| ---                                                                    | ---   | ---                                                   |
| tracker.sh label ops pass in all three backend suites                  | 1     | tests/repo-state/tracker-labels.sh (local+github+gitlab) |
| Queue-runner: three eligible, one run touches exactly one, reason kept | 3     | tests/repo-state/tracker-eligible.sh                  |
| Kill test: claim + relaunch from tracker + git alone                   | 5,7   | tracker-killtest.sh (runs reclaim) + Task 7 Step 4 demo |
| Close guard: evidence-free/failing agent:done rejected, script-enforced| 2     | tests/repo-state/tracker-claim-done.sh                |
| tests/run.sh passes clean                                              | 7     | ./install.sh && tests/run.sh                          |
| Lint's first live run catches the unarchived plan-sets                 | 6,7   | lifecycle-lint.sh unit + Task 7 Step 5 real demo      |
| Works on local backend too (constraint)                                | 1-6   | every tracker suite has a local arm; lint runs modeless |
| Receipts align w/ handoff; gen-mirrors reflects lanes (brief task 6)   | 1,7   | receipt prose in Task 1; Task 7 Step 3 lane check     |

Every checkable criterion maps to at least one task carrying an `[executed-check]`; the only `[judgment]` residue is the prose-follow half of the kill test, routed to the Task 7 Step 4 human checkpoint, never onto a task.
