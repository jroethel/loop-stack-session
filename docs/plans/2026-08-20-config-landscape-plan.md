# Config landscape refactor - implementation plan (backlog #38)

> For executors: tasks use checkbox syntax; execute in dependency order; a task is done when its
> acceptance check passes. No specific tooling, harness, or skills are assumed.

**Goal:** Split the accreted `config/repo-state.md` by audience into a near-frozen machine surface plus a sibling doctrine doc (`config/conventions.md`), staged as template v4 and applied to this repo, so every future config addition has a self-evident home.

**Approach:** Author `config/conventions.md` (rendered from `config/conventions.template.md`) holding all mode-invariant doctrine prose and a new placement table as its first section; strip that prose from `repo-state.md`/`.template.md`, leaving line-anchored keys, the Lanes table, and the mode-specific rendered lines, bumped to template-version 4. Teach `setup.sh` to render and reconcile both files as one versioned unit that carries every line-anchored key forward, update the prose pointers that named the old home, and close with a handoff doc that drives the target-repo roll later.

**Tech stack:** Bash (POSIX-ish, `set -uo pipefail`), `awk`/`grep`/`sed`, Markdown; existing test suites are plain bash scripts run directly.

**Source brief:** docs/briefs/2026-08-20-config-landscape-brief.md

## Decisions (decided at planning; orchestrator recommendation; do not reopen)

1. Convention doc is `config/conventions.md`, rendered from `config/conventions.template.md`, vendored to target repos alongside `repo-state.md`. The placement table is its first section - the first thing an agent adding config prose encounters.
2. `config/host.env`, `config/ringer/`, `config/routing/` do NOT physically move. They receive declared homes in the placement table only.
3. Versioning: a single `template-version:` key stays in `repo-state.md` (the machine surface). Value `4` means the two-file shape. One reconcile offer renders/replaces BOTH files together.
4. Skill prose pointer updates: `skills/loop-brainstorm/references/brief-pipeline.md` and `skills/loop-setup/references/import-triage.md` (graduated-item template pointer -> `conventions.md`), and `skills/loop-setup/SKILL.md` (render description is now two files). `skills/loop-auto/SKILL.md` and `skills/handoff/SKILL.md` cite keys/lanes that stay in `repo-state.md` - no change.
5. `graduate-parking.sh` does NOT parse the template out of `repo-state.md` (verified: its body is hardcoded at line ~71). Only its header/inline comments that call `config/repo-state.md` the "template source" need rewording; its existence check stays on `config/repo-state.md` as the conforming-repo marker.

## Config split map (the authoritative binning; Tasks 1 and 2 both consume it)

Every block of the current `config/repo-state.md` / `.template.md` is binned here. "Move" means the prose leaves `repo-state` and lands in `conventions.md`; "Keep" means it stays in `repo-state` (parser-read or mode-specific rendered content).

| Block (current repo-state)                                   | Bin      | Destination            |
| ---                                                          | ---      | ---                    |
| H1 + intro schema-source sentence                            | Keep*    | repo-state (reworded)  |
| `template-version:` / `Remote:` / `backlog-group:` keys      | Keep     | repo-state             |
| `tracker:` key                                               | Keep     | repo-state             |
| `## Lanes` table                                             | Keep     | repo-state             |
| Backlog cross-repo view command lines (gh / glab)            | Keep     | repo-state (rendered)  |
| Source-of-truth + mirrors 3-line block                       | Keep     | repo-state (rendered)  |
| `## Local tracker` section (template only)                   | Keep     | repo-state.template    |
| `autonomy-default:` explanatory prose (NOT the key)          | Move     | conventions            |
| `tracker:` key explanatory prose (NOT the key)               | Move     | conventions            |
| Root ALL-CAPS files / import-sweep exclusions / `idea` prose | Move     | conventions            |
| Filename-patterns sentence                                   | Move     | conventions            |
| "Where I left off" / handoff-degradation paragraph           | Move     | conventions            |
| `## Agent status vocabulary` section                         | Move     | conventions            |
| `## Archive and graduation rules` + graduated-item template  | Move     | conventions            |
| `## Context map` pointer section                             | Move     | conventions            |
| `## Scope rule` section                                      | Move     | conventions            |

