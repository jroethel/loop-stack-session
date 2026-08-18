# Context Map Full Index Implementation Plan

> For executors: tasks use checkbox syntax; execute in dependency order; a task is done when its
> acceptance check passes. No specific tooling, harness, or skills are assumed.

**Goal:** Ship `config/context-map.md` - a lifecycle-governed pointer index so a fresh agent reaches every piece of durable, non-derivable memory in this repo without pasting content into the prompt.
**Approach:** Create the map (policy header plus the index lines) as the single home; migrate the two existing pointers out of `config/repo-state.md`, leaving it a one-line pointer; wire the project `CLAUDE.md` orientation line; add a class-e resolver to `scripts/lifecycle-lint.sh` so every in-repo pointer is machine-checked; re-point the stale qmd research collection.
**Tech stack:** Markdown, Bash (POSIX/bash-4), the `qmd` CLI, git.
**Source brief:** `docs/briefs/2026-08-17-context-map-brief.md`.

## Global constraints

- The map is a pointer index, never content: each line is `what - where-or-how-to-retrieve - why it matters`.
- The `why` clause is load-bearing: a prune pass reads it to keep or retire the line without opening the pointee.
- Each index line is ONE physical line (the success checks are per-line greps); use ` - ` (space-dash-space) only as the top-level clause separator, never inside a clause.
- Every pointee that is an in-repo path appears inside backticks (the class-e lint extracts backticked tokens).
- Dating: lines under `### External` and `### Transient` carry a `(YYYY-MM-DD)` date; no line under `### In-repo, durable` carries one.
- Date format is `YYYY-MM-DD`, matching the repo's filename convention; the map-entry date is `2026-08-18`.
- Per-user operating lessons are never indexed here; they live in auto-memory (`MEMORY.md`). The map holds repo-committed pointers to in-repo artifacts and external corpora only.
- No retrieval verb is ever executed by the lint.
- House style: plain dash only (no em dash), aligned pipe tables, one sentence per physical line in prose.

## Dependency graph

```
Wave 1 (parallel):  Task 1 (create the map)      Task 2 (re-point qmd collection, host action)
                          |
Wave 2:             Task 3 (wire pointers)        depends on Task 1
                          |
Wave 3:             Task 4 (class-e lint + test)  depends on Task 1, Task 3
```

Task 1 gates Tasks 3 and 4 (both need the map to exist).
Task 2 is independent of every repo file and runs anytime.
Tasks 3 and 4 own disjoint files but are serialized (Task 4 depends on Task 3), not parallel: each
ends with a pathspec-less `git commit`, and two of those interleaved in one worktree would blend
their staged files or collide on `.git/index.lock`. Serializing costs nothing here (both are tiny,
single-edit-session work) and removes the race for any naive same-worktree executor.

## Human checkpoints

- **Judgment - why clauses.** After Task 1, a human confirms each `why` clause lets a molt keep or retire the line without opening the pointee. This is the brief's `[judgment]` criterion; it does not reduce to a grep.
- **Judgment - policy adequacy.** After Task 1, a human confirms the policy header covers all four lifecycle moments (add, refresh, prune, delete) adequately, not merely present.
- **Host mutation - qmd re-point (Task 2).** The re-point command writes host state outside this repo checkout and requires `qmd` on the host. It is the user's to fire, not an autonomous executor's; the command is staged in Task 2, the user runs it, then the acceptance check is re-run. An executor in a worktree without `qmd` routes this task to the user.
- **Out-of-scope debt surfaced, not fixed.** `scripts/lifecycle-lint.sh .` currently exits 1 with four pre-existing class-a findings (superseded plans under `docs/plans/` not yet archived: `control-plane`, `loop-molt-skill`, `slim-fold-dedup`). Archiving them is a separate BATCH-class lifecycle reconciliation at the archive gate, out of scope for #34. This is why Task 4's acceptance checks class-e specifically (`grep '^LINT e'`), not whole-lint `exit 0`.

## How to run

