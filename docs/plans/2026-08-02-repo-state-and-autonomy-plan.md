# Repo State Convention + Autonomy Knob Implementation Plan

> For executors: tasks use checkbox syntax; execute in dependency order; a task is done when its
> acceptance check passes. No specific tooling, harness, or skills are assumed.

**Goal:** Ship seam B (a declared per-repo state convention with gh-issue lanes, disclosed mirrors, converged location-aware handoff) and seam C (a persisted autonomy knob over a four-type gate taxonomy tagged at the gate sites) as one build, standing up this repo's own state as the demonstration.
**Approach:** Split state by lane nature - roadmap is a file, issues and backlog are gh issues, everything is declared in one `config/repo-state.md` - and make gate class truth-at-the-site via inline tags that a generated registry mirrors and a freshness check guards; the knob is an explicit setting persisted in chain state.
**Tech stack:** Bash (POSIX-ish, matching `install.sh` and `tests/loop-review/`), `gh` CLI, GitHub issues, Claude Code skills (markdown SKILL.md files).
**Source briefs:** `docs/briefs/2026-08-02-repo-state-convention-brief.md` (seam B), `docs/briefs/2026-08-02-autonomy-knob-brief.md` (seam C).
**Surrounding ledger:** `docs/2026-08-02-settled-decisions-and-sequence.md` - the build wave (step 4) is later work; B and C tasks here compose with it and do not duplicate it.

## Scope reconciliation (read before decomposing)

The two briefs each carry an "out of scope: skill-body edits (build wave)" line that appears to collide with their own seams and success criteria.
The reconciliation, fixed here so no task relitigates it:

- **In scope now (this plan):**
  - B: `config/repo-state.md` + schema, the `loop-setup` skill, the mirror generator, the *converged* handoff skill (new in-repo this session), documented archive/graduation rules, and this repo's live migration.
  - C: inline gate tags in the four chain skill texts (tags only), the generated registry + freshness check, the `/loop-auto` knob mechanism, the chain-state and batch-review formats.
