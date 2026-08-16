# /loop-improve Implementation Plan

> For executors: tasks use checkbox syntax; execute in dependency order; a task is done when its
> acceptance check passes. No specific tooling, harness, or skills are assumed.

**Goal:** Ship a read-only `/loop-improve` audit skill that converges one selected finding into a `/loop-plan`-ready brief, sharing loop-brainstorm's convergence half so a brief-format fix lands in both skills at once.
**Approach:** Extract loop-brainstorm's convergence half (Steps 4-9 detail) into one shared reference and repoint loop-brainstorm at it, then build loop-improve's divergence half (vendored audit playbook, tracker scan, findings table, selection) that hands off into that same shared pipeline.
loop-improve and loop-brainstorm become sibling entry points into one pipeline: the user runs one or the other, never chained.
One source of truth means a brief-section or gate fix edits the shared reference once.
Recorded deviation from the brief: the shared reference ends at the user review gate and commit offer, while graduation and terminal state stay per-skill - the brief assumed those were shared, but their content genuinely differs between the siblings (Rubix review finding, HIGH), and sharing them would graduate the parking lot twice and emit conflicting handoffs.
**Tech stack:** markdown skill prose, bash test scripts, existing repo scripts.
**Source brief:** docs/briefs/2026-08-08-loop-improve-brief.md

## Global constraints

- House style: one sentence per line in all prose; plain dashes only, never an em dash; aligned table pipes; plain commit messages with no co-author line.
- Constraint A: scripts/gen-gate-registry.sh scans ONLY skills/loop-*/SKILL.md, so every `[gate:...]` tag must live in a SKILL.md, never only in a reference file.
- Constraint B: tests/gates/loop-brainstorm.sh greps loop-brainstorm/SKILL.md for the glossary/domain-term probe, the scenario stress-test probe, the "Reading the user" heading, "graduate-parking.sh", and preview/confirm/assent/DEFAULT terms; all must survive the refactor inside SKILL.md itself, with the test unchanged.
- Read-only audit: loop-improve's audit phase never writes source code; the only files a run creates are the brief and journal artifacts, exactly as /improve mandates.
- Never create or close issues without assent: graduation and supersede-close are previewed, assented, and each created/closed issue is announced with its number and title.
- Executor needs nothing installed beyond this repo to run or check any task, with one named authoring input: Task 2 vendors content from two host paths named in its Step 1, and stops rather than improvises if they are absent.
- Gate tags are UPPERCASE only (`[gate:ASK]`, `[gate:DEFAULT]`); a lowercase tag fails tests/gates/tags.sh.

## Dependency graph

```
Task 1 (extract shared reference, repoint loop-brainstorm)
   │
   ├──> Task 2 (loop-improve SKILL.md + vendored playbook)  [needs the shared reference to point at]
   │        │
   │        └──> Task 3 (regenerate registry + gate test + README)  [needs loop-improve gate tags to exist]
   │
   └──────────> Task 3 also reads loop-brainstorm SKILL.md + the shared reference for its anti-drift guard
```

The chain is sequential: Task 1 -> Task 2 -> Task 3.
No two tasks touch the same file, so exclusive ownership holds; nothing here runs in parallel because each task consumes the prior task's output.
The README edit is folded into Task 3 so it sits beside the test that asserts it.

## Human checkpoints

- Criterion 8 (findings quality) `[judgment]`: after a live `/loop-improve` run on loop-stack, a human confirms the table's top findings are ones actually worth briefing; no script can judge this.
- End-to-end dogfood (criterion 1): a human runs `/loop-improve` on loop-stack, answers the skill's `[gate:ASK]` findings-selection round, and confirms the resulting `docs/briefs/YYYY-MM-DD-<topic>-brief.md` carries every pipeline section and is accepted by `/loop-plan` without edits.
- Coverage / graduation / supersede dogfood (criteria 3, 4, 5): during that same run, with a seeded open issue matching a finding, the human confirms the row shows `covered by #N`; with a seeded related issue, `related: #N`; after assent, one new open `idea` issue per unselected finding is announced with number and title; committing a covered finding offers `scripts/tracker.sh close <num>` and records the supersede link, and nothing closes without acceptance.
- Brainstorm regression dogfood (criterion 6): a human runs `/loop-brainstorm` after the refactor and confirms it still produces a brief with all sections and the same gates as before (the automated half is tests/gates/loop-brainstorm.sh staying green).
- Load-bearing note: the gate tests grep for token presence only and cannot verify that a running skill actually reads and follows the shared reference; the criterion-1 and criterion-6 dogfood runs are therefore mandatory checkpoints, not optional confirmation.