```bash
# from the repo root
bash scripts/lifecycle-lint.sh .            # lifecycle lint (adds class-e in Task 4)
bash tests/repo-state/lifecycle-lint.sh     # the lint's own test suite (extended in Task 4)
bash tests/run.sh                           # full test discovery/run
qmd search "progressive context shaping"    # research-corpus retrieval verb (must return a qmd:// hit)
qmd collection show research                # inspect the re-pointed collection (after Task 2)
```

---

### Task 1: Create `config/context-map.md`

Depends on: none

**Files (exclusive ownership):**
- Create: `config/context-map.md`

**Interfaces:**
- Consumes: nothing.
- Produces: the file `config/context-map.md` with a `## The index` heading, and index lines whose backticked in-repo pointers Task 4 resolves and whose one-line-pointer target Task 3 points at.

**Acceptance check:** all three commands below pass `[executed-check]`

```bash
# (a) every index line carries the three clauses (>= 2 top-level " - " separators)
awk '/^## The index/{s=1;next} s&&/^- /{n=gsub(/ - /,"");if(n<2){print "SHORT: "$0;bad=1}} END{exit bad}' config/context-map.md
# (b) dating by section: external + transient lines dated, durable lines not. sec defaults to "dur"
# so a stray line above the first ### subheading is held to the undated (durable) rule, never skipped.
awk '
  BEGIN{sec="dur"}
  /^### In-repo, durable/{sec="dur"} /^### External/{sec="ext"} /^### Transient/{sec="tr"}
  /^- /{
    dated=($0 ~ /\(20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]\)/)
    if(sec=="dur" && dated){print "DUR-DATED: "$0; bad=1}
    if((sec=="ext"||sec=="tr") && !dated){print "UNDATED: "$0; bad=1}
  } END{exit bad}' config/context-map.md
# (c) the boundary sentence naming auto-memory is present
grep -q 'MEMORY.md' config/context-map.md
```

Each of (a)-(c) exits 0. The research-corpus retrieval verb is NOT checked here: it needs host `qmd`
and a live collection, so that check belongs to Task 2 (which owns the qmd dependency), keeping Task 1
a pure repo-local file write that completes in a bare worktree.

- [ ] Step 1: Write `config/context-map.md` with exactly this content:

````markdown
# Context map

The orientation index for this repo: every piece of durable, non-derivable memory a fresh agent
needs, reached through one pointer each. Read this file first, then follow any line to its artifact.
This is the repo's answer to "paste everything into the prompt" - the pointers are the context, the
content stays where it lives.

## What earns a line

The durability test: a fresh agent needs it AND cannot derive it from the code or the git history.
Index homes over individual files (one line covers a whole lane forever); a single file earns its
own line only when it is a singular landmark. Additions are rare by construction - a new KIND of
artifact, or a new load-bearing document. Per-user operating lessons are NOT indexed here: those
live in auto-memory (`MEMORY.md`). The boundary is firm - this map holds repo-committed pointers to
in-repo artifacts and external corpora, never anything about how one person likes to work.

## Line shape

Each line is `what - where-or-how-to-retrieve - why it matters`, on one physical line, with ` - `
used only as the top-level clause separator. The why clause is load-bearing: a prune pass reads it
to keep or retire the line without opening the pointee, so it states what the artifact gives an
agent, not merely what it contains.

## Decay: dating plus a usage look

Two signals govern whether a line still earns its place; dating is the reliable one, usage is a
corroborating look with known blind spots.

- Dating is the primary cheap marker. Anything that can rot carries a `(YYYY-MM-DD)` date - external
  paths, retrieval verbs, and transient snapshots. In-repo durable lines carry no date, and
  machinery-supporting operational notes count as durable. A dated line is never auto-dead at any
  age; the date is an input to the prune look, not a timer.
- Usage is a rough corroborating look, not a precise counter. Age cannot tell a pointer used once
  from one used constantly, so at each prune pass a coarse citation count helps: `git grep -l
  <pointee-basename> | grep -v config/context-map.md | wc -l` counts how many tracked files reference
  the pointee. Read it as a weak signal, never a verdict - it over-counts the brief or handoff that
  first named the line, under-counts a real "follow" (a markdown line read directly emits no event),
  and misses any citation phrased without the filename. No live counter is kept: self-reported bumps
  on every orientation would flood git with noise, so usage is derived retrospectively at the gate,
  coarsely, never tracked live. When the count and the date both say a line is cold, retire it; when
  they disagree, the why clause and a human's judgment decide.