- **Out of scope now (build wave, per the ledger step 4):**
  - Wiring auto-graduation into `loop-brainstorm` at brief-commit time (the *rule* and *issue template* are documented here; the skill-body edit that fires it is build-wave).
  - Wiring the four chain skills to *consume* the knob and gate tags at runtime (the tags, rules doc, and knob persistence are here; the behavior that reads them mid-run is build-wave).
  - The end-to-end autonomous demonstration run of the build wave under the knob (C's "End artifact").
- **The tags-only invariant (C):** C's edits to `loop-brainstorm`, `loop-plan`, `loop-drive`, `loop-which` add gate tags and nothing else; with the knob off, the diff to those four files is tag additions only (success criterion, brief C).

## Global constraints

- Markdown files: one sentence per line, plain dashes (never the em dash), no section symbol, table cells padded so pipes align, total table width <= 110 chars.
- Never hand-edit generated files: mirrors (`ISSUES.md`, `BACKLOG.md`) and `docs/gate-registry.md` carry a `DO NOT EDIT` disclosure and are only ever regenerated.
- Bash scripts follow the `tests/loop-review/acceptance.sh` house style: `set -uo pipefail` (not `-e`), each check prints its own failure via a `fail()` helper, exit 0 only on full pass.
- Skills are self-contained markdown; no task adds a script the executor must install beyond the repo itself.
- `gh` is the single source of truth for issues and backlog; mirrors are read-only snapshots whose headers disclose staleness; no hooks, no daemons, no always-running sync.
- Nothing here spawns Fable; the knob's continuation model only ever delegates down-tier (managed CLAUDE.md roster).
- Commits: never add an agent co-author line; do not touch `CHANGELOG.md` or auto-generated files by hand.

## Resolved open questions (decided here, with rationale)

Seam B:

- **`config/repo-state.md` schema:** a lane table (Roadmap, Issues, Backlog, Handoffs, Chain state, Batch reviews, Archive) each with `Home` and `How` columns, then a `## Fallback (no remote)` section (local-markdown tracker) and a `## Archive and graduation rules` section. Rationale: one glanceable contract; the fallback and rules are prose, not table cells.
- **CLAUDE.md pointer wording (one line):** `Repo state map: config/repo-state.md declares where roadmap, issues, backlog, handoffs, and archive live.`
- **Handoff: repo-managed or hand-copied?** Repo-managed. Move `~/.claude/skills/handoff` into `skills/handoff`; `install.sh` already symlinks every `skills/*` and backs up the pre-existing real dir. Rationale: consistency with every other loop-stack skill, single live-editable source, and Jeremy under-invests in exactly this kind of drift.
- **Config schema lives once (rubix B5):** the lane schema is authored in one place, `config/repo-state.template.md`, owned by B1. B1 renders this repo's `config/repo-state.md` from it; B3's `setup.sh` renders a new repo's config from the same template. Neither hand-copies the schema, so the two cannot drift - the exact failure seam B exists to kill.
- **Mirror format:** root-level `ISSUES.md` and `BACKLOG.md`, each with an HTML-comment header disclosing generation time + regen command + `DO NOT EDIT`, an H1, then a table `# | title | labels | updated`, sorted by issue number descending. `BACKLOG.md` = open issues labeled `idea`; `ISSUES.md` = open issues without `idea`.
- **Roadmap file:** `docs/roadmap.md`, beside `docs/briefs/` and `docs/plans/`. Coarse ordered narrative; an entry may link a brief/plan when one exists. Low churn, versions with the code it plans.
- **Graduated-item issue body template:** verbatim parking-lot prose, then a `---`, then `Source brief:`, `Graduated:` (date), `Restart context:` (one line). Label `idea`.
- **In-repo handoff location:** `docs/handoffs/YYYY-MM-DD-<slug>.md` (dated); "where I left off" = the newest file. Outside any repo, `/handoff` still writes to the OS temp dir.
- **"Where I left off" degrades to git (rubix A4):** the answer must never depend on remembering to run `/handoff` before a session ends. The config's Handoffs lane states the fallback in words: newest `docs/handoffs/` file if one exists, else the newest commit on the working branch plus `git log --oneline -5` and `git status`. A crashed or cold-closed session degrades to git, never to nothing.

Seam C:

- **Command + phrases:** `/loop-auto`. Recognized phrases: "run the rest", "run the rest from here", "take it from here", "go autonomous", "auto mode", "full auto". Any phrase sets the knob with a one-line confirmation of the mode; never silent.
- **Tag syntax:** backtick-wrapped inline `` `[gate:ASK]` ``, `` `[gate:STOP]` ``, `` `[gate:BATCH]` ``, `` `[gate:DEFAULT]` `` on the line where the gate fires. Escape hatch `` `[gate:none]` `` suppresses a false positive from the freshness heuristic. Grep token: `\[gate:(ASK|STOP|BATCH|DEFAULT|none)\]`.
- **Registry:** `docs/gate-registry.md`, generated, disclosed header. Rows key on `skill | type | trigger` and carry **no line numbers** (rubix A2): line numbers are the highest-churn attribute in a skill file, so keying on them would stale the registry on any benign prose edit that renumbers gates below it. The disclosed header's timestamp line is verbatim `<!-- generated: <ISO8601> -->` (rubix B6) so the freshness diff can strip exactly it.
- **Freshness check:** `tests/gates/check.sh` is authoritative (exit 0 gate); `install.sh` doctor invokes it non-fatally. Two parts: (a) the registry regenerates byte-identically (stale = red), (b) the untagged-gate scanner. The scanner is **high-precision, not a prose grep** (rubix A5/B1): the raw signal set (`\bSTOP\b`, `approve`, `pick`, `triage`, `commit?`) matched ~57 lines across the four skills against ~20 real gates - section headings, dot-graph nodes, and "Reading the user" prose - so it is unrunnable as first drafted. The scanner instead only flags lines that both (i) sit under a `## Step` heading (not red-flag tables, not the process-flow dot graph, not frontmatter) and (ii) contain a tight token: `AskUserQuestion`, `ask once`, `offer the commit`, `Want me to commit`, `human checkpoint`, `ask the human`, `Wait for the response`. The `` `[gate:none]` `` escape hatch remains for the rare true gate-shaped line these still catch. The registry header and the check both disclose that the registry reflects *tagged* gates only and is not a completeness guarantee, so no reader over-trusts it.
- **Chain-state artifact:** `docs/chain-state.md`, managed by `scripts/loop-auto.sh`; home declared by `config/repo-state.md`. Holds the autonomy mode and a pointer to the active chain artifact.
- **Chain-state is gitignored runtime state (rubix A1/B4):** it is *not* committed, so writing the mode never dirties the working tree. `preflight` computes dirtiness with the chain-state path excluded (`git status --porcelain -- . ':(exclude)docs/chain-state.md'`), so `set auto` immediately followed by `preflight auto` passes on an otherwise-clean tree. B1 adds `docs/chain-state.md` to `.gitignore`. Persistence across sessions is the on-disk file (same repo, same machine); `get` returns `pause` when it is absent (the unset default).
- **Batch-review list:** `docs/reviews/YYYY-MM-DD-<slug>-batch-review.md`; home declared by `config/repo-state.md`.
- **Does `_loop.md` record the mode?** No. `docs/chain-state.md` is the single source of truth; wiring `loop-drive` to read it is build-wave (keeps C's skill diff tags-only). Documented in the `/loop-auto` skill and the CLAUDE.md autonomy section, not in `loop-drive`.

## Dependency graph

```
Wave 1 (parallel, no deps):   B1 (config+schema)   B2 (mirror gen)   C1 (gate tags)
Wave 2 (parallel):            B3 (loop-setup)      B4 (handoff)      C2 (registry+check)   C3 (loop-auto knob)
                               deps B1,B2           deps B1,B2        deps C1,B1,B2         deps B1
Wave 3:                       B5 (this-repo migration + demonstration)
                               deps B1,B2
```

- B5 gates on B1+B2 only; it can run once wave 2's B tasks are done in practice but has no hard edge to B3/B4/C*.
- All wave-2 tasks touch disjoint files (see each task's ownership block); they are parallel-safe.
- C2 depends on C1 (it scans the tags C1 writes) and on B2 (it reuses `scripts/gen-mirrors.sh`'s disclosed-header shape); B1 defines the mirror lane but B2 is where the header convention is actually coded.

## Human checkpoints

The executor stops and asks a human at exactly these points; none of these are worker tasks:

1. **B5 archive offer** - before moving any brief/plan to `docs/archive/`, list each candidate and its rule (auto-archive only fully-complete plans; everything else is offered, per the archive rules). The `loop-skills-model-routing.xlsx` and `docs/2026-07-20-mattpocock-comparison-dump.md` are offered here (ledger loose end: archivable once the ledger is committed).
2. **B5 graduation review** - before creating gh issues from the live parked items, show the exact `gh issue create` commands and bodies for approval (issue creation is outward-facing per the STOP class).
3. **B [judgment] criterion** - "a fresh session answers the three return-from-break questions citing only standard locations": a human runs the fresh-session check after B5; the resolvability half is covered by the B1 config check, this half is briefing quality.
4. **C [judgment] criterion** - "the batch-review list is a sufficient basis to accept or reverse each batched decision without replaying the run": a human judges sufficiency against C3's worked sample (`docs/reviews/2026-08-02-sample-batch-review.md`); the structural half (each entry names decision, rationale, and a gate-type-appropriate reversal path) is checked by C3.
5. **Final commit + push** - `main` is ahead of `origin` (ledger loose end); offer the push at the session boundary, do not push unprompted.
6. **Build-wave demonstration** - the end-to-end autonomous run under the knob and the seeded-dirty-tree STOP behavioral proof are build-wave; noted here so no task attempts them.

## How to run

From the repo root (`/Users/jjrdar/create/loops/loop-stack-session`):

```bash
# B2 mirror generator (writes ISSUES.md + BACKLOG.md from live gh, or a fixture)
scripts/gen-mirrors.sh .

# B3 loop-setup acceptance
bash tests/loop-setup/acceptance.sh

# B2 mirror acceptance
bash tests/repo-state/mirrors.sh

# C2 gate registry + freshness check
scripts/gen-gate-registry.sh .            # regenerates docs/gate-registry.md
bash tests/gates/check.sh                 # exit 0 gate: registry fresh + no untagged gate

# C3 knob persistence + STOP guard
scripts/loop-auto.sh set auto             # writes docs/chain-state.md
scripts/loop-auto.sh get                  # prints current mode
bash tests/gates/loop-auto.sh             # exit 0 gate: set/get/preflight

# Installer (symlinks the new/moved skills, refreshes managed block, runs doctors)
./install.sh
```

---

### Task B1: repo-state convention config, schema, and CLAUDE.md pointer

Depends on: none

**Files (exclusive ownership):**
- Create: `config/repo-state.template.md` (the single schema source; B3's `setup.sh` reads this too)
- Create: `config/repo-state.md` (this repo's config, rendered from the template)
- Create: `CLAUDE.md` (repo root - does not exist yet; single-line pointer plus nothing else load-bearing)
- Modify: `.gitignore` (add `docs/chain-state.md` - runtime state, never committed, per rubix A1/B4)
- Test: `tests/repo-state/config.sh`

**Interfaces:**
- Produces: `config/repo-state.template.md` - the lane schema with a `{{REMOTE_OR_FALLBACK}}` placeholder, the single authored copy of the schema. `config/repo-state.md` is that template rendered for this repo (has a remote); B3 renders new repos from the same file, so the two cannot drift.
- Produces: the lane names and homes that B3, B4, B5, C2, C3 read. The canonical homes, verbatim:
  - Roadmap -> `docs/roadmap.md`
  - Issues -> GitHub issues, open, without the `idea` label; mirror `ISSUES.md`
  - Backlog -> GitHub issues labeled `idea`; mirror `BACKLOG.md`
  - Handoffs -> `docs/handoffs/YYYY-MM-DD-<slug>.md`
  - Chain state -> `docs/chain-state.md`
  - Batch reviews -> `docs/reviews/YYYY-MM-DD-<slug>-batch-review.md`
  - Archive -> `docs/archive/`
- Produces: the regen command string `scripts/gen-mirrors.sh .` (cited in the config's Issues/Backlog `How` column).
- Produces: the `idea` label as the one load-bearing label; unlabeled (optionally `bug`/`refactor`) is the Issues lane.
- Produces: the Backlog lane documents BOTH the cross-repo view (`gh search issues --owner jroethel --label idea --state open`) AND its per-repo fallback (`gh issue list --label idea --state open`) for when private-repo search is unavailable (rubix A3/B3).

**Acceptance check:** `bash tests/repo-state/config.sh` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test.

```bash
#!/usr/bin/env bash
# Structural check for config/repo-state.md and the repo CLAUDE.md pointer.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
CFG="$REPO/config/repo-state.md"
TPL="$REPO/config/repo-state.template.md"
CLAUDEMD="$REPO/CLAUDE.md"
GI="$REPO/.gitignore"
fail() { echo "FAIL: $1" >&2; exit 1; }

[ -f "$TPL" ] || fail "config/repo-state.template.md missing (single schema source)"
[ -f "$CFG" ] || fail "config/repo-state.md missing"
# template and this repo's config carry the same lane set (drift guard, rubix B5)
for lane in Roadmap Issues Backlog Handoffs "Chain state" "Batch reviews" Archive; do
  grep -qi "$lane" "$TPL" || fail "template does not name the '$lane' lane"
  grep -qi "$lane" "$CFG" || fail "config/repo-state.md does not name the '$lane' lane"
done
# chain-state is gitignored runtime state (rubix A1/B4)
grep -q 'docs/chain-state.md' "$GI" || fail ".gitignore does not exclude docs/chain-state.md"
# "where I left off" degrades to git, not to nothing (rubix A4)
grep -Eqi 'git (log|status)' "$CFG" || fail "Handoffs lane missing the git fallback for 'where I left off'"
grep -q 'docs/roadmap.md'      "$CFG" || fail "roadmap home not declared"
grep -q 'ISSUES.md'            "$CFG" || fail "ISSUES.md mirror not declared"
grep -q 'BACKLOG.md'           "$CFG" || fail "BACKLOG.md mirror not declared"
grep -q 'docs/chain-state.md'  "$CFG" || fail "chain-state home not declared (C consumes this)"
grep -q 'docs/reviews/'        "$CFG" || fail "batch-review home not declared (C consumes this)"
grep -q 'docs/handoffs/'       "$CFG" || fail "handoff home not declared"
grep -q 'scripts/gen-mirrors.sh' "$CFG" || fail "mirror regen command not declared"
grep -qi '## *Fallback'        "$CFG" || fail "no-remote fallback section missing"
grep -qi 'idea'                "$CFG" || fail "the 'idea' backlog label not documented"
grep -Eqi '## *Archive and graduation' "$CFG" || fail "archive/graduation rules section missing"
grep -qi 'Source brief:'       "$CFG" || fail "graduated-item issue template (Source brief/Restart) missing"
[ -f "$CLAUDEMD" ] || fail "repo CLAUDE.md missing"
grep -q 'config/repo-state.md' "$CLAUDEMD" || fail "CLAUDE.md pointer to config/repo-state.md missing"
echo "PASS: config/repo-state.md and CLAUDE.md pointer complete"
```

- [ ] Step 2: Run it - `bash tests/repo-state/config.sh` - expected FAIL with `config/repo-state.template.md missing`.
- [ ] Step 3: Write `config/repo-state.template.md` to the schema in Resolved open questions (lane table with `Home`/`How`, a `{{REMOTE_OR_FALLBACK}}` placeholder, `## Fallback (no remote)` naming the local-markdown tracker, `## Archive and graduation rules` carrying the five archive rules and the graduated-item issue template). The Handoffs lane states the git fallback for "where I left off". Render `config/repo-state.md` from it with the placeholder filled for this repo (has a remote). Add `docs/chain-state.md` to `.gitignore`. Create the root `CLAUDE.md` with the single pointer line.
- [ ] Step 4: Run it - expected PASS.
- [ ] Step 5: Commit - `git add config/repo-state.template.md config/repo-state.md CLAUDE.md .gitignore tests/repo-state/config.sh && git commit -m "seam B: repo-state convention template + this-repo config + CLAUDE.md pointer"`.

---

### Task B2: mirror generator

Depends on: none

**Files (exclusive ownership):**
- Create: `scripts/gen-mirrors.sh`
- Test: `tests/repo-state/mirrors.sh`
- Test fixture: `tests/repo-state/fixtures/issues.json`

**Interfaces:**
- Produces: `scripts/gen-mirrors.sh <out-dir>` - writes `<out-dir>/ISSUES.md` and `<out-dir>/BACKLOG.md`.
  Reads issue JSON from `gh issue list --state open --json number,title,labels,updatedAt --limit 500`
  unless `MIRRORS_JSON_FILE` is set (test hook), in which case it reads that file.
- Behavior: an issue is Backlog if any of its labels is `idea`, else Issues. Sort by `number` descending.
  Each mirror opens with an HTML-comment header: generation time (ISO 8601), `source of truth: GitHub issues`,
  `regenerate: scripts/gen-mirrors.sh <out-dir>`, `DO NOT EDIT`. Then an H1, then a table
  `| # | title | labels | updated |`.

**Acceptance check:** `bash tests/repo-state/mirrors.sh` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test and fixture.

```bash
#!/usr/bin/env bash
# gen-mirrors.sh splits idea/non-idea, discloses a header, never calls live gh under the fixture hook.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
GEN="$REPO/scripts/gen-mirrors.sh"
FIX="$HERE/fixtures/issues.json"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$GEN" ] || fail "scripts/gen-mirrors.sh missing or not executable"

OUT="$(mktemp -d)"; trap 'rm -rf "$OUT"' EXIT
MIRRORS_JSON_FILE="$FIX" "$GEN" "$OUT" || fail "gen-mirrors exited non-zero under fixture"

[ -f "$OUT/ISSUES.md" ]  || fail "ISSUES.md not written"
[ -f "$OUT/BACKLOG.md" ] || fail "BACKLOG.md not written"
# disclosure headers
grep -qi 'DO NOT EDIT'          "$OUT/ISSUES.md"  || fail "ISSUES.md missing DO NOT EDIT disclosure"
grep -qi 'regenerate'           "$OUT/ISSUES.md"  || fail "ISSUES.md missing regen command"
grep -qi 'source of truth'      "$OUT/BACKLOG.md" || fail "BACKLOG.md missing source-of-truth disclosure"
# lane split, anchored to a real table row (rubix B7 - bare grep '101' matches timestamps/counts)
row() { grep -En "^\| *$1 *\|" "$2" | head -1 | cut -d: -f1; }  # -> line number of the #N row, empty if absent
[ -n "$(row 101 "$OUT/BACKLOG.md")" ] || fail "idea issue #101 is not a table row in BACKLOG.md"
[ -n "$(row 103 "$OUT/BACKLOG.md")" ] || fail "idea issue #103 is not a table row in BACKLOG.md"
[ -z "$(row 101 "$OUT/ISSUES.md")"  ] || fail "idea issue #101 leaked into ISSUES.md"
[ -n "$(row 102 "$OUT/ISSUES.md")"  ] || fail "non-idea issue #102 is not a table row in ISSUES.md"
[ -z "$(row 102 "$OUT/BACKLOG.md")" ] || fail "non-idea issue #102 leaked into BACKLOG.md"
# descending sort by number: within BACKLOG, #103's row must precede #101's row
[ "$(row 103 "$OUT/BACKLOG.md")" -lt "$(row 101 "$OUT/BACKLOG.md")" ] \
  || fail "BACKLOG.md not sorted by issue number descending (#103 should precede #101)"
echo "PASS: mirror split, disclosure, table-row anchoring, and descending sort all verified"
```

Fixture `tests/repo-state/fixtures/issues.json` (mirrors `gh issue list --json` shape; two idea rows exercise the sort):

```json
[
  {"number":102,"title":"crash on empty input","labels":[{"name":"bug"}],"updatedAt":"2026-08-01T10:00:00Z"},
  {"number":101,"title":"cross-repo digest idea","labels":[{"name":"idea"}],"updatedAt":"2026-07-30T09:00:00Z"},
  {"number":103,"title":"vault backlog view","labels":[{"name":"idea"}],"updatedAt":"2026-08-02T11:00:00Z"}
]
```

- [ ] Step 2: Run it - `bash tests/repo-state/mirrors.sh` - expected FAIL with `scripts/gen-mirrors.sh missing`.
- [ ] Step 3: Implement `scripts/gen-mirrors.sh` against the Interfaces contract. Parse JSON with whatever is present (`jq` if available, else a `gh ... --template` or a small awk fallback - the check does not assume `jq`, so prefer `gh`'s `--jq`/`--template`; under the fixture hook read the file and parse it the same way). `chmod +x`.
- [ ] Step 4: Run it - expected PASS.
- [ ] Step 5: Commit - `git add scripts/gen-mirrors.sh tests/repo-state/mirrors.sh tests/repo-state/fixtures/issues.json && git commit -m "seam B: disclosed mirror generator"`.

---

### Task B3: loop-setup skill

Depends on: Task B1, Task B2

**Files (exclusive ownership):**
- Create: `skills/loop-setup/SKILL.md`
- Create: `skills/loop-setup/setup.sh`
- Test: `tests/loop-setup/acceptance.sh`

**Interfaces:**
- Consumes: `config/repo-state.template.md` from B1 (the single schema source it renders into a new repo's config - never a second hand-copied schema, per rubix B5).
- Consumes: the mirror regen command from B2 (`scripts/gen-mirrors.sh`).
- Produces: `setup.sh` - the runnable, **idempotent** core (safe to re-run; skip-if-exists on config, label, and every `docs/` home). It (a) detects a GitHub remote via `git remote`, (b) renders `config/repo-state.md` from the template, (c) creates `docs/roadmap.md` and the `docs/handoffs/`, `docs/reviews/`, `docs/archive/` homes, (d) with a remote, ensures the `idea` label exists (`gh label create idea` skipped if present) and generates mirrors; without a remote, records the local-markdown tracker fallback (`.scratch/<feature>/issues/`, Matt's convention). **Both branches live in `setup.sh` so the executed check exercises them (rubix A6); the SKILL.md only narrates and invokes it.** Under `MIRRORS_JSON_FILE`/a `--dry-run-remote` hook it exercises the remote branch without live `gh`.
- Produces: `skills/loop-setup/SKILL.md` - the LLM-facing wrapper that runs `setup.sh` and explains the result.
- Note: written fresh to the convention. Matt's setup skill is not installed on this machine, so there is no literal file to fork; the brief's "fork" is conceptual (setup runs once per repo, picks a tracker, every downstream skill reads it).

**Acceptance check:** `bash tests/loop-setup/acceptance.sh` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test.

```bash
#!/usr/bin/env bash
# loop-setup: structural (SKILL.md contract) + behavioral (produces a valid config in a bare repo).
# LOOP_SETUP_SKIP_BEHAVIOR=1 runs structural only.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SKILL="$REPO/skills/loop-setup/SKILL.md"
fail() { echo "FAIL: $1" >&2; exit 1; }

# --- structural ---
[ -f "$SKILL" ]                     || fail "skills/loop-setup/SKILL.md missing"
grep -q  '^name: loop-setup' "$SKILL" || fail "frontmatter name is not loop-setup"
grep -q  'config/repo-state.md' "$SKILL" || fail "loop-setup never writes config/repo-state.md"
grep -qi 'remote'            "$SKILL" || fail "loop-setup does not branch on remote presence"
grep -qi 'idea'             "$SKILL" || fail "loop-setup does not create the idea label"
grep -qi 'scratch'          "$SKILL" || fail "loop-setup missing the local-markdown fallback tracker"
grep -q  'scripts/gen-mirrors.sh' "$SKILL" || fail "loop-setup does not cite the mirror regen command"
echo "structural: PASS"
[ "${LOOP_SETUP_SKIP_BEHAVIOR:-0}" = 1 ] && { echo "PASS: structural only"; exit 0; }

# --- behavioral: run the documented no-remote path in a bare repo, assert a valid config lands ---
# The skill documents the exact commands; this test executes the no-remote branch as a script would.
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
( cd "$TMP" && git init -q )
# The executor implements skills/loop-setup/setup.sh as the runnable core the SKILL.md wraps (see Step 3).
SETUP="$REPO/skills/loop-setup/setup.sh"
[ -x "$SETUP" ] || fail "skills/loop-setup/setup.sh missing (runnable core for the executed check)"
( cd "$TMP" && "$SETUP" ) || fail "setup.sh exited non-zero in a bare repo"
[ -f "$TMP/config/repo-state.md" ] || fail "no config/repo-state.md produced in bare repo"
# validate the generated config directly against the same required lanes B1 mandates
for lane in Roadmap Issues Backlog Handoffs Archive; do
  grep -qi "$lane" "$TMP/config/repo-state.md" || fail "generated config missing the '$lane' lane"
done
grep -qi 'fallback\|scratch\|no remote' "$TMP/config/repo-state.md" \
  || fail "bare-repo config did not record the no-remote fallback"

# idempotency: a second run must not error or duplicate (rubix A6)
( cd "$TMP" && "$SETUP" ) || fail "setup.sh is not idempotent (second run errored)"
[ "$(grep -c '## *Fallback' "$TMP/config/repo-state.md")" -le 1 ] \
  || fail "re-running setup.sh duplicated config content"

# remote branch exercised without live gh, via the fixture hook (rubix A6)
TMP2="$(mktemp -d)"; trap 'rm -rf "$TMP" "$TMP2"' EXIT
( cd "$TMP2" && git init -q && git remote add origin https://example.invalid/x.git )
( cd "$TMP2" && MIRRORS_JSON_FILE="$REPO/tests/repo-state/fixtures/issues.json" "$SETUP" --dry-run-remote ) \
  || fail "setup.sh remote branch (dry-run) errored"
[ -f "$TMP2/ISSUES.md" ] || fail "remote branch did not generate mirrors"
grep -qi 'fallback\|scratch\|no remote' "$TMP2/config/repo-state.md" \
  && fail "remote-repo config wrongly recorded the no-remote fallback"
echo "PASS: loop-setup config generation, idempotency, and remote branch all verified"
```

- [ ] Step 2: Run it - expected FAIL with `skills/loop-setup/SKILL.md missing`.
- [ ] Step 3: Write `skills/loop-setup/setup.sh` (idempotent core: detect remote via `git remote`, render `config/repo-state.md` from `config/repo-state.template.md` resolved relative to the script's own location, make the `docs/` homes, run the remote branch - `gh label create idea` skip-if-exists then `scripts/gen-mirrors.sh` - or the fallback branch; under `--dry-run-remote` + `MIRRORS_JSON_FILE`, treat the repo as remote-present and generate mirrors from the fixture without live `gh`). Write `skills/loop-setup/SKILL.md` as the wrapper that runs it and explains the result.
- [ ] Step 4: Run it - expected PASS.
- [ ] Step 5: Commit - `git add skills/loop-setup tests/loop-setup && git commit -m "seam B: loop-setup skill (idempotent per-repo state bootstrap)"`.

---

### Task B4: converged location-aware handoff skill

Depends on: Task B1, Task B2

**Files (exclusive ownership):**
- Create: `skills/handoff/SKILL.md` (moved in from `~/.claude/skills/handoff`, then edited)
- Create: `skills/handoff/agents/` (carry over whatever the source dir holds)
- Test: `tests/handoff/location.sh`

**Interfaces:**
- Consumes: from B1, the handoff home (`docs/handoffs/YYYY-MM-DD-<slug>.md`) and the mirror regen command.
- Produces: a handoff skill that, in a conforming repo (one with `config/repo-state.md`), writes the
  handoff doc to the declared `docs/handoffs/` location and refreshes both mirrors in the same pass
  (`scripts/gen-mirrors.sh .`); outside any repo, writes to the OS temp dir exactly as today.
- Preserves the original skill's content rules: suggested-skills section, no duplication of specs/ADRs/
  commits, secret redaction, argument-as-focus.

**Migration note (call out to the human at install):** `~/.claude/skills/handoff` is currently a real
directory outside the repo. After this task, `./install.sh` will back it up to `~/.claude/handoff.bak`
and symlink `~/.claude/skills/handoff` -> the repo copy. No `install.sh` edit is needed (it already
loops `skills/*`); the backup is automatic and reversible.

**Acceptance check:** `bash tests/handoff/location.sh` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test.

```bash
#!/usr/bin/env bash
# handoff is location-aware: names the in-repo home for conforming repos AND the OS-temp fallback.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SKILL="$REPO/skills/handoff/SKILL.md"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -f "$SKILL" ] || fail "skills/handoff/SKILL.md missing (not moved into the repo)"
grep -q  '^name: handoff'      "$SKILL" || fail "frontmatter name is not handoff"
grep -q  'config/repo-state.md' "$SKILL" || fail "handoff does not consult config/repo-state.md for its location"
grep -q  'docs/handoffs'       "$SKILL" || fail "handoff does not name the in-repo handoffs home"
grep -qi 'temp'               "$SKILL" || fail "handoff dropped the OS-temp-dir fallback"
grep -q  'scripts/gen-mirrors.sh' "$SKILL" || fail "handoff does not refresh mirrors in the same pass"
grep -qi 'suggested skills'    "$SKILL" || fail "handoff lost its suggested-skills section"
grep -qi 'redact'             "$SKILL" || fail "handoff lost its secret-redaction rule"
echo "PASS: handoff is location-aware, mirror-refreshing, and kept its content rules"
```

- [ ] Step 2: Run it - expected FAIL with `skills/handoff/SKILL.md missing`.
- [ ] Step 3: `cp -R ~/.claude/skills/handoff skills/handoff`, then edit `skills/handoff/SKILL.md`: add a "location" step (if `config/repo-state.md` exists in the repo root, write to its declared `docs/handoffs/YYYY-MM-DD-<slug>.md` and run `scripts/gen-mirrors.sh .`; else write to the OS temp dir as today). Keep all original content rules verbatim.
- [ ] Step 4: Run it - expected PASS.
- [ ] Step 5: Commit - `git add skills/handoff tests/handoff && git commit -m "seam B: converge handoff into repo, location-aware + mirror refresh"`.

---

### Task B5: stand up this repo's state (the demonstration)

Depends on: Task B1, Task B2

**Files (exclusive ownership):**
- Create: `ISSUES.md`, `BACKLOG.md` (generated by B2's script)
- Create: `docs/roadmap.md` (seeded)
- Modify: `docs/archive/` (add files only, per the archive human checkpoint)
- Test: `tests/repo-state/live.sh`
- External: creates gh issues on `jroethel/loop-stack-session` (the `idea` label and the graduated items)

**Interfaces:**
- Consumes: B1's config (lane homes), B2's `scripts/gen-mirrors.sh`.
- Produces: this repo's live state - the `idea` label, the live parked items as labeled issues, the two
  mirrors, a seeded `docs/roadmap.md`, and any offered-and-accepted archive moves.

**Live parked items to graduate (from the briefs' parking lots and ledger loose ends):**
- loop-review brief parking-lot items (see `docs/briefs/2026-07-21-loop-review-brief.md`).
- Ledger loose ends that are ideas, not done work (`docs/2026-08-02-settled-decisions-and-sequence.md`).
- The seam B and seam C parking-lot entries that outlive this plan (mass sprawl migration, triage-state
  labels, per-repo knob default, spec-edit-gate relaxation, quota-aware auto-resume).
  Each becomes one `gh issue create --label idea` with the graduated-item template body from B1.
- **Idempotency guard (rubix B3):** `gh issue create` mints irreversible outward-facing state, so before
  creating each issue, query existing open `idea` titles (`gh issue list --label idea --state open --json title`)
  and skip any whose title already exists. Re-running B5 (or a second migration) must never duplicate issues.

**Acceptance check:** `bash tests/repo-state/live.sh` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test.

```bash
#!/usr/bin/env bash
# This repo's live state exists: mirrors present + disclosed, roadmap present, idea issues queryable,
# and the cross-repo backlog command returns this repo's idea issues.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }

[ -f "$REPO/ISSUES.md" ]      || fail "ISSUES.md not stood up"
[ -f "$REPO/BACKLOG.md" ]     || fail "BACKLOG.md not stood up"
[ -f "$REPO/docs/roadmap.md" ] || fail "docs/roadmap.md not seeded"
grep -qi 'DO NOT EDIT' "$REPO/ISSUES.md"  || fail "ISSUES.md not a disclosed mirror"
grep -qi 'DO NOT EDIT' "$REPO/BACKLOG.md" || fail "BACKLOG.md not a disclosed mirror"

# at least one idea issue exists on this repo (index-free path - the hard gate, rubix A3/B3)
N="$(gh issue list --label idea --state open --json number --jq 'length' 2>/dev/null)" \
  || fail "gh issue list failed (auth or remote?)"
[ "${N:-0}" -ge 1 ] || fail "no open 'idea' issues on this repo - live parked items not graduated"

# cross-repo backlog command is ADVISORY, not a hard gate: the brief marks gh-search-over-private-repos
# a guess, and the search index lags issue creation by seconds-to-minutes. Warn on miss, never fail.
if gh search issues --owner jroethel --label idea --state open --json repository \
     --jq '.[].repository.name' 2>/dev/null | grep -q 'loop-stack-session'; then
  echo "note: cross-repo 'gh search issues' resolves this repo's idea issues"
else
  echo "WARNING: cross-repo 'gh search issues' did not return this repo (private-repo indexing or lag)."
  echo "         Fallback documented in config/repo-state.md: per-repo 'gh issue list --label idea'."
fi
echo "PASS: live mirrors, roadmap, and idea issues resolve (cross-repo view advisory)"
```

- [ ] Step 2: Run it - expected FAIL with `ISSUES.md not stood up`.
- [ ] Step 3: `gh label create idea --description "backlog: idea to revisit" --color a2eeef` (skip if exists). **Human checkpoint (graduation review):** for each parked item, first check `gh issue list --label idea --state open --json title` and skip any title that already exists (idempotency guard); print each surviving `gh issue create --label idea --title ... --body ...` command with its template body; on approval, run them. Seed `docs/roadmap.md` with this repo's ordered roadmap (the build wave and its downstream). Run `scripts/gen-mirrors.sh .`. **Human checkpoint (archive offer):** list archive candidates (completed plans auto; the xlsx and mattpocock dump offered) and move accepted ones to `docs/archive/`.
- [ ] Step 4: Run it - expected PASS.
- [ ] Step 5: Commit - `git add ISSUES.md BACKLOG.md docs/roadmap.md docs/archive tests/repo-state/live.sh && git commit -m "seam B: stand up this repo's live state (mirrors, roadmap, graduated backlog)"`.

---

### Task C1: gate taxonomy tags in the four chain skill texts

Depends on: none

**Files (exclusive ownership):**
- Modify: `skills/loop-brainstorm/SKILL.md`
- Modify: `skills/loop-plan/SKILL.md`
- Modify: `skills/loop-drive/SKILL.md`
- Modify: `skills/loop-which/SKILL.md`
- Test: `tests/gates/tags.sh`

**Interfaces:**
- Produces: a `` `[gate:TYPE]` `` token on the line where each gate fires, TYPE in {ASK, STOP, BATCH, DEFAULT}.
  Tags only; no other content changes to these four files (the tags-only invariant).
- Produces: the tagged sites C2's registry generator will scan.

**Gate inventory (the tagging spec - tag exactly these session-pause sites):**

| Skill           | Where                                             | Type    |
|-----------------|---------------------------------------------------|---------|
| loop-brainstorm | Step 3 clarifying questions (interview)           | ASK     |
| loop-brainstorm | Steps 5-6 present brief section-by-section        | DEFAULT |
| loop-brainstorm | Step 8 commit offer                               | DEFAULT |
| loop-brainstorm | Step 9 terminal handoff to next stage             | DEFAULT |
| loop-plan       | Step 2 resolve open questions (ask the user)      | ASK     |
| loop-plan       | Step 6 rubix offer                                | DEFAULT |
| loop-plan       | Step 6 rubix triage (user picks findings)         | BATCH   |
| loop-plan       | Step 7 user review + commit offer                 | DEFAULT |
| loop-plan       | Step 8 pinned handoff                             | DEFAULT |
| loop-which      | Step 2 availability probe                         | ASK     |
| loop-which      | Step 5 proceed on the verdict                     | DEFAULT |
| loop-drive      | Step 0 topology pick when two shapes are close    | BATCH   |
| loop-drive      | Step 0/5 pre-flight dirty tree                    | STOP    |
| loop-drive      | Step 2/5 exceed the effort cap                    | STOP    |
| loop-drive      | Step 5 spec edits beyond a clarification          | STOP    |
| loop-drive      | Step 5 outward-facing unit                        | STOP    |
| loop-drive      | Step 5 twice-failed unit with a design issue      | STOP    |
| loop-drive      | Step 5 terminal loop-review findings              | BATCH   |
| loop-drive      | Step 7 drive dashboard ask                        | DEFAULT |

Not a gate (rubix B8): loop-plan's "route every `[judgment]` criterion to a human checkpoint" is a property
of the plan loop-plan *writes*, not a point where the loop-plan session itself pauses; it is not tagged, so
the knob never treats it as a pausable runtime gate. The `[judgment]` gates it refers to fire later, inside
loop-drive's Step 1 halt and its gate checklist, which are already covered above.
The brief counts 19; this inventory lists 19 session-pause sites. Tag them as they actually read; the registry
lists whatever is tagged, and the count is not itself a gate.

**Acceptance check:** `bash tests/gates/tags.sh` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test.

```bash
#!/usr/bin/env bash
# Every chain skill carries gate tags; all four types appear; tags are well-formed; and the diff is
# TAGS ONLY - stripping the tags from working tree and baseline yields byte-identical text (rubix B2).
# Run at Step 4 (before the Step 5 commit) so the baseline ref is the pre-edit skill text.
# TAGS_BASE_REF overrides the baseline (default HEAD).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
BASE="${TAGS_BASE_REF:-HEAD}"
fail() { echo "FAIL: $1" >&2; exit 1; }
SKILLS="loop-brainstorm loop-plan loop-drive loop-which"
TOK='\[gate:(ASK|STOP|BATCH|DEFAULT)\]'
strip_tags() { sed -E 's/`?\[gate:(ASK|STOP|BATCH|DEFAULT|none)\]`?//g'; }

total=0
for s in $SKILLS; do
  f="$REPO/skills/$s/SKILL.md"
  [ -f "$f" ] || fail "skills/$s/SKILL.md missing"
  n="$(grep -oE "$TOK" "$f" | wc -l | tr -d ' ')"
  [ "$n" -ge 1 ] || fail "$s carries no gate tag"
  total=$((total + n))
  # tags-only invariant: current file minus tags == baseline file minus tags
  if git -C "$REPO" cat-file -e "$BASE:skills/$s/SKILL.md" 2>/dev/null; then
    diff <(git -C "$REPO" show "$BASE:skills/$s/SKILL.md" | strip_tags) \
         <(strip_tags < "$f") >/dev/null \
      || fail "$s changed more than tags (prose differs after stripping gate tags) - tags-only violated"
  fi
done
[ "$total" -ge 15 ] || fail "only $total gate tags across the chain; inventory expects ~19"
# all four types present somewhere
for t in ASK STOP BATCH DEFAULT; do
  grep -rqE "\[gate:$t\]" "$REPO"/skills/loop-*/SKILL.md || fail "type $t never used"
done
# STOP appears in loop-drive specifically (its gates are the STOP class)
grep -qE '\[gate:STOP\]' "$REPO/skills/loop-drive/SKILL.md" || fail "loop-drive missing STOP tags"
# no malformed tags
if grep -rEn '\[gate:[a-z]' "$REPO"/skills/loop-*/SKILL.md | grep -vE '\[gate:none\]'; then
  fail "lowercase/malformed gate tag found (types are upper-case)"
fi
echo "PASS: $total gate tags, all four types, STOP in loop-drive, diff is tags-only vs $BASE"
```

- [ ] Step 2: Run it - `bash tests/gates/tags.sh` - expected FAIL with `only 0 gate tags across the chain`.
- [ ] Step 3: Add the `` `[gate:TYPE]` `` tokens at the inventory sites. Add nothing else to these four files.
- [ ] Step 4: Run it (before committing, so the tags-only diff compares against the pre-edit HEAD) - expected PASS.
- [ ] Step 5: Commit - `git add skills/loop-*/SKILL.md tests/gates/tags.sh && git commit -m "seam C: inline gate-type tags in the four chain skills"`.

---

### Task C2: gate registry generator, freshness check, and installer doctor line

Depends on: Task C1, Task B1, Task B2

**Files (exclusive ownership):**
- Create: `scripts/gen-gate-registry.sh`
- Create: `docs/gate-registry.md` (generated)
- Create: `tests/gates/check.sh`
- Test fixture: `tests/gates/fixtures/` (a tiny tagged skill + one untagged-gate skill for the scanner)
- Modify: `install.sh` (one non-fatal doctor line invoking `tests/gates/check.sh`)

**Interfaces:**
- Consumes: the tags C1 wrote; the disclosed-header shape coded in B2's `scripts/gen-mirrors.sh` (reuse it).
- Produces: `scripts/gen-gate-registry.sh <repo-root>` - scans `skills/loop-*/SKILL.md` for gate tags and
  writes `docs/gate-registry.md`: disclosed header whose timestamp line is verbatim `<!-- generated: <ISO8601> -->`,
  plus `regenerate: scripts/gen-gate-registry.sh .`, `DO NOT EDIT`, and a one-line note that the registry
  reflects **tagged gates only and is not a completeness guarantee** (rubix A5/B1). Then a table grouped by
  type with `skill | type | trigger` per gate - **no line-number column** (rubix A2), so benign prose edits
  that renumber gates never stale the registry.
- Produces: `tests/gates/check.sh` - exits non-zero if (a) the committed registry differs from a fresh
  regeneration once both headers are stripped (stale), or (b) the untagged-gate scanner flags a line.

**Freshness scanner (high-precision, not a prose grep - rubix A5/B1):** the raw signal set matched ~57 lines
against ~20 real gates (headings, dot-graph nodes, "Reading the user" prose), so the scanner is scoped two
ways at once: it considers only lines that (i) fall under a `## Step` heading - skipping frontmatter, the
red-flag tables, the process-flow dot graph, and the "Reading the user" section - and (ii) contain a tight
token: `AskUserQuestion`, `ask once`, `offer the commit`, `Want me to commit`, `human checkpoint`,
`ask the human`, `Wait for the response`. Such a line must carry a `[gate:...]` within +/-2 lines, else the
scanner prints `file:line` and fails. The `` `[gate:none]` `` token suppresses a rare true positive.
`ponytail: scoped-heuristic, not a parser; a gate phrased outside the token set and outside a ## Step section still slips - widen the tokens or tag it when it does.`

**Acceptance check:** `bash tests/gates/check.sh` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test (drives against fixtures so it is hermetic, then also validates the real registry).

```bash
#!/usr/bin/env bash
# Registry is fresh (regenerates identically) and no gate-signal line lacks a tag.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
GEN="$REPO/scripts/gen-gate-registry.sh"
REG="$REPO/docs/gate-registry.md"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$GEN" ] || fail "scripts/gen-gate-registry.sh missing or not executable"
[ -f "$REG" ] || fail "docs/gate-registry.md missing (never generated)"

# (a) freshness: regenerate to a temp root that mirrors skills/, diff registries
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/skills" "$TMP/docs"
cp -R "$REPO"/skills/loop-* "$TMP/skills/"
"$GEN" "$TMP" || fail "gen-gate-registry exited non-zero"
# Strip the whole disclosed-comment header block (everything before the first H1) so the volatile
# timestamp cannot cause a false STALE - rubix B6, where 'grep -vi generated' missed 'generation time'.
strip_header() { awk 'f{print} /^# /{f=1; print}' "$1"; }
diff <(strip_header "$REG") <(strip_header "$TMP/docs/gate-registry.md") >/dev/null \
  || fail "docs/gate-registry.md is STALE - rerun scripts/gen-gate-registry.sh ."

# (b) untagged gate-signal lines (the real skills). Uses the check's own scanner via a flag.
"$GEN" --scan-untagged "$REPO" >/tmp/untagged.$$ 2>&1
if [ -s /tmp/untagged.$$ ]; then rm -f /tmp/untagged.$$; fail "gate-signal line without a tag (see above)"; fi
rm -f /tmp/untagged.$$

# registry is a disclosed mirror
grep -qi 'DO NOT EDIT' "$REG" || fail "registry is not a disclosed mirror"
echo "PASS: registry fresh, disclosed, and no untagged gate-signal lines"
```

- [ ] Step 2: Run it - expected FAIL with `scripts/gen-gate-registry.sh missing`.
- [ ] Step 3: Implement `scripts/gen-gate-registry.sh` (generation + a `--scan-untagged` mode that prints offending file:line for gate-signal lines lacking a nearby tag). Generate the real `docs/gate-registry.md`. Add one line to `install.sh`'s doctor block: `bash "$REPO/tests/gates/check.sh" >/dev/null 2>&1 && echo "found gate registry (fresh)" || echo "WARNING: gate registry stale or gate untagged - run scripts/gen-gate-registry.sh ."` (non-fatal, matching the doctor style).
- [ ] Step 4: Run it - expected PASS. Run `./install.sh` and confirm the new doctor line prints without aborting.
- [ ] Step 5: Commit - `git add scripts/gen-gate-registry.sh docs/gate-registry.md tests/gates/check.sh tests/gates/fixtures install.sh && git commit -m "seam C: gate registry generator + freshness check + doctor line"`.

---

### Task C3: the /loop-auto knob, chain-state persistence, and autonomy rules

Depends on: Task B1

**Files (exclusive ownership):**
- Create: `skills/loop-auto/SKILL.md`
- Create: `scripts/loop-auto.sh`
- Create: `docs/reviews/2026-08-02-sample-batch-review.md` (one worked example, rubix A8)
- Modify: `claude-md/fable.md` (add a `## Chain autonomy` section)
- Test: `tests/gates/loop-auto.sh`

**Interfaces:**
- Consumes: from B1, the chain-state home (`docs/chain-state.md`, gitignored) and the batch-review home (`docs/reviews/`).
- Produces: `scripts/loop-auto.sh {set <pause|auto>|get|preflight <mode>}`:
  - `set` writes `docs/chain-state.md` with `autonomy: <mode>` and a generation stamp; `get` prints the mode
    (`pause` when the file is absent - the unset default); `preflight <mode>` checks dirtiness **excluding the
    chain-state path** (`git status --porcelain -- . ':(exclude)docs/chain-state.md'`, rubix A1/B4) and exits
    non-zero on a dirty tree **in either mode** (the STOP invariant, made executable). Excluding chain-state is
    what lets `set auto` be immediately followed by a passing `preflight` on an otherwise-clean tree.
- Produces: `skills/loop-auto/SKILL.md` - the `/loop-auto` command UX: sets the knob via the script,
  confirms the mode in one line, recognizes the phrase list, points at `docs/chain-state.md` as the single
  source of truth (not `_loop.md`), and **states plainly that until the build wave wires consumption into the
  chain skills, setting `auto` records intent only and changes no runtime behavior** (rubix A7), so no one bets
  an unattended run on an inert knob.
- Produces: one worked `docs/reviews/2026-08-02-sample-batch-review.md` (rubix A8) - a realistic entry per
  gate type, so the checkpoint-4 human judges a concrete artifact, not a format described in the abstract.
- Produces: the `## Chain autonomy` block in `claude-md/fable.md` (injected into `~/.claude/CLAUDE.md` by
  `install.sh`): the four-type behavior rules (ASK always blocks; STOP always halts and states what it needs;
  BATCH auto-takes the named lean and collects for end review; DEFAULT auto-takes the default and logs
  verbosely), the "knob off/unset = today's behavior" rule, the "autonomy takes effect after the last ASK
  gate" rule, the "records intent only until the build wave wires consumption" caveat, the phrase list, and
  the batch-review list format. The format **distinguishes reversal paths by gate type** (rubix A8): DEFAULT
  and commit entries are cheaply revertible (`git revert`/undo the default); BATCH taste entries (topology,
  triage) name a scoped re-run as their honest reversal, since re-running is the only real undo. Plus the
  down-tier-only / never-spawn-Fable continuation rule.

**Acceptance check:** `bash tests/gates/loop-auto.sh` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test.

```bash
#!/usr/bin/env bash
# Knob persists across "sessions" (a fresh process reads the file); set never dirties its own preflight;
# STOP fires in auto mode on real dirty work.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
LA="$REPO/scripts/loop-auto.sh"
SKILL="$REPO/skills/loop-auto/SKILL.md"
CMD="$REPO/claude-md/fable.md"
SAMPLE="$REPO/docs/reviews/2026-08-02-sample-batch-review.md"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$LA" ]    || fail "scripts/loop-auto.sh missing or not executable"
[ -f "$SKILL" ] || fail "skills/loop-auto/SKILL.md missing"

# set/get persistence in an isolated repo with a .gitignored chain-state (mirrors the real repo)
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
( cd "$TMP" && git init -q && echo 'docs/chain-state.md' > .gitignore \
    && git add .gitignore && git commit -q -m init )
( cd "$TMP" && "$LA" set auto ) || fail "loop-auto set auto failed"
[ -f "$TMP/docs/chain-state.md" ] || fail "chain-state file not written"
grep -qi 'autonomy: *auto' "$TMP/docs/chain-state.md" || fail "mode not persisted as auto"
mode="$( cd "$TMP" && "$LA" get )"    # fresh process = across a session boundary
[ "$mode" = "auto" ] || fail "get returned '$mode', not the persisted 'auto'"

# rubix A1/B4: set immediately followed by preflight must PASS on an otherwise-clean tree
( cd "$TMP" && "$LA" preflight auto ) \
  || fail "preflight auto blocked a clean tree - chain-state.md is tripping its own STOP guard"

# unset default is pause
rm -rf "$TMP/docs"
[ "$( cd "$TMP" && "$LA" get )" = "pause" ] || fail "unset default is not 'pause'"

# STOP invariant: real uncommitted WORK halts even in auto mode
( cd "$TMP" && echo dirt > work.txt )
( cd "$TMP" && "$LA" preflight auto ) && fail "preflight auto passed a DIRTY tree (STOP did not fire)"
( cd "$TMP" && git add -A && git commit -q -m clean )
( cd "$TMP" && "$LA" preflight auto ) || fail "preflight auto blocked a CLEAN tree"

# skill + rules content
grep -q  'loop-auto'          "$SKILL" || fail "skill does not name /loop-auto"
grep -q  'docs/chain-state.md' "$SKILL" || fail "skill does not point at the chain-state source of truth"
grep -qi 'run the rest'       "$SKILL" || fail "skill missing the recognized phrase list"
grep -qi 'intent only\|records intent\|no runtime' "$SKILL" \
  || fail "skill does not disclose the knob is inert until the build wave wires it (rubix A7)"
grep -qi '## *Chain autonomy' "$CMD"   || fail "managed CLAUDE.md block missing the Chain autonomy section"
for t in ASK STOP BATCH DEFAULT; do
  grep -q "$t" "$CMD" || fail "autonomy rules do not cover the $t class"
done
grep -qi 'reversal'           "$CMD" || fail "batch-review format does not require a reversal path"
grep -qi 'never.*Fable\|Fable.*never' "$CMD" || fail "continuation rule missing the never-spawn-Fable clause"

# worked sample batch-review exists and distinguishes reversal by gate type (rubix A8)
[ -f "$SAMPLE" ] || fail "no worked sample batch-review for checkpoint 4 to judge"
grep -qi 'reversal\|revert\|re-run' "$SAMPLE" || fail "sample batch-review names no reversal path"
grep -qi 'BATCH'   "$SAMPLE" || fail "sample batch-review lacks a BATCH entry"
grep -qi 'DEFAULT' "$SAMPLE" || fail "sample batch-review lacks a DEFAULT entry"
echo "PASS: knob persists, set never trips its own STOP, STOP fires on real work, rules + sample complete"
```

- [ ] Step 2: Run it - expected FAIL with `scripts/loop-auto.sh missing`.
- [ ] Step 3: Implement `scripts/loop-auto.sh` (set/get/preflight against the Interfaces contract, chain-state excluded from the porcelain check), `skills/loop-auto/SKILL.md` (with the intent-only disclosure), the worked `docs/reviews/2026-08-02-sample-batch-review.md`, and the `## Chain autonomy` section in `claude-md/fable.md`. `chmod +x scripts/loop-auto.sh`.
- [ ] Step 4: Run it - expected PASS. Run `./install.sh` and confirm the managed block now carries `## Chain autonomy`.
- [ ] Step 5: Commit - `git add scripts/loop-auto.sh skills/loop-auto docs/reviews claude-md/fable.md tests/gates/loop-auto.sh && git commit -m "seam C: /loop-auto knob, chain-state persistence, autonomy rules"`.

---

## Post-build verification (run after all tasks, before the final human checkpoint)

```bash
bash tests/repo-state/config.sh
bash tests/repo-state/mirrors.sh
bash tests/loop-setup/acceptance.sh
bash tests/handoff/location.sh
bash tests/repo-state/live.sh
bash tests/gates/tags.sh
bash tests/gates/check.sh
bash tests/gates/loop-auto.sh
./install.sh    # symlinks loop-setup, handoff, loop-auto; refreshes the managed block; doctors pass
```

All eight scripts exit 0 and `install.sh` completes without aborting -> both briefs' `[executed-check]`
criteria are met. The two `[judgment]` criteria and the build-wave demonstration go to the human checkpoints above.