*The intro sentence is reworded to say `repo-state.md` is the machine surface and points at `conventions.md` for doctrine; `conventions.md` points back. Each file names the other.

The `autonomy-default:` and `tracker-remote-ack:` KEYS (line-anchored, present only when set) stay in `repo-state.md`: `skills/loop-auto/loop-auto.sh` greps `^autonomy-default:` there, and `setup.sh` greps `^tracker-remote-ack:` there. Only their surrounding prose moves.

## Global constraints (exact values)

- Template version bumps from `3` to `4`; the key is `template-version: 4`, line-anchored in `repo-state.md`/`.template.md` only.
- New files: `config/conventions.template.md` (vendoring source) and `config/conventions.md` (this repo's instance). They are byte-identical - `conventions.md` is mode-invariant, so its render is a verbatim copy of the template.
- Line-anchored keys the v4 reconcile MUST carry forward: `Remote:`, `backlog-group:`, `tracker:`, `autonomy-default:`, `tracker-remote-ack:`. (Today's reconcile silently drops the last two.)
- One reconcile gate offers both files together; accepting replaces both, declining leaves both untouched.
- `config/context-map.md` content is out of scope (settled by #34). No context-map line is added or moved; `conventions.md` is not indexed there. All existing class-e pointers must keep resolving.
- House style in every touched Markdown file: plain `-`, never the em-dash character; aligned pipe tables under 110 chars; one sentence per physical line where reasonable.
- Commit messages are plain, no co-author line.

## Dependency graph

```
Task 1 (conventions files)
   |
Task 2 (repo-state restructure + prose-location tests)   depends on 1
   |
Task 3 (setup.sh render/reconcile + reconcile test)      depends on 1, 2
   |            \
Task 4 (skill/script prose pointers)   Task 5 (close-out handoff doc)
   depends on 1, 3                        depends on 3
```

Task 4 and Task 5 own disjoint files and run in parallel after Task 3.

## Human checkpoints

- [judgment] After Task 1, before merge: review the placement table in `config/conventions.md`. Success criterion: the next real config addition lands without debate about where it goes. This is the brief's placement-table-unambiguity judgment and cannot be reduced to a command; a human confirms each row's home is unambiguous and the six config artifacts (repo-state, conventions, context-map, host.env, ringer/, routing/) each have exactly one declared home.
- [judgment] After Task 5: confirm the handoff doc's per-repo re-render step is runnable by a later session with no other context (the roll is a real staged offer, not a rewrite of this stream).

## How to run

Run from the repo root (`/Users/jjrdar/create/loops/loop-stack-session`).

- Full suite (discovers and runs every `tests/*/*.sh`): `bash tests/run.sh`
- A single suite, e.g.: `bash tests/loop-setup/reconcile.sh`
- Prose-location suites: `bash tests/repo-state/config.sh` and `bash tests/loop-setup/docs-gitlab.sh`
- Lifecycle lint on this repo: `bash scripts/lifecycle-lint.sh .` (exit 0 = clean)
- Key-read checks: `bash scripts/tracker.sh mode get` and `bash skills/loop-auto/loop-auto.sh default get`

`tests/run.sh` skips `build-fixtures.sh` and (when `gh` is unauthenticated) `live.sh`; both are reported, not failures.

---

### Task 1: conventions doctrine doc + placement table
Depends on: none
**Files (exclusive ownership):**
Create: `config/conventions.template.md`, `config/conventions.md`

**Interfaces:**
Produces: `config/conventions.md` and `config/conventions.template.md`, byte-identical, containing (in order) the placement table as the first `##` section, then the moved doctrine sections listed in the split map: `## Config placement`, then the `autonomy-default`/`tracker` key prose, the sweep-exclusions/`idea` prose, filename patterns, "where I left off", `## Agent status vocabulary`, `## Archive and graduation rules` (including the graduated-item template fenced block with `Source brief:` / `Graduated:` / `Restart context:` lines), `## Context map`, `## Scope rule`. The graduated-item fenced template must be reproduced verbatim from the current `repo-state.md` lines 64-72. Each file opens with a sentence naming `config/repo-state.md` as the machine-surface sibling.
Consumes: the current prose blocks of `config/repo-state.md` (source of the moved text).

**Acceptance check:**
`bash scripts/lifecycle-lint.sh . && bash tests/run.sh` both exit 0, AND `grep -q '^## Config placement' config/conventions.md && diff config/conventions.md config/conventions.template.md` succeeds. [executed-check]

Steps:
- [ ] Write `config/conventions.template.md`. First line: `# Loop-stack conventions`. Second sentence names `config/repo-state.md` as the sibling machine surface and states this file holds doctrine. First `##` section is `## Config placement` containing this table (fill the prose cells; keep each row under 110 chars):

  ```
  | Artifact               | Audience            | Rendered / lives         | Holds                      |
  | ---                    | ---                 | ---                      | ---                        |
  | config/repo-state.md   | parsers (machine)   | repo-state.template.md   | keys + Lanes table         |
  | config/conventions.md  | agents (doctrine)   | conventions.template.md  | this table + all doctrine  |
  | config/context-map.md  | agents (orient)     | living; #34 policy       | one pointer per memory     |
  | config/host.env        | this host (machine) | template; gitignored     | host-local env values      |
  | config/ringer/         | ringer engine       | in place; no move        | host adapter + tmpl        |
  | config/routing/        | routing (both)      | in place; no move        | model scoreboard           |
  ```
  (Rows are pre-checked at under 110 chars with aligned pipes; keep that property through any edit.)
  Below the table add one sentence: any new config prose lands in `config/conventions.md` unless it is a line-anchored key a parser greps, which lands in `config/repo-state.md`.
- [ ] Append the moved doctrine sections, copied verbatim from `config/repo-state.md` (the blocks marked Move in the split map). Preserve the graduated-item fenced block exactly. Do not alter wording beyond removing any now-dangling "in this same file" phrasing that referred to keys now split across two files (reword to name the file that actually holds the key).
- [ ] Copy the finished template verbatim to `config/conventions.md` (`cp config/conventions.template.md config/conventions.md`).
- [ ] Run the acceptance check; expect PASS (nothing has been removed from `repo-state.md` yet, so prose is temporarily duplicated - that is expected at this task boundary and the suite stays green).
- [ ] Commit:
  ```
  git add config/conventions.template.md config/conventions.md
  git commit -m "config: add conventions doc with placement table (v4 prep)"
  ```

---

### Task 2: repo-state restructure to v4 + prose-location tests
Depends on: Task 1
**Files (exclusive ownership):**
Create: none
Modify: `config/repo-state.template.md` (bump `template-version:` line 7; delete the Move blocks; rework intro line 3-5), `config/repo-state.md` (bump `template-version:` line 6; delete the Move blocks; rework intro line 3), `tests/repo-state/config.sh` (repoint moved-prose assertions), `tests/loop-setup/docs-gitlab.sh` (repoint moved-prose assertions + em-dash sweep)
Test: the two modified test files are the deliverable's teeth

**Interfaces:**
Produces: `config/repo-state.md` and `config/repo-state.template.md` at `template-version: 4`, containing only the Keep blocks from the split map. `repo-state.md` retains `tracker: github`, its `Remote:` line, and the intro pointer to `conventions.md`. `repo-state.template.md` retains the `## Local tracker` section and its disclosures.
Consumes: `config/conventions.md` (created by Task 1) as the assertion target for moved prose.

**Acceptance check:**
`bash tests/repo-state/config.sh && bash tests/loop-setup/docs-gitlab.sh && bash scripts/lifecycle-lint.sh . && bash scripts/tracker.sh mode get && bash skills/loop-auto/loop-auto.sh default get && bash tests/run.sh` all succeed; `tracker.sh mode get` prints `github`, `loop-auto.sh default get` prints `pause`. [executed-check]

Steps:
- [ ] Edit `tests/repo-state/config.sh` FIRST (test-before-implement). Add `CONV="$REPO/config/conventions.md"` and `CONVTPL="$REPO/config/conventions.template.md"`. Repoint these assertions from `$CFG`/`$TPL` to `$CONV`/`$CONVTPL`: the `## Scope rule` check (currently asserted in both `$TPL` and `$CFG`), the `## Archive and graduation` check, and the `Source brief:` graduated-item check. Also repoint the `grep -qi 'idea'` doctrine assertion (line 40) to `$CONV`, so it keeps testing the moved idea-label prose instead of tautologically matching the kept Lanes table. Keep the Lanes-table, `.gitignore`, `^tracker:` key, Local-tracker-in-`$TPL`, and CLAUDE.md-pointer assertions. Note: the `git (log|status)` fallback prose moved, so repoint that assertion to `$CONV` as well.
- [ ] Edit `tests/loop-setup/docs-gitlab.sh` FIRST. Repoint the two `autonomy-default` assertions (lines 42-44) from `$TPL`/`$CFG` to `$CONVTPL`/`$CONV`, and the two `CONTRIBUTING.md` assertions (lines 47-48) likewise. Repoint the `grep -qi 'gitlab' "$CFG"` assertion (line 33) to `$CONV` - after the split, the tracker-backend prose that names gitlab lives in `conventions.md`, and the kept blocks of `repo-state.md` may carry no gitlab mention at all. Add `$CONV` and `$CONVTPL` to the em-dash sweep loop (line 87). Leave the `template-version: $TV` current-version assertion pointed at `$CFG`.
- [ ] Run `bash tests/repo-state/config.sh` and `bash tests/loop-setup/docs-gitlab.sh`. Expect PASS at this point, not a red state: Task 1 duplicated the doctrine prose into `conventions.md`, so the repointed assertions already match, and no version assertion has moved yet. The red signal these edits buy arrives later in this task - once the Move blocks are deleted and the version is bumped, any assertion still pointed at the wrong file fails. A FAIL here means a repoint was typo'd; fix before proceeding.
- [ ] Edit `config/repo-state.template.md`: set line 7 to `template-version: 4`; delete every Move block present in this file (the `autonomy-default`/`tracker` explanatory paragraphs, the root-files/sweep-exclusions/`idea` paragraph, the filename-patterns line, the "where I left off" paragraph, the `## Archive and graduation rules` section including the fenced template, the `## Scope rule` section). Note: the template has NO `## Agent status vocabulary` or `## Context map` section - those are instance-only; do not go hunting for them here. Keep the `## Lanes` table, the backlog cross-repo view lines, the source-of-truth+mirrors block, and the entire `## Local tracker` section (template-only; the github render strips it). Rework the intro (lines 3-5) so it names the machine surface and points at `conventions.md` - BUT the reworked intro MUST preserve two literal anchor strings verbatim, because `setup.sh`'s render functions key on them with `index()` matches: `Render it into` (the line the renders drop) and `the Local tracker section governs local mode` (the line the renders rewrite into the tracker-backend disclosure). Dropping either anchor silently breaks the github/gitlab render in a way this repo's tests cannot see. In the kept `## Lanes` table, reword the Handoffs row's How cell from `Per session; git fallback below.` to `Per session; git fallback in conventions.md.` (the fallback prose moves there), then re-pad the table so the pipes still align.
- [ ] Edit `config/repo-state.md`: set line 6 to `template-version: 4`; delete the same Move blocks PLUS the two instance-only sections (`## Agent status vocabulary`, `## Context map`); rework the intro line to point at `conventions.md` (the instance carries neither anchor string - both are template-only render inputs); make the same Handoffs-cell reword in the Lanes table. Result contains only Keep blocks plus `Remote:` and `tracker: github`.
- [ ] Run the full acceptance check; expect PASS. Confirm `scripts/tracker.sh mode get` -> `github` and `skills/loop-auto/loop-auto.sh default get` -> `pause` (no `autonomy-default:` key set in this repo).
- [ ] Commit:
  ```
  git add config/repo-state.template.md config/repo-state.md tests/repo-state/config.sh tests/loop-setup/docs-gitlab.sh
  git commit -m "config: restructure repo-state to v4 machine surface, doctrine to conventions"
  ```

---

### Task 3: setup.sh two-file render + reconcile with key carry-forward
Depends on: Task 1, Task 2
**Files (exclusive ownership):**
Modify: `skills/loop-setup/setup.sh` (add `CTPL` var near `TPL` at line ~22; render `conventions.md` in the fresh-render branch at lines ~429-433; extend `reconcile_config` at lines ~277-313 to carry `autonomy-default:`/`tracker-remote-ack:` forward and to render/offer/write `conventions.md` as one gate), `tests/loop-setup/reconcile.sh` (two-file + carry-forward assertions)
Test: `tests/loop-setup/reconcile.sh` is the deliverable's teeth

**Interfaces:**
Consumes: `config/conventions.template.md` (Task 1), `template-version: 4` in `config/repo-state.template.md` (Task 2).
Produces: after a fresh setup or an accepted reconcile, the target repo has both `config/repo-state.md` (v4, with `Remote:`, `backlog-group:`, `tracker:`, and any pre-existing `autonomy-default:`/`tracker-remote-ack:` preserved) and `config/conventions.md` (verbatim copy of the template). A declined reconcile leaves both files byte-identical to before.

**Acceptance check:**
`bash tests/loop-setup/reconcile.sh && bash tests/run.sh` both exit 0. [executed-check]

Steps:
- [ ] Edit `tests/loop-setup/reconcile.sh` FIRST. After the existing accept-re-render diff (line 34), add:
  ```bash
  # v4 is a two-file shape: the accepted re-render also produces conventions.md, verbatim from the template
  [ -f "$S/config/conventions.md" ] || fail "accepted re-render did not create config/conventions.md"
  diff "$REPO/config/conventions.template.md" "$S/config/conventions.md" \
    || fail "rendered conventions.md is not a verbatim copy of the template"
  # the reworked v4 template must still feed the render anchors: the rendered machine surface
  # carries the tracker-backend disclosure and never leaks the template-only render instruction
  grep -q '(github, gitlab, or local)' "$S/config/repo-state.md" \
    || fail "v4 render lost the tracker-backend disclosure (template intro anchor broken)"
  ! grep -q 'Render it into' "$S/config/repo-state.md" \
    || fail "v4 render leaked the template-only 'Render it into' instruction"
  ```
  Then add a new scenario at the end (before the final `echo`). Splice the heredoc at column 0: the
  block below is indented for plan readability, but `<<'EOS'` requires the body's key lines AND the
  closing `EOS` at column 0, or the fixture's `^`-anchored greps and the heredoc terminator both break:
  ```bash
  # --- v2-era fixture: a v4 re-render preserves every line-anchored key (Remote, tracker,
  #     autonomy-default, tracker-remote-ack), not just the two the v3 reconcile carried ---
  V="$(mktemp -d)"; trap 'rm -rf "$REF" "$S" "$G" "$V"' EXIT
  ( cd "$V" && git init -q )
  mkdir -p "$V/config"
  cat > "$V/config/repo-state.md" <<'EOS'
  # Repo State Map

  template-version: 2

  Remote: none (local tracker; see the Local tracker section)
  tracker: local
  autonomy-default: auto
  tracker-remote-ack: github

  old v2 doctrine prose that should be dropped from the machine surface
  EOS
  ( cd "$V" && LOOP_ASSUME_YES=1 "$SETUP" </dev/null >/dev/null ) || fail "v2 accept re-render exited non-zero"
  grep -q '^template-version: 4$'        "$V/config/repo-state.md" || fail "v2->v4 re-render did not bump the version"
  grep -q '^tracker: local$'             "$V/config/repo-state.md" || fail "v4 re-render dropped tracker:"
  grep -q '^autonomy-default: auto$'     "$V/config/repo-state.md" || fail "v4 re-render dropped autonomy-default:"
  grep -q '^tracker-remote-ack: github$' "$V/config/repo-state.md" || fail "v4 re-render dropped tracker-remote-ack:"
  [ -f "$V/config/conventions.md" ]                                || fail "v4 re-render did not create conventions.md"
  ```
- [ ] Run `bash tests/loop-setup/reconcile.sh`; expect FAIL (setup.sh renders one file and drops the two keys).
- [ ] In `setup.sh`, after `TPL=...` (line ~22) add `CTPL="$REPO/config/conventions.template.md"` and, next to the `[ -f "$TPL" ]` guard, add `[ -f "$CTPL" ] || fail "conventions template not found: $CTPL"`.
- [ ] In `reconcile_config`, after the line `cand="$cand"$'\n'"tracker: $MODE"`, add the carry-forward loop:
  ```bash
  for k in autonomy-default tracker-remote-ack; do
    kv="$(grep -E "^${k}:" config/repo-state.md | head -1)"
    [ -n "$kv" ] && cand="$cand"$'\n'"$kv"
  done
  ```
- [ ] In `reconcile_config`, extend the offer to both files: in the diff/announce block show both files (for the conventions half, `diff -u config/conventions.md "$CTPL"` when the file exists, else announce it as new); in the accept branch write `printf '%s\n' "$cand" > config/repo-state.md` and `cp "$CTPL" config/conventions.md`, and echo that both were re-rendered. Use `cp` for the conventions half, never a `"$(cat ...)"` round-trip - command substitution strips trailing newlines and would make the byte-identical `diff` assertion flaky. Keep the single `ask` gate governing both.
- [ ] In the fresh-render branch (the `if [ ! -f config/repo-state.md ]` block, after the `case "$MODE"` render writes `config/repo-state.md`), add `cp "$CTPL" config/conventions.md` so a first-time setup also lands the doctrine file. In the existing-config path, add an idempotence guard: `[ -f config/conventions.md ] || cp "$CTPL" config/conventions.md` - a repo already at v4 whose `conventions.md` went missing gets it back on re-run instead of slipping through both render paths (reconcile returns early on version match).
- [ ] Run the acceptance check; expect PASS.
- [ ] Commit:
  ```
  git add skills/loop-setup/setup.sh tests/loop-setup/reconcile.sh
  git commit -m "loop-setup: render and reconcile repo-state + conventions as one v4 unit, carry all keys"
  ```

---

### Task 4: prose pointer updates (skills + graduate-parking)
Depends on: Task 1, Task 3
**Files (exclusive ownership):**
Modify: `skills/loop-brainstorm/references/brief-pipeline.md` (line 70), `skills/loop-setup/references/import-triage.md` (line 57), `skills/loop-setup/SKILL.md` (description line 3 and render step line 27), `scripts/graduate-parking.sh` (header/inline comments only, lines ~2-15)

**Interfaces:**
Consumes: `config/conventions.md` (Task 1) as the new home of the graduated-item template; the two-file render behavior (Task 3).
Produces: no runtime behavior change; only prose now names the correct homes.

**Acceptance check:**
`grep -q 'conventions.md' skills/loop-brainstorm/references/brief-pipeline.md && grep -q 'conventions.md' skills/loop-setup/references/import-triage.md && grep -q 'conventions.md' skills/loop-setup/SKILL.md && ! grep -q 'template source' scripts/graduate-parking.sh && bash tests/run.sh` succeeds; plus the prose-source audit `! (grep -rn 'graduated-item template' scripts skills | grep -q 'repo-state')` - no script or skill doc still names `repo-state` as the graduated-item template's home. (The audit is scoped to the prose that moved; `skills/loop-auto/` legitimately reads the `autonomy-default:` KEY from `repo-state.md` and must not be flagged.) [executed-check]

Steps:
- [ ] `skills/loop-brainstorm/references/brief-pipeline.md` line 70: change "body built from the graduated-item template in `config/repo-state.md`" to "... in `config/conventions.md`".
- [ ] `skills/loop-setup/references/import-triage.md` line 57: change "the graduated-item template shape from `config/repo-state.md`" to "... from `config/conventions.md`".
- [ ] `skills/loop-setup/SKILL.md`: line 3 description - after "write its repo-state map (`config/repo-state.md`)" add "and conventions (`config/conventions.md`)"; the "What it does" render step (line 27) - change "Writes `config/repo-state.md` by rendering `config/repo-state.template.md`" to note it renders both `config/repo-state.md` and `config/conventions.md` from their templates as one versioned unit.
- [ ] `scripts/graduate-parking.sh`: reword the header comment (lines ~2-4) and the inline comments at lines ~13-15 so they call `config/repo-state.md` the conforming-repo marker whose existence is checked, and name `config/conventions.md` as the home of the graduated-item template. Also reword the comment at line ~70 - `Body shape mirrors the graduated-item template in config/repo-state.md.` - to name `config/conventions.md`; this is the load-bearing pointer to the template's home and the acceptance audit greps for it. Do NOT change the `REPO_STATE="config/repo-state.md"` existence check or the hardcoded body at line ~71.
- [ ] Run the acceptance check; expect PASS.
- [ ] Commit:
  ```
  git add skills/loop-brainstorm/references/brief-pipeline.md skills/loop-setup/references/import-triage.md skills/loop-setup/SKILL.md scripts/graduate-parking.sh
  git commit -m "docs: repoint graduated-item template and render prose to conventions.md"
  ```

---

### Task 5: close-out handoff doc for the target-repo roll
Depends on: Task 3
**Files (exclusive ownership):**
Create: `docs/handoffs/2026-08-20-config-v4-target-roll.md`

**Interfaces:**
Consumes: the finalized v4 reconcile mechanism (Task 3) - the doc's per-repo step must match how `setup.sh` actually offers the re-render.
Produces: a self-contained handoff naming all five target repos and the exact per-repo re-render step, so a later session rolls one repo without re-deriving context.

**Acceptance check:**
`test -f docs/handoffs/2026-08-20-config-v4-target-roll.md && for r in vaultwise pokemine iamawriter substack-scraper ai-benchmark; do grep -q "$r" docs/handoffs/2026-08-20-config-v4-target-roll.md || exit 1; done && bash scripts/lifecycle-lint.sh .` succeeds. [executed-check]

Steps:
- [ ] Create `docs/handoffs/2026-08-20-config-v4-target-roll.md` (filename matches the `docs/handoffs/YYYY-MM-DD-<slug>.md` pattern). Include: a one-paragraph context line (template v4 = two-file config shape; these repos are at v2 or none, all github mode); a table of the five target repos - `vaultwise`, `pokemine`, `iamawriter`, `substack-scraper`, `ai-benchmark` - each with its current template-version (v2 or none) and status (pending); and the exact per-repo re-render step, verbatim runnable:
  ```
  cd <target-repo> && /path/to/loop-stack/skills/loop-setup/setup.sh
  ```
  followed by: setup detects the stale template-version and offers a single re-render of `config/repo-state.md` + `config/conventions.md`; accepting preserves `tracker:`, `Remote:`, `backlog-group:`, `autonomy-default:`, and `tracker-remote-ack:`; verify with `git diff config/` and `bash scripts/lifecycle-lint.sh .` before committing. State that each repo is an independent, resumable unit and the roll is a staged offer, not part of this stream.
- [ ] Run the acceptance check; expect PASS.
- [ ] Commit:
  ```
  git add docs/handoffs/2026-08-20-config-v4-target-roll.md
  git commit -m "handoff: config v4 target-repo roll runbook (5 repos)"
  ```

---

## Success-criterion -> task mapping (total)

| Brief criterion                            | Lands at                                 |
| ---                                        | ---                                      |
| lifecycle-lint exits 0 after restructure   | Task 2 acceptance (also 1, 5)            |
| repo-state + loop-setup suites pass        | Task 3 acceptance (tests/run.sh)         |
| six machine keys parse from declared file  | Tasks 2 and 3 (config.sh, reconcile.sh)  |
| v2 fixture: v4 re-render preserves keys    | Task 3 (carry-forward scenario)          |
| grep audit: no prose read off its home     | Task 4 acceptance (prose-source audit)   |
| handoff doc names 5 repos + roll step      | Task 5 acceptance                        |
| placement table exists, encountered first  | Task 1 + human checkpoint                |
| [judgment] placement homes unambiguous     | human checkpoint (after Task 1)          |

## Self-review notes

- Brief coverage is total: every Success criterion and every "Done looks like" item maps above; the five seams map to Tasks 1-5 in blast-radius order.
- Placeholder scan: no TBD/TODO; every edge case is named (key carry-forward for two specific keys, byte-identical conventions files, fresh-vs-reconcile render paths, config/ not scanned so conventions.md is never import-offered).
- Name/signature consistency: `CTPL`, `config/conventions.md`, `config/conventions.template.md`, `template-version: 4`, and the five carry-forward keys are used identically across Tasks 1-5.
- Ownership is exclusive: no two tasks modify the same file. Task 2 and Task 3 both need `repo-state`/`setup.sh` to agree on the split, but Task 2 owns `repo-state`, Task 3 owns `setup.sh`; they are dependent (3 depends on 2), never parallel. Task 4 and Task 5 own disjoint files and are the only parallel pair.
- Executor-portability: every acceptance check is a runnable command; no skill or harness name appears in an executor step; the test runner invocation was verified against `tests/run.sh`.

## Rubix revisions (2026-08-20)

Two fresh-context reviewers (lens A: executor seat; lens B: cold craft) produced 14 findings; all
were incorporated (B7 in its cheap repoint variant). The load-bearing three: Task 4's prose-source
audit was rescoped so it cannot flag loop-auto's legitimate key-reads (A1); `docs-gitlab.sh` line 33
was added to Task 2's repoint list (A2/B1 symptom); Task 2 now requires the reworked template intro
to preserve the two literal render anchors `setup.sh` keys on, with a render assertion added to
Task 3's test (B1). Also: instance-only vs template-only sections disclosed (A3), honest
no-red-state framing (A5), heredoc column-0 splice notes (A6/B3), `cp` for the conventions render
half (B4), v4-missing-conventions idempotence guard (A7), Handoffs-cell dangling "below" reword
(B5), `graduate-parking.sh:70` added to Task 4 (A4/B6), placement table rewritten to house style
(B2), `config.sh:40` idea assertion repointed (B7).

## Contradictions found vs the pre-decided answers

None. Every verified fact held up on inspection:
- `graduate-parking.sh` body is hardcoded at line 71 and does not parse `repo-state.md` (pre-decision 5 confirmed).
- `reconcile_config` re-renders by whole-file replacement preserving only `Remote:`, `backlog-group:`, `tracker:`, and drops `autonomy-default:`/`tracker-remote-ack:` today (verified fact confirmed; Task 3 fixes it).
- `skills/loop-auto/SKILL.md` and `skills/handoff/SKILL.md` cite only keys/lanes that stay in `repo-state.md` (autonomy-default key, Handoffs/Chain-state/Batch-reviews lanes) - no change needed (pre-decision 4 confirmed).
- `lifecycle-lint.sh` class-e scans only `config/context-map.md`'s `## The index`; no context-map pointer targets any block that moves, so all pointers keep resolving.

One nuance worth flagging (not a contradiction): `tests/loop-setup/acceptance.sh` asserts the local-mode config discloses "cross-repo idea search" and "wayfinder requires" - those live in the `## Local tracker` section, which the split map KEEPS in `repo-state.template.md`, so that suite passes unchanged. `tests/gates/loop-brainstorm.sh` writes its own minimal `repo-state.md` fixture and relies only on the file existing (graduate-parking's body is hardcoded), so it also passes unchanged.