## Lifecycle

- Add: at the durability test above, on the write gates below; homes over files; verbose-announce
  the added line.
- Refresh: touching a pointee (edit, supersede, move) revalidates its line's where and why in the
  same change; a move is rewritten in place, never appended as a correction.
- Prune: this map is an explicit target at every molt-close - per line, run the removal test (does
  it still pass the durability test?) plus the usage-and-staleness look above; no retrieval verb is
  executed by the lint.
- Delete: the pointer moves or dies with its pointee (at archive or graduation); verbose-announce
  the moved or deleted line. The class-e lint will go red between removing a pointee and removing
  its map line - that red at an archive or molt gate is expected, and clearing it is this Delete
  step, not a regression to back out.
- Write gates: brief commit, handoff close, molt close, archive/graduation. Every line added, moved,
  or deleted is announced, the same precedent as parking-lot graduation and mirror regeneration.

## The index

### In-repo, durable

- Molt evaluation basis - `docs/memos/2026-08-15-pcs-consolidated-recommendations.md` (protocol at `skills/loop-molt/references/protocol.md`, ledger `docs/molt-ledger.md`) - the pcs verdict and the second axis a molt re-derives its constraints from, without which an audit restarts its reasoning from zero.
- Decision records, four homes - Approach sections under `docs/briefs/`, batch journals under `docs/reviews/`, the drift ledger `docs/molt-ledger.md`, and inline DECISION lines, with the 2026-08 set anchored by `docs/2026-08-02-settled-decisions-and-sequence.md` - where a past "why did we choose X" is written down, so it is read instead of re-litigated.
- Engineering principles - `principles.md` (P1-P14) - the numbered principle vocabulary the diagrams and learning guide cite, needed to read those artifacts or name a principle in review.
- Origin design record - `PLAN.md` and `conversation-archive.md` - the approved full build plan and the 2026-07-10 session behind it, the "why is the stack shaped this way" that code and commits never narrate.
- Model-routing prior tier - `config/routing/model-benchmarks.md` - the routing chain's prior-tier scoreboard and loop-which's tier examples, how an agent resolves a tier to a model before any local scoreboard evidence exists.
- Git conventions for loop work - `docs/git-guide.md` - loop-stack's return points, worktree gates, and recovery moves, which generic git knowledge does not cover.

### External (dated)

- Research corpus - `~/create/research/research/` outside the repo, query via `qmd search '<topic>'` (collection `research`) - the 13 digests behind the 2026-08 evaluation, the evidence a design decision cites without pasting any of it. (2026-08-18)

### Transient (dated, expected to die at a molt or archive pass)

- Agent-error field notes - `fixing-agent-errors.md` - a raw pasted transcript of failure patterns, kept until a molt distills or archives it. (2026-08-18)
- Model-routing run notes, local engine - `model-routing-ringer-notes.local.md` - the raw transcript behind routing-unification work, superseded once its findings land in durable form. (2026-08-18)
- Model-routing run notes, remote engine - `model-routing-ringer-notes.remote.md` - the raw transcript companion for the remote engine, same expiry. (2026-08-18)
- First gitlab-mode setup findings - `docs/memos/2026-08-10-to-loop-stack.md` - a dated cross-host report from a real /loop-setup run, retired once its findings are absorbed or stale. (2026-08-18)
````

- [ ] Step 2: Run acceptance checks (a)-(c). If (a) prints `SHORT:`, a line has fewer than two ` - ` separators - fix it. If (b) prints `DUR-DATED:` or `UNDATED:`, a line is dated in the wrong section - fix it. Expected: all three exit 0.
- [ ] Step 3: Commit.
```bash
git add config/context-map.md
git commit -m "context-map: create config/context-map.md full index (#34)"
```

---