## How to run

```sh
# From the repo root (/home/jjrdar/repos/loop-stack-session):

# Task 1 acceptance:
bash tests/gates/loop-brainstorm.sh
bash tests/gates/check.sh

# Task 2 acceptance (registry not yet regenerated, so use the scanner, not check.sh):
scripts/gen-gate-registry.sh --scan-untagged .   # must exit 0

# Task 3 acceptance:
scripts/gen-gate-registry.sh .                   # regenerate docs/gate-registry.md
bash tests/gates/loop-improve.sh
bash tests/gates/check.sh
bash tests/gates/tags.sh

# Full gate suite (run after Task 3):
for t in tests/gates/*.sh; do echo "== $t =="; bash "$t" || echo "FAILED: $t"; done

# Dry-run graduation against a brief (no issues created):
GRADUATE_DRY_RUN=1 scripts/graduate-parking.sh docs/briefs/<the-brief>.md
```

## Success criteria coverage

| Brief criterion                         | Verified by                                                                 |
|-----------------------------------------|-----------------------------------------------------------------------------|
| 1. End-to-end brief accepted by loop-plan | Human checkpoint (end-to-end dogfood)                                      |
| 2. Findings hygiene (evidence/impact/effort/confidence) | Task 3 gate test greps the findings-table contract + dogfood |
| 3. Coverage annotation (covered by / related) | Task 3 gate test greps the render + definitions; seeded-issue dogfood  |
| 4. Graduation of unselected findings    | Task 2 wires graduate-parking.sh unchanged; Task 3 test greps it; dogfood   |
| 5. Supersede-close offer + link         | Task 3 gate test greps `scripts/tracker.sh close` + `Supersedes: #`; dogfood |
| 6. Brainstorm regression                | Task 1 acceptance: tests/gates/loop-brainstorm.sh passes unchanged; dogfood |
| 7. Read-only audit                      | Task 3 gate test greps the read-only statement; dogfood confirms clean tree |
| 8. Findings quality                     | Human checkpoint (judgment)                                                 |

### Task 1: Extract the shared convergence reference and repoint loop-brainstorm

Depends on: none

**Files (exclusive ownership):**
- Create: skills/loop-brainstorm/references/brief-pipeline.md
- Modify: skills/loop-brainstorm/SKILL.md
- Test: tests/gates/loop-brainstorm.sh (unchanged, run only), tests/gates/check.sh (unchanged, run only)

**Interfaces:**
- Consumes: the existing Steps 4-9 prose in skills/loop-brainstorm/SKILL.md.
- Produces: skills/loop-brainstorm/references/brief-pipeline.md holding the convergence-half detail; the phrase `Three bins: verified` (the brief section table row) lives ONLY in this reference after this task; loop-brainstorm/SKILL.md retains a numbered step skeleton with its gate tags on the exact heading lines listed below.

**Acceptance check:** `bash tests/gates/loop-brainstorm.sh && bash tests/gates/check.sh` both print `PASS`, tagged [executed-check].

- [ ] Step 1: Create skills/loop-brainstorm/references/brief-pipeline.md. Move into it, verbatim, the detailed prose currently in SKILL.md for the convergence half UP TO AND INCLUDING the user review gate and commit offer: the Step 4 Approaches guidance, the brief section table (the full `| Section | Contents |` table including the `| Known vs guessed | Three bins: verified / believed-unchecked / guessed ... |` row), the Checkability tagging rule, the "What the brief is not" paragraph, the Step 7 Self-review checklist, and the Step 8 user-review-gate and commit-offer prose. One sentence per line, plain dashes.
  The shared reference ENDS at the accepted commit: the Step 8 parking-lot graduation detail (preview/assent/announce, the graduate-parking.sh invocation) and the Step 9 terminal-state prose STAY in loop-brainstorm/SKILL.md, because those two bodies genuinely differ between the sibling skills (brainstorm graduates parked threads and offers both /loop-plan and frontier-sandwich; loop-improve graduates unselected findings and hands only to /loop-plan).
  End the reference with an explicit return line: "Graduation and the terminal state are the calling skill's own steps - return to the calling SKILL.md after the commit offer resolves."
- [ ] Step 2: In skills/loop-brainstorm/SKILL.md, keep Steps 1-3 (Explore context, the three scope probes, Step 2b domain-modeling probe with glossary + scenario stress-test, Step 3 clarifying questions with the "Reading the user" block) completely unchanged; these are the divergence half and carry the Constraint B grep targets.
- [ ] Step 3: Replace the moved bodies (Steps 4 through the Step 8 review-gate/commit-offer prose) with summaries that (a) retain load-bearing grep targets and (b) carry an IMPERATIVE pointer, not a bare citation: "Read `references/brief-pipeline.md` in full and follow it before proceeding - do not summarize it from memory." A passive "detail in references/..." line is a known skip risk for a running model; the imperative wording is the contract.
  Step 8's retained graduation body keeps the literal `scripts/graduate-parking.sh` and its preview/assent prose (tests/gates/loop-brainstorm.sh greps both), and Step 9's terminal-state body stays whole.
- [ ] Step 4: Preserve these four heading lines VERBATIM (text and gate tag), because tests/gates/check.sh regenerates docs/gate-registry.md from them and diffs against the committed registry; any reword changes an excerpt and fails the freshness check:
  - `` ## Step 3 - Clarifying questions in rounds`[gate:ASK]` ``
  - `` ## Steps 5-6 - The brief`[gate:DEFAULT]` ``
  - `` ## Step 8 - User review gate`[gate:DEFAULT]` ``
  - `` ## Step 9 - Terminal state (pinned)`[gate:DEFAULT]` ``