### Task 2: Re-point the qmd research collection

Depends on: none

**Files (exclusive ownership):** none (host-side action, no repo file).

**Interfaces:**
- Consumes: nothing.
- Produces: a `qmd` collection named `research` rooted at `~/create/research`, so the map's `qmd search` verb resolves against a live, re-indexable corpus rather than a frozen snapshot of the deleted `~/create/pcs` path.

**Acceptance check:** both commands pass `[executed-check]`

```bash
qmd collection show research | grep -qi '/create/research'   # collection rooted at the live path
qmd search "progressive context shaping" | grep -q '^qmd://'  # BM25 search returns a corpus hit
```

Context: the existing `pcs` collection points at `~/create/pcs`, which was renamed to `~/create/research` on 2026-08-16 and no longer exists; the collection still returns hits only from a stale index it can no longer refresh. `qmd` has no in-place re-point, so this adds the live path first, then removes the stale one - add-before-remove so a failed `add` never leaves zero collections and breaks retrieval. This mutates host state outside the repo checkout and is the user's to fire.

- [ ] Step 1: Add the collection at the live path (user runs this on the host).
```bash
qmd collection add ~/create/research --name research
```
- [ ] Step 2: Confirm the new collection indexed, then remove the stale one. If `add` failed, stop here and re-run Step 1 (retrieval still works off the old `pcs` collection until then); do not remove `pcs` until `research` is present.
```bash
qmd collection show research | grep -qi '/create/research' && qmd collection remove pcs
```
- [ ] Step 3: Optionally rebuild vectors (only if `qmd query`/`qmd vsearch` are wanted; `qmd search` is BM25 and needs no embeddings).
```bash
qmd embed
```
- [ ] Step 4: Run both acceptance-check commands; expected both exit 0.
- [ ] Step 5: No commit (no repo file changed).

---

### Task 3: Wire the two pointers

Depends on: Task 1

**Files (exclusive ownership):**
- Modify: `config/repo-state.md:74-77` (the `## Context map` section)
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: `config/context-map.md` (created by Task 1) as the pointer target.
- Produces: nothing later tasks rely on.

**Acceptance check:** all three commands pass `[executed-check]`

```bash
# (a) repo-state.md points at the map and no longer carries the two migrated pointer lines
grep -q 'config/context-map.md' config/repo-state.md
! grep -q 'Molt evaluation source: `docs/memos/2026-08-15-pcs' config/repo-state.md
# (b) the project CLAUDE.md names the context map as the orientation index
grep -q 'config/context-map.md' CLAUDE.md
```

- [ ] Step 1: In `config/repo-state.md`, replace the entire `## Context map` section (the heading on line 74 through the `Research corpus:` line, currently line 77) with this pointer:
```markdown
## Context map

The repo's orientation index lives in `config/context-map.md`: every piece of durable,
non-derivable memory a fresh agent needs, one pointer each, under a full lifecycle policy.
This file remains the definitive list of convention and schema files; the context map is the
definitive index of memory pointers.
```
- [ ] Step 2: In `CLAUDE.md`, append this line under the existing repo-state line:
```markdown
Orientation index: `config/context-map.md` indexes every piece of durable, non-derivable memory a fresh agent needs, one pointer each.
```
- [ ] Step 3: Run acceptance checks (a) and (b); expected exit 0 (the negated grep passes only once the migrated line is gone).
- [ ] Step 4: Commit.
```bash
git add config/repo-state.md CLAUDE.md
git commit -m "context-map: migrate repo-state pointers, wire CLAUDE.md orientation line (#34)"
```

---

### Task 4: Add class-e to `scripts/lifecycle-lint.sh`

Depends on: Task 1, Task 3 (Task 3 must commit first - both end in a pathspec-less `git commit` in the same worktree)

**Files (exclusive ownership):**
- Modify: `scripts/lifecycle-lint.sh` (insert class-e before the final `exit "$found"`)
- Modify: `tests/repo-state/lifecycle-lint.sh` (extend the existing suite)

**Interfaces:**
- Consumes: `config/context-map.md` (Task 1); the existing `lint()` helper and `found` variable in `scripts/lifecycle-lint.sh`.
- Produces: a `LINT e <map> <why>` finding line per unresolved in-repo pointer; nothing later tasks rely on.

**Acceptance check:** both commands pass `[executed-check]`

```bash
bash tests/repo-state/lifecycle-lint.sh                        # suite PASSes (now also exercises class-e)
[ -z "$(bash scripts/lifecycle-lint.sh . 2>&1 | grep '^LINT e')" ]  # zero class-e findings against the real map
```

The second check is class-e-specific on purpose: the repo carries pre-existing class-a findings (see Human checkpoints), so whole-lint `exit 0` is not the bar here; zero `LINT e` lines is.

- [ ] Step 1: In `scripts/lifecycle-lint.sh`, insert this block immediately before the final `exit "$found"` line:
```bash
# (e) in-repo context-map pointer resolves - pure filesystem, runs only when a map exists, so the
# lint stays portable across loop-stack repos. Scans only the "## The index" section, so backticked
# prose in the policy header (e.g. `MEMORY.md`, a grep example) is never mistaken for a pointer.
MAP=config/context-map.md
if [ -f "$MAP" ]; then
  # Resolve only filesystem-style in-repo pointers; skip verbs, externals, URI schemes, prose words.
  while IFS= read -r tok; do
    case "$tok" in
      *' '*)         continue ;;  # a retrieval verb, not a path
      *'://'*)       continue ;;  # a URI scheme (e.g. qmd://...), not a filesystem path
      '~'*|/*|http*) continue ;;  # external or absolute - not an in-repo pointer
      *.*|*/*)       ;;           # has an extension or a slash: treat as a path
      *)             continue ;;  # bare backticked prose word
    esac
    p="${tok%%:*}"               # drop any :line-range suffix
    [ -e "$p" ] || lint e "$MAP" "in-repo pointer '$tok' does not resolve"
  done < <(sed -n '/^## The index/,$p' "$MAP" | grep -oE '`[^`]+`' | sed 's/`//g')
fi
```
- [ ] Step 2: Update the header comment block: add class-e to the `# Classes:` list near the top of the script (one line: `#   e  every backticked in-repo pointer in config/context-map.md's index resolves (test -e)`).
- [ ] Step 3: In `tests/repo-state/lifecycle-lint.sh`, after the existing "clean tree: ... exit 0" block (currently ending near line 35), insert this class-e coverage before the final `$GHLOG` assertion:
```bash
# (e) context-map pointer resolution: a broken in-repo pointer trips class-e; header prose is spared
mkdir -p "$SB/config"
cat > "$SB/config/context-map.md" <<'MAP'
# Context map
Header prose naming `MEMORY.md` must be ignored - it is not a repo file.
## The index
- Real pointer - `docs/plans/` - resolves.
- Broken pointer - `docs/nope/ghost.md` - does not resolve.
MAP
out="$("$L" "$SB")"; rc=$?
[ "$rc" -eq 1 ] || fail "class-e: lint did not exit 1 with a broken map pointer (rc=$rc)"
printf '%s\n' "$out" | grep -q '^LINT e .*ghost.md' || fail "class-e: did not flag the broken pointer"
printf '%s\n' "$out" | grep -q 'MEMORY.md' && fail "class-e: false-positived on header prose MEMORY.md"
# all pointers resolve -> class-e clean
cat > "$SB/config/context-map.md" <<'MAP'
# Context map
## The index
- Real pointer - `docs/plans/` - resolves.
MAP
"$L" "$SB" >/dev/null; rc=$?
[ "$rc" -eq 0 ] || fail "class-e: lint flagged a map whose pointers all resolve (rc=$rc)"
```
- [ ] Step 4: Run acceptance checks. Expected: the suite prints `PASS:` and exits 0; the class-e grep against the real repo returns empty.
- [ ] Step 5: Commit.
```bash
git add scripts/lifecycle-lint.sh tests/repo-state/lifecycle-lint.sh
git commit -m "lifecycle-lint: add class-e in-repo context-map pointer resolver (#34)"
```