- [ ] Step 5: Confirm the phrase `Three bins: verified` no longer appears anywhere in skills/loop-brainstorm/SKILL.md (it moved to the reference); the bare phrase `Known vs guessed` MAY remain in the Step 2b prose and that is expected.
- [ ] Step 6: Run the acceptance check. If check.sh reports STALE, a gate heading line was reworded in Step 3/4; restore it verbatim rather than regenerating docs/gate-registry.md (that file is owned by Task 3, and loop-brainstorm's rows must not change here).
- [ ] Step 7: Commit.
  ```sh
  git add skills/loop-brainstorm/references/brief-pipeline.md skills/loop-brainstorm/SKILL.md
  git commit -m "loop-brainstorm: extract convergence half (Steps 4-9) into shared references/brief-pipeline.md"
  ```

### Task 2: loop-improve skill and vendored audit playbook

Depends on: Task 1 (loop-improve's convergence pointer targets the shared reference produced by Task 1)

**Files (exclusive ownership):**
- Create: skills/loop-improve/SKILL.md
- Create: skills/loop-improve/references/audit-playbook.md
- Test: `scripts/gen-gate-registry.sh --scan-untagged .` (run only; docs/gate-registry.md is regenerated in Task 3)

**Interfaces:**
- Consumes: skills/loop-brainstorm/references/brief-pipeline.md (the shared convergence half, referenced by absolute path); scripts/tracker.sh (the `list`, `create`, `close` subcommands); scripts/graduate-parking.sh (unchanged, parses a brief's `## Parking lot` section); config/repo-state.md (lanes, the `idea` label, graduated-item template).
- Produces: skills/loop-improve/SKILL.md carrying frontmatter, the hard gate, the findings-table contract, the tracker-scan wiring, the `[gate:ASK]` selection round and `[gate:DEFAULT]` convergence steps; skills/loop-improve/references/audit-playbook.md carrying the attribution header, all 9 categories, the Finding format, and the effort table. install.sh's `skills/*` glob auto-installs the new directory, so no install.sh change is needed.

**Acceptance check:** `scripts/gen-gate-registry.sh --scan-untagged .` exits 0 (no untagged gate-signal line), tagged [executed-check].

- [ ] Step 1: Create skills/loop-improve/references/audit-playbook.md by vendoring from two named host sources: the category/finding content from `~/.claude/skills/improve/references/audit-playbook.md` (all 9 categories - Correctness/Bugs, Security, Performance, Test Coverage, Tech Debt & Architecture, Dependencies & Migrations, DX & Tooling, Docs, Direction - plus the Finding format block and the Prioritization rubric) and the quick/standard/deep effort-table concept from the Phase 2 table in `~/.claude/skills/improve/SKILL.md`.
  If either source path is missing on this host, STOP and report back instead of improvising the content.
  Prepend this attribution header verbatim as the first content after the H1:
  ```markdown
  > Source: the improve skill by shadcn, MIT, version 1.0.0, vendored 2026-08-08.
  ```
- [ ] Step 2: In the vendored playbook, rephrase every sentence that references /improve's plans/ machinery into brief/backlog terms. The source carries FIVE such lines, and all five must be recast (Task 3's test asserts the absence of three tell-tale strings):
  - The low-confidence line "LOW-confidence findings may be reported but get an 'investigate' plan, not a 'fix' plan" - recast as: a LOW-confidence finding selected for briefing is briefed as investigation scope, not build scope.
  - The direction line "Plans for selected direction findings are usually a design/spike plan (investigate, prototype...) rather than a build-everything plan" - recast in brief terms: a selected direction finding briefs as a design/spike outcome, and the strings matched by `grep -i "investigate.*plan"` must not survive.
  - The secret-handling line "never copy a secret value into a finding or plan - those files get committed" - the rule stays (it is still true: the brief gets committed) but recast the object: "never copy a secret value into a finding or the brief - the brief gets committed"; the exact string `those files get committed` must not survive.
  - The DX line recommending a CLAUDE.md "for repos where agents will execute the plans ... include its outline as a plan" - recast as: recommend one as a briefable finding; the exact string `execute the plans` must not survive.
  - The Finding-format Fix-sketch line "Not the plan - just enough to judge effort honestly" - recast as "Not the brief - just enough to judge effort honestly".
- [ ] Step 3: Create skills/loop-improve/SKILL.md frontmatter. Use this description verbatim (it must trigger on the listed phrases and state the read-only + one-brief contract):
  ```yaml
  ---
  name: loop-improve
  description: >
    Audit this repo for improvements and converge the one worth doing into a single approved brief.
    Surveys the codebase as a senior advisor, scans the Issues and Backlog lanes for overlap, and
    presents a vetted findings table; the user selects one finding and it converges to ONE brief for
    /loop-plan. Read-only on source code - it never fixes, refactors, or scaffolds. Triggers on
    "audit this repo for improvements", "what should I improve", "improvement brief", and loop-improve.
  ---
  ```
- [ ] Step 4: Add a `<HARD-GATE>` block stating loop-improve is read-only on source code, writes no file other than the brief, creates no issue and closes none without assent, and invokes no planning or implementation skill until the brief is approved. Include the literal phrase `read-only` (Task 3 greps it).
- [ ] Step 5: Write the step skeleton. Place gate tags on the `## Step` heading lines so scan_one's per-step coverage applies (this guarantees `--scan-untagged` exits 0). Use this structure:
  - `## Step 1 - Resolve effort and focus` (no gate): parse an optional focus argument (example `/loop-improve security`) and a `quick` / `standard` / `deep` keyword, default `standard`, per the vendored playbook's effort table; include the literal tokens `focus` and `quick`/`standard`/`deep`.
  - `## Step 2 - Audit (read-only)` (no gate): run the vendored playbook categories, depth set by the effort knob; state that the audit reads code and never writes it, and that finding rows require file:line evidence (no vibes-only rows).
  - `## Step 3 - Scan the tracker` (no gate): one call to `scripts/tracker.sh list` (gh-shaped JSON with number, title, labels in BOTH github and local modes), then model judgment matches findings to issue titles; when a title is ambiguous, read the body (`gh issue view N` in github mode, `docs/issues/NNN-*.md` in local mode). Include the literal string `scripts/tracker.sh list`.
  - `` ## Step 4 - Present findings and select`[gate:ASK]` ``: present the findings table, then the user selects exactly one finding via AskUserQuestion. Covered findings stay selectable.
  - `` ## Step 5 - Converge through the shared brief pipeline`[gate:DEFAULT]` ``: an IMPERATIVE pointer, not a bare citation: "Read `~/.claude/skills/loop-brainstorm/references/brief-pipeline.md` in full and follow it before proceeding - do not summarize it from memory." Scope it explicitly: follow the shared reference from approaches through the user review gate and commit offer, then return to Step 6 here; the shared reference contains NO graduation and NO terminal state, and loop-improve's own Steps 6-7 are the sole graduation and terminal. While authoring the brief in this step, write each unselected finding NOT covered by an existing open issue into the brief's `## Parking lot` section (bullet shape defined in Step 6). Record `Supersedes: #N` in the brief when the selected finding was covered.
  - `` ## Step 6 - Leftover graduation and supersede-close`[gate:DEFAULT]` ``: after the Step 5 commit is accepted, ride `scripts/graduate-parking.sh <brief-path>` unchanged (preview count + titles, assent, announce each `idea` issue with number and title). Parking-lot bullet shape, stated in the skill: the first sentence is the derived issue title and MUST be period-free and filename-free (graduate-parking.sh truncates the title at the first dot, so a leading `tracker.sh` or `config/repo-state.md` self-truncates); every dotted `file:line` token and the impact one-liner ride the indented `Restart context:` continuation, which reaches the issue body untouched. Unselected findings that ARE covered by an existing open issue are never graduated and appear only as a table annotation. For a selected covered finding, offer `scripts/tracker.sh close <num>` (assented, announced); declining leaves the issue open with the `Supersedes: #N` link still recorded, and the skill states in one line that closing at brief time rather than merge time is the deliberate, brief-mandated choice. Include the literals `scripts/graduate-parking.sh`, `Parking lot`, and `scripts/tracker.sh close`.
  - `` ## Step 7 - Terminal state`[gate:DEFAULT]` ``: name the approved brief path and hand to `/loop-plan`; loop-improve never invokes /loop-which or /loop-drive and never invokes an implementation skill. Include the literal `/loop-plan`.
- [ ] Step 6: Add the findings-table contract to Step 2 (or a dedicated subsection). The header row is exactly these columns in this order: `# | Finding | Category | Impact | Effort | Risk | Confidence | Tracker`, rendered as an aligned markdown pipe table. State that every row carries file:line evidence, impact, effort (S/M/L), and confidence. State the Tracker column renders `covered by #N`, `related: #N`, or `-`, and define the two: `covered` = the issue's ask and the finding's fix are the same work; `related` = same area, different ask. The prose must contain the literal strings `covered by #`, `related: #`, `same work`, and `different ask`.
- [ ] Step 7: Run the acceptance check `scripts/gen-gate-registry.sh --scan-untagged .` and confirm exit 0. If it flags a line in loop-improve/SKILL.md, a gate-signal token (AskUserQuestion, "offer the commit", "wait for the response") sits under a `## Step` heading without a covering tag; move the tag onto that step's heading.
- [ ] Step 8: Commit.
  ```sh
  git add skills/loop-improve/SKILL.md skills/loop-improve/references/audit-playbook.md
  git commit -m "loop-improve: add read-only audit skill sharing the brief pipeline, plus vendored MIT audit playbook"
  ```

### Task 3: Regenerate the gate registry, add the gate test, and update the README

Depends on: Task 1 (its anti-drift guard reads loop-brainstorm/SKILL.md and the shared reference), Task 2 (needs loop-improve's gate tags to regenerate the registry and to grep the contracts)

**Files (exclusive ownership):**
- Create: tests/gates/loop-improve.sh
- Modify: docs/gate-registry.md, README.md
- Test: tests/gates/loop-improve.sh, tests/gates/check.sh, tests/gates/tags.sh (run)

**Interfaces:**
- Consumes: skills/loop-improve/SKILL.md and skills/loop-improve/references/audit-playbook.md (Task 2); skills/loop-brainstorm/SKILL.md and skills/loop-brainstorm/references/brief-pipeline.md (Task 1); scripts/gen-gate-registry.sh.
- Produces: docs/gate-registry.md including loop-improve's `[gate:ASK]` and `[gate:DEFAULT]` rows; tests/gates/loop-improve.sh asserting all greppable contracts, the anti-drift guard, and the README rows; README.md with a loop-improve skill-table row and a directory-listing line.

**Acceptance check:** `scripts/gen-gate-registry.sh . && bash tests/gates/loop-improve.sh && bash tests/gates/check.sh && bash tests/gates/tags.sh` all print `PASS` / succeed, tagged [executed-check].

- [ ] Step 1: Regenerate the registry: `scripts/gen-gate-registry.sh .`. This rewrites docs/gate-registry.md to include loop-improve's rows (one ASK, three DEFAULT); the header timestamp updates and that is expected.
- [ ] Step 2: Add a README skill-table row and a directory-listing line for loop-improve. In the skill table (around the "Brainstorm / Plan / Router / Compiler / Executor" table near line 32), add a row naming loop-improve as the read-only audit front end that converges one finding into a brief for /loop-plan. In the repo-layout directory listing (the fenced block around line 72), add a line `skills/loop-improve/` describing the audit skill. Both must contain the literal `loop-improve` (the gate test greps README for it). Match the existing table alignment and listing style.
- [ ] Step 3: Create tests/gates/loop-improve.sh with EXACTLY this content:
  ```bash
  #!/usr/bin/env bash
  # loop-improve: read-only audit front end sharing loop-brainstorm's convergence half.
  # Asserts the greppable deliverable contracts, the anti-drift guard (the brief section table
  # lives ONLY in the shared reference), and the README rows.
  set -uo pipefail
  HERE="$(cd "$(dirname "$0")" && pwd)"
  REPO="$(cd "$HERE/../.." && pwd)"
  S="$REPO/skills/loop-improve/SKILL.md"
  PB="$REPO/skills/loop-improve/references/audit-playbook.md"
  BP="$REPO/skills/loop-brainstorm/references/brief-pipeline.md"
  BS="$REPO/skills/loop-brainstorm/SKILL.md"
  RM="$REPO/README.md"
  fail() { echo "FAIL: $1" >&2; exit 1; }

  [ -f "$S" ]  || fail "loop-improve SKILL missing"
  [ -f "$PB" ] || fail "vendored audit playbook missing"
  [ -f "$BP" ] || fail "shared brief-pipeline reference missing"

  # frontmatter: name + trigger phrases + read-only + one-brief convergence
  grep -qE '^name:[[:space:]]*loop-improve' "$S" || fail "frontmatter name is not loop-improve"
  grep -qi 'audit this repo for improvements' "$S" || fail "description missing the audit trigger"
  grep -qi 'what should I improve'            "$S" || fail "description missing the what-to-improve trigger"
  grep -qi 'improvement brief'                "$S" || fail "description missing the improvement-brief trigger"
  grep -qi 'read-only'                        "$S" || fail "skill does not state it is read-only on source code"

  # effort knobs: focus argument + quick/standard/deep
  grep -qi 'focus' "$S" || fail "no focus argument"
  grep -Eqi 'quick[ /].*standard[ /].*deep|quick/standard/deep' "$S" || fail "no quick/standard/deep effort knob"

  # findings table: the eight columns in order, plus covered/related renders and definitions
  grep -qE 'Finding.*Category.*Impact.*Effort.*Risk.*Confidence.*Tracker' "$S" \
    || fail "findings table header columns wrong or out of order"
  grep -q 'covered by #' "$S"  || fail "Tracker column does not render 'covered by #N'"
  grep -q 'related: #'   "$S"  || fail "Tracker column does not render 'related: #N'"
  grep -qi 'same work'   "$S"  || fail "no definition of covered (same work)"
  grep -qi 'different ask' "$S" || fail "no definition of related (same area, different ask)"

  # tracker scan wired to the backend-agnostic lister
  grep -q 'scripts/tracker.sh list' "$S" || fail "tracker scan not wired to scripts/tracker.sh list"

  # selection gate is ASK; convergence/commit/graduation/supersede are DEFAULT
  grep -qE '\[gate:ASK\]'     "$S" || fail "findings-selection round is not tagged ASK"
  grep -qE '\[gate:DEFAULT\]' "$S" || fail "convergence steps are not tagged DEFAULT"

  # unselected findings ride graduate-parking.sh unchanged; supersede offers a close
  grep -q 'graduate-parking.sh'      "$S" || fail "unselected findings do not ride graduate-parking.sh"
  grep -qi 'Parking lot'             "$S" || fail "unselected findings are not written to the Parking lot"
  grep -q 'scripts/tracker.sh close' "$S" || fail "supersede does not offer scripts/tracker.sh close"
  grep -qi 'Supersedes: #'           "$S" || fail "brief does not record the supersede link"

  # terminal state hands to /loop-plan
  grep -q '/loop-plan' "$S" || fail "terminal state does not name /loop-plan"

  # pointer to the shared convergence reference (absolute, resolves under both install styles)
  grep -q '~/.claude/skills/loop-brainstorm/references/brief-pipeline.md' "$S" \
    || fail "loop-improve does not point at the shared brief-pipeline reference"

  # vendored playbook: attribution + all 9 categories + Finding format, no plans-directory machinery
  grep -qi 'MIT'             "$PB" || fail "playbook missing MIT attribution"
  grep -q  'vendored 2026-08-08' "$PB" || fail "playbook missing vendored-date attribution"
  for cat in Correctness Security Performance 'Test Coverage' 'Tech Debt' Dependencies 'DX' Docs Direction; do
    grep -qi "$cat" "$PB" || fail "playbook missing category: $cat"
  done
  grep -qi 'Finding format' "$PB" || fail "playbook missing the Finding format"
  if grep -qi 'investigate.*plan' "$PB"; then fail "playbook still references /improve plan machinery (rephrase to brief/backlog terms)"; fi
  if grep -qi 'those files get committed' "$PB"; then fail "playbook secret rule still names /improve plan files (recast to the brief)"; fi
  if grep -qi 'execute the plans'          "$PB"; then fail "playbook DX line still references executing plans (recast to a briefable finding)"; fi

  # scope guards: the shared reference ends at the commit offer, and loop-improve's terminal is /loop-plan only
  if grep -q  'graduate-parking.sh' "$BP"; then fail "graduation leaked into the shared reference (it is a per-skill step)"; fi
  if grep -qi 'frontier-sandwich'   "$BP"; then fail "terminal-state routing leaked into the shared reference (it is a per-skill step)"; fi
  if grep -qi 'frontier-sandwich'   "$S";  then fail "loop-improve must not offer frontier-sandwich (its terminal is /loop-plan only)"; fi

  # anti-drift: the brief section table lives ONLY in the shared reference.
  # Key on 'Three bins: verified' (unique to the table row); the bare phrase 'Known vs guessed'
  # legitimately survives in loop-brainstorm Step 2b prose, so it is NOT a safe marker.
  grep -q 'Three bins: verified' "$BP" || fail "shared reference is missing the brief section table"
  if grep -q 'Three bins: verified' "$BS"; then fail "brief section table duplicated into loop-brainstorm SKILL.md (drift)"; fi
  if grep -q 'Three bins: verified' "$S";  then fail "brief section table duplicated into loop-improve SKILL.md (drift)"; fi

  # README rows
  grep -q 'loop-improve' "$RM" || fail "README missing a loop-improve row/line"

  echo "PASS: loop-improve contracts, anti-drift guard, and README rows all hold"
  ```
- [ ] Step 4: `chmod +x tests/gates/loop-improve.sh` so it runs like its siblings.
- [ ] Step 5: Run the acceptance check. `bash tests/gates/loop-improve.sh` prints its PASS line; `bash tests/gates/check.sh` prints its PASS line (registry now fresh with loop-improve rows); `bash tests/gates/tags.sh` prints its PASS line (loop-improve's added tags only raise the per-type counts, all UPPERCASE). If check.sh reports STALE, re-run `scripts/gen-gate-registry.sh .`.
- [ ] Step 6: Commit.
  ```sh
  git add docs/gate-registry.md README.md tests/gates/loop-improve.sh
  git commit -m "loop-improve: regenerate gate registry, add gate test and anti-drift guard, add README rows"
  ```

## Self-review

1. Brief coverage: every success criterion maps to an acceptance check or human checkpoint per the coverage table above; criteria 1 and 8 are human checkpoints, 2/3/4/5/7 are Task 3 gate-test contract greps plus the dogfood, 6 is Task 1's loop-brainstorm.sh passing unchanged plus the dogfood note.
2. Placeholder scan: no TBD, no "add appropriate", no "similar to Task N"; every path named (skills/loop-improve/SKILL.md, skills/loop-improve/references/audit-playbook.md, skills/loop-brainstorm/references/brief-pipeline.md, tests/gates/loop-improve.sh, docs/gate-registry.md, README.md) is created or modified by a task here.
3. Consistency: the pointer path, the `Three bins: verified` anti-drift marker, the findings-table columns, and the `[gate:ASK]`/`[gate:DEFAULT]` placements named in Task 2 match exactly the strings tests/gates/loop-improve.sh greps in Task 3.
4. Loop-drive contract: each task states its scope, an executed acceptance check (not a judged one), exclusive file ownership, complete depends-on, and reads in isolation; no two tasks touch the same file, so there is no false parallelism (the chain is fully sequential by design).
5. Agnosticism: the plan edits markdown and bash files and runs `bash tests/gates/*.sh` and `scripts/gen-gate-registry.sh`; it never assumes Claude Code skills or ringer are installed to execute or check any task.
