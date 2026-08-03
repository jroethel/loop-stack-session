# loop-review Implementation Plan

> For executors: tasks use checkbox syntax; execute in dependency order; a task is done when its
> acceptance check passes. No specific tooling, harness, or skills are assumed beyond a Claude Code
> install with the `claude` CLI on PATH and `git`.

**Goal:** Ship `skills/loop-review/SKILL.md`, a fork of Matt Pocock's code-review skill that judges any finished diff on two axes (Spec and Standards) and discloses its resolved sources before any finding.

**Approach:**
Fork-and-adapt Matt's proven code-review skill rather than writing loop-native from scratch.
Preserve its two-parallel-subagent structure and its verbatim Fowler 12-smell baseline; add four deltas (a spec discovery chain, a disclosure opener, reviewer model referenced by role, the user's markdown rules); remove its hard `docs/agents/issue-tracker.md` setup dependency so the skill runs in any repo.
Then hook loop-drive's final gate to invoke it as the run's terminal artifact-quality check.

**Tech stack:** Markdown skill files (Claude Code skill format), bash test harness, `git`, the `claude` CLI for headless end-to-end runs.

**Source brief:** `docs/briefs/2026-07-21-loop-review-brief.md`

## Resolved open questions

The brief's four planning questions, decided here with rationale:

- **Plan-discovery matching heuristic (Q1): branch-name match only, else ask - never a silent most-recent guess.**
  Within the brief's fixed discovery chain (user-passed path, else plan, else brief, else commit-message refs, else ask, else "no spec available"), the plan/brief rung resolves by branch-name match: a `docs/plans/*.md` (then `docs/briefs/*.md`) whose topic slug appears in the current branch name.
  If no file matches the branch name, the skill does not auto-resolve to the most recent plan; it falls through to asking the user (offering the most-recent file only as a labeled suggestion the user must confirm).
  The disclosure opener always names which file resolved and by which rule.
  Rationale (rubix A1): a confident Spec-axis review against the wrong plan is worse than no review; the most-recent-by-date fallback silently substitutes an unrelated spec, so it is demoted from an auto-resolve to a suggestion inside the ask, keeping the wrong-guess case "obvious and overridable," never "silently wrong."

- **loop-drive insertion point (Q2): Step 5, "Advance only on a green integration branch" item - as an advisory review, not a blocking gate.**
  The terminal review runs once, after the final wave's advance, over the whole-run diff (the pre-run base ref `...` the integration branch), as an advisory artifact review distinct from the per-unit validators.
  Its single clean insertion point is the "Advance only on a green integration branch" item in Step 5, reflected in the emitted procedure list at Step 6 item 6.
  Rationale (rubix A4): the whole-run review is inherently retrospective - per-unit validators already gated correctness during the waves, so this review runs after advancement and cannot block it; calling it a "gate" oversells it, so it is named an advisory terminal review whose findings are recorded at the final human checkpoint and whose Spec-axis findings may be slipped to the plan's downstream review step (loop-drive's existing slip mechanism).

- **Subagent effort (Q3): medium, model resolved by role.**
  Both lenses dispatch as fresh subagents at medium reasoning effort, with the reviewer model chosen by its role (a review / validation gate) per the user's routing conventions when present, else the session's default capable model.
  Rationale: medium matches loop-drive's validator default (high is reserved for gate-critical numeric or contract work); the two-axis split and fresh context are where the signal comes from, not raw effort; resolving by role rather than a hard-pinned name keeps the skill standalone and keeps frontier quota for orchestration.

- **RED-GREEN fixture shape (Q4): two seeded throwaway git repos, a deterministic structural layer plus a costed behavioral layer.**
  The harness has two layers (rubix B5/A7): layer A is deterministic greps over `SKILL.md` (no model calls) that drive RED before the skill exists and serve as the cheap regression check; layer B builds two temp git repos and runs one real headless review each with `claude -p "/loop-review base"`, grepping the reports for the seeded defects.
  The seeded defects live inside the reviewed diff `base...HEAD` (rubix B2): the base commit lacks `parse_amount`, so the HEAD commit's guard-less `parse_amount` (missing requirement), its `--export-json` flag (scope creep), and its `d` function (Mysterious Name smell) are all part of the change under review.
  The with-spec repo sits on a branch whose name contains the plan's topic slug and carries a second, newer, unrelated plan (rubix A5), so the harness proves branch-match resolves the right plan over the newer one.
  Rationale: the seeded defects are specific enough that "caught and cited" is an objective grep, honoring the brief's `[executed-check]` tags; the fixture repos carry zero loop-stack conventions, so criterion 5 (standalone) is covered by construction.

## Global constraints

- Fork Matt's code-review `SKILL.md` as the skeleton; keep its two-parallel-subagent structure and side-by-side, never-merged reporting.
- Keep the Fowler 12-smell baseline verbatim (reproduced in Task 1 below); the repo's own documented standards override it, each smell stays a judgement call, skip anything tooling already enforces.
- Remove Matt's `docs/agents/issue-tracker.md` dependency; the skill must run in a repo with zero loop-stack or setup conventions.
- The report opens with a disclosure block naming the resolved spec source and standards sources before any finding.
- The disclosure distinguishes two no-spec outcomes (rubix A6): "no spec available (confirmed: none exists)" when the user confirms there is none, versus "no spec available (not found automatically ...)" as a warning when discovery simply missed it; both contain the exact phrase "no spec available."
- The fixed point must be an ancestor of HEAD with a non-empty diff; an empty diff fails early with an actionable message telling the user to run from the finished branch or pass the pre-work ref (rubix A3).
- Reviewer model is referenced by role (review / validation gate), never a hard-pinned model name.
- Markdown rules for every file this plan creates or edits: one full sentence per line, plain dashes only (never the em dash), never the section symbol, no agent co-author lines.
- `skills/loop-review/` is a single-file skill dir (`SKILL.md` only); install.sh's `for TARGET in "$REPO"/skills/*` loop symlinks it automatically, so no installer edit is required.
- Exact end-user usage is `/loop-review <fixed-point>` run from the finished branch, for example `/loop-review main` from a feature branch, or `/loop-review HEAD~3`.

## Dependency graph

```
Task 1 (loop-review skill + fixtures + harness + install verify)
   |
   v
Task 2 (loop-drive advisory terminal-review hookup)   -- references Task 1's invocation contract
```

Two waves, sequential.
Task 2 depends on Task 1 for the invocation contract (`/loop-review <fixed-point>`).
The files are disjoint (`skills/loop-review/**` vs `skills/loop-drive/SKILL.md`), so the dependency is contract-only, not a file conflict.

## Human checkpoints

- **HC1 - fixture report read (after Task 1).**
  A human reads one saved fixture report and confirms the two-axis output reads usefully beyond the grepped tokens (the Spec and Standards findings are coherent and correctly separated).
  This is the one judgement the grep cannot make; it does not gate the acceptance check but is offered before Task 2.

- **HC2 - loop-drive integration read (after Task 2).**
  A human confirms the advisory terminal-review paragraph reads correctly in Step 5's flow, is honest that it does not block the advance, and does not contradict the per-unit validator language.

- **HC3 - first real deliverable (post-plan, the payoff).**
  Run `/loop-review <ref>` against the next real diff the user finishes, the day the skill lands (the brief's first real deliverable).
  Not a build task; it needs a real diff that does not exist yet.

## How to run

```bash
# Prerequisites: the loop-review skill must be discoverable by the claude CLI.
# install.sh symlinks it automatically once skills/loop-review/ exists:
./install.sh            # non-interactive: LOOP_STACK_SKILL_STYLE=agents ./install.sh

# Fast deterministic check only (no model calls, cheap - safe to run every commit):
LOOP_REVIEW_SKIP_BEHAVIOR=1 bash tests/loop-review/acceptance.sh

# Full acceptance including the behavioral E2E (spawns ~2 headless reviews x 2 subagents,
# so it costs a few model turns and carries some LLM variance - run deliberately, not on every commit):
bash tests/loop-review/acceptance.sh    # exits 0 on pass, prints the failing check on fail

# Real usage, run from the finished branch, in any repo:
#   /loop-review main       (from a feature branch)
#   /loop-review HEAD~3
#   /loop-review <sha-or-tag>
```

The harness assumes `claude` is on PATH (confirmed at `~/.local/bin/claude`), `git` is available, and the skill has been installed so `/loop-review` resolves.
Layer A (structural) is the RED driver and a free regression check; layer B (behavioral) is the honest end-user E2E and the only layer that costs model turns.
loop-drive never runs this harness - it invokes the `/loop-review` skill directly at runtime, so the harness cost is a build-time expense, not a per-run one (rubix B5).

---

### Task 1: loop-review skill, fixtures, and acceptance harness

Depends on: none

**Files (exclusive ownership):**
- Create: `skills/loop-review/SKILL.md`
- Create: `tests/loop-review/acceptance.sh`
- Create: `tests/loop-review/build-fixtures.sh`

**Interfaces:**
- Produces: a skill invoked as `/loop-review <fixed-point>` where `<fixed-point>` is any git ref (SHA, branch, tag, `HEAD~N`); an optional second argument is an explicit spec path.
- Produces: a report whose first block discloses the resolved spec source and the standards sources, followed by a `## Spec` section and a `## Standards` section, never merged, ending with a per-axis one-line summary.
- Produces: `tests/loop-review/acceptance.sh`, one command, exit 0 on pass.

**Acceptance check:** `bash tests/loop-review/acceptance.sh` exits 0 `[executed-check]`

**The skill's required content (the fork spec).**

Start from Matt's skill at `/Users/jjrdar/repos/mattpocock/skills/skills/engineering/code-review/SKILL.md` and keep its skeleton: pin the fixed point, identify the spec source, identify the standards sources, spawn two parallel subagents (one Spec, one Standards), aggregate side by side under `## Spec` and `## Standards`, and the closing "Why two axes" rationale.
Do not drop Matt's `agents/openai.yaml`; simply do not create it (this fork dispatches via the general-purpose Agent tool, not a codex agent file).

Apply exactly these deltas from Matt's version:

1. **Frontmatter.**
   `name: loop-review`.
   One dense `description` sentence covering: two-axis review (Spec and Standards) of the diff since a user-supplied fixed point, discloses its resolved sources before its findings, runs both axes as parallel fresh-context subagents, works in any repo with zero setup, use when the user wants to judge whether finished work (loop-driven or hand-made) was good or asks to "review since X".

2. **Fixed point (keep Matt's structure; delta - actionable empty-diff message).**
   Whatever ref the user passed is the fixed point; if none, ask.
   Capture `git diff <fixed-point>...HEAD` (three-dot, against the merge-base) and the commit list `git log <fixed-point>..HEAD --oneline`.
   Confirm the ref resolves (`git rev-parse <fixed-point>`) and the diff is non-empty before spawning any subagent; a bad ref or empty diff fails here, not inside a subagent.
   On an empty diff, fail with an actionable message rather than a bare error (rubix A3): "No commits between `<fixed-point>` and HEAD. Run loop-review from the branch you finished, or pass the pre-work ref (for example `HEAD~3` or the commit you branched from)." This is the flagship-command trap: `/loop-review main` run while sitting on `main` produces an empty diff, so the message must point the user to the fix.

3. **Spec discovery chain (delta - replaces Matt's issue-tracker-first order).**
   Resolve the spec source in this fixed order, stopping at the first hit:
   1. An explicit path passed as the second argument to the skill.
   2. A plan under `docs/plans/` whose topic slug appears in the current branch name (`git rev-parse --abbrev-ref HEAD`).
   3. A brief under `docs/briefs/` by the same branch-name match.
   4. Issue references in the commit messages (`#123`, `Closes #45`); fetch the referenced issue with the `gh` CLI (`gh issue view <n>`) if `gh` is available and authenticated; if it is not, record the reference text as the spec pointer and note it was not fetched.
   5. If nothing matched, ask the user where the spec is; if plans or briefs exist but none matched the branch, offer the most recent by `YYYY-MM-DD` filename date as a labeled suggestion the user must confirm - never auto-resolve to it (rubix A1).
   6. If the user confirms there is none, the disclosure reports "no spec available (confirmed: none exists)" and the Spec axis is skipped; the Standards axis still runs.
   7. If the skill cannot ask (non-interactive or headless), it does not block: the disclosure reports "no spec available (not found automatically - none passed and nothing matched under docs/plans or docs/briefs; pass an explicit path if one exists)" as a warning, and the Standards axis still runs (rubix A6).
   There is no dependency on `docs/agents/` or any setup file.

4. **Standards sources (keep Matt's, verbatim behavior + verbatim baseline).**
   Collect anything in the repo documenting how code should be written (`CODING_STANDARDS.md`, `CONTRIBUTING.md`, and the like).
   On top of whatever the repo documents, the Standards axis always carries the Fowler smell baseline reproduced below.
   Two binding rules: a documented repo standard always wins and suppresses a baseline smell it endorses; every smell is a labelled judgement call ("possible Feature Envy"), never a hard violation, and anything tooling already enforces is skipped.
   Reproduce this baseline verbatim inside the skill (the Standards subagent has no other access to it):

   - **Mysterious Name** - a function, variable, or type whose name does not reveal what it does or holds. -> rename it; if no honest name comes, the design is murky.
   - **Duplicated Code** - the same logic shape appears in more than one hunk or file in the change. -> extract the shared shape, call it from both.
   - **Feature Envy** - a method that reaches into another object's data more than its own. -> move the method onto the data it envies.
   - **Data Clumps** - the same few fields or params keep travelling together (a type wanting to be born). -> bundle them into one type, pass that.
   - **Primitive Obsession** - a primitive or string standing in for a domain concept that deserves its own type. -> give the concept its own small type.
   - **Repeated Switches** - the same `switch`/`if`-cascade on the same type recurs across the change. -> replace with polymorphism, or one map both sites share.
   - **Shotgun Surgery** - one logical change forces scattered edits across many files in the diff. -> gather what changes together into one module.
   - **Divergent Change** - one file or module is edited for several unrelated reasons. -> split so each module changes for one reason.
   - **Speculative Generality** - abstraction, parameters, or hooks added for needs the spec does not have. -> delete it; inline back until a real need shows.
   - **Message Chains** - long `a.b().c().d()` navigation the caller should not depend on. -> hide the walk behind one method on the first object.
   - **Middle Man** - a class or function that mostly just delegates onward. -> cut it, call the real target direct.
   - **Refused Bequest** - a subclass or implementer that ignores or overrides most of what it inherits. -> drop the inheritance, use composition.

5. **Disclosure opener (delta - new, before any finding).**
   Before the two axis sections, the report opens with a short disclosure block that names, in plain text:
   - The resolved spec source and which discovery rung produced it, using the exact phrase "matched by branch name" when rung 2 or 3 resolved it (for example: "Spec source: `docs/plans/2026-07-21-loop-review-plan.md` (plan, matched by branch name)"), or one of the two no-spec wordings from delta 3 rungs 6 and 7.
   - The standards sources (each documented file found, plus "Fowler 12-smell baseline").
   This block is the skill's basis-before-findings contract; it always precedes `## Spec` and `## Standards` (the harness asserts this ordering).

6. **Two parallel subagents (keep Matt's structure; delta - model by role, medium effort).**
   Send one message with two Agent-tool calls, both `general-purpose`, at medium reasoning effort.
   Choose the reviewer model by its role (a review / validation gate) per the user's routing conventions if present, else the session's default capable model; do not hard-pin a model name.
   - **Standards subagent** gets: the diff command and commit list; the standards-source file list; the full Fowler baseline pasted in; and the brief - "Report, per file/hunk where relevant: (a) every place the diff violates a documented standard, citing the standard (file plus the rule); and (b) any baseline smell you spot, naming it with its baseline label verbatim (for example 'Mysterious Name') and quoting the offending symbol or hunk. Distinguish hard violations from judgement calls; documented-standard breaches can be hard, baseline smells are always judgement calls, and a documented repo standard overrides the baseline. Skip anything tooling enforces. Under 400 words."
   - **Spec subagent** gets: the diff command and commit list; the path or fetched contents of the spec; and the brief - "Report: (a) requirements the spec asked for that are missing or partial; (b) behaviour in the diff that was not asked for (scope creep); (c) requirements that look implemented but where the implementation looks wrong. Quote the spec line for each finding. Under 400 words."
   If the spec is missing, skip the Spec subagent and note it in the report.

7. **Aggregate (keep Matt's, verbatim behavior).**
   Present the two reports under `## Spec` and `## Standards`, verbatim or lightly cleaned, never merged or reranked.
   End with a one-line per-axis summary (findings per axis, worst issue within each axis); do not pick a single cross-axis winner.
   Every finding must cite its spec line or its named standard.

8. **Why two axes (keep Matt's closing rationale).**

**The fixtures and harness (the test - verbatim).**

`tests/loop-review/build-fixtures.sh` creates two throwaway git repos under a temp dir passed as `$1`.
The base commit deliberately lacks `parse_amount`, so all three seeded defects land inside the reviewed diff `base...HEAD` (rubix B2): a missing requirement (Spec), a scope-creep flag (Spec), and a Mysterious Name smell (Standards).
The with-spec repo sits on a branch named for the plan slug and carries a second, newer, unrelated plan so branch-match is genuinely exercised against a most-recent decoy (rubix A5).

```bash
#!/usr/bin/env bash
# Builds two fixture repos under $1: "with-spec" and "no-spec".
# Base commit is tagged 'base' and does NOT contain parse_amount, so the HEAD
# commit's guard-less parse_amount is part of the reviewed diff base...HEAD.
set -euo pipefail
ROOT="${1:?usage: build-fixtures.sh <tmpdir>}"

seed_repo() {
  # $1 = repo dir, $2 = "with-spec" | "no-spec"
  local dir="$1" mode="$2"
  mkdir -p "$dir/src"
  git -C "$dir" init -q
  git -C "$dir" config user.email test@example.com
  git -C "$dir" config user.name test
  # base: a stub with NO parse_amount, so parse_amount (and its missing guard) is added in the diff.
  printf 'def cli(args):\n    return None\n' > "$dir/src/money.py"
  git -C "$dir" add -A
  git -C "$dir" commit -q -m "base: cli stub"
  git -C "$dir" tag base
  if [ "$mode" = with-spec ]; then
    # Branch name contains the plan's topic slug ("money") so branch-match resolves.
    git -C "$dir" checkout -q -b money-cli
    mkdir -p "$dir/docs/plans"
    cat > "$dir/docs/plans/2099-01-01-money-plan.md" <<'SPEC'
# Money Plan
- parse_amount MUST reject negative inputs by raising ValueError.
- Add a --verbose flag to the CLI.
SPEC
    # A NEWER, unrelated plan: most-recent-by-date would wrongly pick this;
    # branch-match must still resolve the money plan, not this decoy.
    cat > "$dir/docs/plans/2099-02-01-widget-plan.md" <<'SPEC2'
# Widget Plan
- Add a Widget renderer.
SPEC2
    git -C "$dir" add -A
    git -C "$dir" commit -q -m "spec: money + widget plans"
  else
    git -C "$dir" checkout -q -b work   # non-matching branch, no docs/ at all
  fi
  # HEAD: the change under review. All three defects are inside base...HEAD:
  #  - parse_amount added WITHOUT the required negative guard  (missing req -> Spec)
  #  - an unrequested --export-json flag                       (scope creep -> Spec)
  #  - a Mysterious Name `d`                                   (smell       -> Standards)
  cat > "$dir/src/money.py" <<'CODE'
def parse_amount(s):
    return int(s)

def d(x):
    return x * 100

def cli(args):
    if "--export-json" in args:
        return "{}"
    return d(parse_amount(args[0]))
CODE
  git -C "$dir" add -A
  git -C "$dir" commit -q -m "feat: parse_amount + cli"
}

seed_repo "$ROOT/with-spec" with-spec
seed_repo "$ROOT/no-spec" no-spec
```

`tests/loop-review/acceptance.sh` runs two layers: A) deterministic structural greps over `SKILL.md` (no model calls, the RED driver and cheap regression check), then B) one real headless review per fixture, grepping the reports for the seeded defects.

```bash
#!/usr/bin/env bash
# Acceptance harness for loop-review.
#   Layer A (structural): deterministic greps over SKILL.md - no model calls. Drives RED; cheap to re-run.
#   Layer B (behavioral): one real headless review per fixture - costs a few model turns, some LLM variance.
# Exits 0 only if both layers pass. LOOP_REVIEW_SKIP_BEHAVIOR=1 runs layer A alone.
# NOTE: not -e. Each check handles its own failure so the message always prints (rubix B6).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SKILL="$REPO/skills/loop-review/SKILL.md"
fail() { echo "FAIL: $1" >&2; exit 1; }

# ---- Layer A: structural (deterministic, no model calls) ----
[ -f "$SKILL" ]                        || fail "skills/loop-review/SKILL.md missing"
grep -q  '^name: loop-review'   "$SKILL" || fail "frontmatter name is not loop-review"
grep -qi 'no spec available'    "$SKILL" || fail "SKILL.md never defines the no-spec wording"
grep -qi 'matched by branch name' "$SKILL" || fail "SKILL.md missing the branch-match disclosure phrasing"
grep -qi 'Fowler'               "$SKILL" || fail "SKILL.md missing the Fowler baseline"
grep -qi 'Mysterious Name'      "$SKILL" || fail "SKILL.md missing the smell baseline body"
grep -Eqi '## +Spec'            "$SKILL" || fail "SKILL.md does not mandate a ## Spec section"
grep -Eqi '## +Standards'       "$SKILL" || fail "SKILL.md does not mandate a ## Standards section"
echo "structural: PASS"
[ "${LOOP_REVIEW_SKIP_BEHAVIOR:-0}" = 1 ] && { echo "PASS: structural only (behavior skipped)"; exit 0; }

# ---- Layer B: behavioral (real headless reviews) ----
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
bash "$HERE/build-fixtures.sh" "$TMP" >/dev/null || fail "fixture build failed"

# --dangerously-skip-permissions: this runs ONLY against the throwaway temp repos built above,
# and the skill is read-only in intent (git-read, Read, Grep, Agent). Never point it at a real repo.
run_review() {  # $1 = repo dir -> prints report to stdout
  ( cd "$1" && claude -p "/loop-review base" --dangerously-skip-permissions )
}

# Capture without aborting so a CLI non-zero exit yields our message, not a silent die (rubix B6).
WITH="$(run_review "$TMP/with-spec")" || fail "with-spec review did not run (claude exited non-zero)"
NO="$(run_review   "$TMP/no-spec")"   || fail "no-spec review did not run (claude exited non-zero)"
[ -n "$WITH" ] || fail "with-spec produced an empty report"
[ -n "$NO" ]   || fail "no-spec produced an empty report"

# with-spec: discloses the BRANCH-MATCHED money plan, and NOT the newer unrelated widget decoy (rubix A5)
grep -qi '2099-01-01-money-plan.md' <<<"$WITH" || fail "did not disclose the money plan as spec source"
grep -qi 'widget-plan'              <<<"$WITH" && fail "resolved the wrong (newer, unrelated) plan"
# disclosure precedes the first axis section - basis before findings (rubix B4)
d_line="$(grep -ni 'spec source' <<<"$WITH" | head -1 | cut -d: -f1)"
s_line="$(grep -ni '## *Spec'    <<<"$WITH" | head -1 | cut -d: -f1)"
{ [ -n "$d_line" ] && [ -n "$s_line" ] && [ "$d_line" -lt "$s_line" ]; } \
    || fail "disclosure block does not precede the ## Spec section"
# two axes present and separate
grep -qi '## *Standards' <<<"$WITH" || fail "no ## Standards section (with-spec)"
# Spec axis: catches the in-diff missing requirement AND cites the spec line (ValueError appears only in the spec)
grep -qi 'negativ'    <<<"$WITH" || fail "Spec axis missed the negative-input requirement"
grep -qi 'ValueError' <<<"$WITH" || fail "Spec finding does not cite the spec line (no ValueError)"
# Spec axis: catches the scope-creep flag (rubix B9)
grep -qi 'export-json' <<<"$WITH" || fail "Spec axis missed the --export-json scope creep"
# Standards axis: names the smell AND the symbol `d` on one finding line (rubix B3).
# Requiring both on a line rejects the baseline-definition echo (which has no lone `d`) and plain prose,
# while allowing words between the label and the symbol in either order.
grep -Eqi 'mysterious name.*\bd\b|\bd\b.*mysterious name' <<<"$WITH" \
    || fail "Standards axis did not flag \`d\` as a Mysterious Name"

# no-spec: NOT-FOUND warning wording (rubix A6), Standards axis still delivers a concrete finding (rubix B3)
grep -qi 'no spec available'       <<<"$NO" || fail "no-spec run did not report 'no spec available'"
grep -qi 'not found automatically' <<<"$NO" || fail "no-spec run did not warn 'not found' vs 'confirmed none'"
grep -qi '## *Standards'           <<<"$NO" || fail "no-spec run dropped the Standards axis"
grep -Eqi 'mysterious name.*\bd\b|\bd\b.*mysterious name' <<<"$NO" \
    || fail "no-spec Standards axis produced no concrete finding"

echo "PASS: axes, disclosure ordering, spec citation, scope creep, and no-spec warning all verified"
```

Ceiling: layer B invokes real headless reviews, so it costs a few subagent turns and carries LLM variance; the greps target mandated-format tokens (the disclosed filename, the exact "no spec available" / "not found automatically" strings, `ValueError` which lives only in the spec, the symbol `d` beside a Mysterious-Name cue) to keep variance low and false-passes out.
This is deliberate - it is the honest end-user E2E path (`/loop-review base`), not a mock.
The RED driver is layer A (deterministic), so RED never depends on the model; layer B only runs once the skill file exists.

- [ ] Step 1: Write `tests/loop-review/build-fixtures.sh` and `tests/loop-review/acceptance.sh` verbatim as above; `chmod +x` both.
- [ ] Step 2: Run `LOOP_REVIEW_SKIP_BEHAVIOR=1 bash tests/loop-review/acceptance.sh` before the skill exists - expect FAIL at "skills/loop-review/SKILL.md missing". This is deterministic RED (rubix B1: RED does not depend on the CLI honoring the skill).
- [ ] Step 3: Write `skills/loop-review/SKILL.md` per the fork spec above; run `./install.sh` (or `LOOP_STACK_SKILL_STYLE=agents ./install.sh`) so `/loop-review` resolves; confirm the symlink appears (`ls -l ~/.claude/skills/loop-review`) and layer A now passes (`LOOP_REVIEW_SKIP_BEHAVIOR=1 bash tests/loop-review/acceptance.sh`).
- [ ] Step 4: Pin the headless invocation form (rubix B1). Build the fixtures to a scratch dir (`bash tests/loop-review/build-fixtures.sh /tmp/lr-probe`) and run `run_review` by hand on `/tmp/lr-probe/with-spec` once; confirm a disclosure block returns. If the leading-slash form is not honored by `claude -p` in headless mode, change `run_review`'s prompt to the natural-language trigger (`"Use the loop-review skill to review the diff since ref base"`) and keep that form for Step 5.
- [ ] Step 5: Run the full `bash tests/loop-review/acceptance.sh` - expect PASS (both layers). This is GREEN.
- [ ] Step 6: Commit - `git add skills/loop-review/SKILL.md tests/loop-review/ && git commit -m "Add loop-review skill: two-axis spec+standards review with source disclosure"`

---

### Task 2: loop-drive advisory terminal-review hookup

Depends on: Task 1

**Files (exclusive ownership):**
- Modify: `skills/loop-drive/SKILL.md` - the Step 5 item "Advance only on a green integration branch" and the Step 6 item 6 procedure line (located by their quoted anchor text, not line numbers, which drift - rubix B10)

**Interfaces:**
- Consumes: the invocation contract from Task 1, `/loop-review <fixed-point>`, where `<fixed-point>` is the pre-run base ref and HEAD is the integration branch tip.

**Precondition to verify first (rubix A5):**
Before writing the routing sentence, confirm loop-drive already has a downstream-slip mechanism to route a Spec-axis finding into.
It does: Step 5 item 2 says "a design issue is recorded for the plan's downstream review step under the source plan's slip rules," and item 4 carries the ask-the-human list.
Scope the added text to those existing mechanisms only; do not invent new machinery.

**Acceptance check:** `awk '/Advance only on a green integration branch/{f=1} /^## Step 6/{f=0} f' skills/loop-drive/SKILL.md | grep -qi 'loop-review' && grep -qi 'terminal loop-review' skills/loop-drive/SKILL.md` exits 0 `[executed-check]`

The first clause proves the invocation sits specifically inside the Step 5 green-advance item (the awk range runs from that anchor to the Step 6 heading), not merely somewhere in the file (rubix B7); the second proves Step 6's emitted procedure list names it.

Add an advisory terminal artifact review to loop-drive's final advance.
This is the "was the whole run good?" check the brief names as the closed gap; it is distinct from the per-unit validators (which own per-unit correctness) and runs once, on the whole-run diff.
It is advisory, not a blocking gate (rubix A4): the per-unit validators already gated correctness during the waves, so this review runs after the final advance and cannot hold it.

Content to add under the Step 5 item "Advance only on a green integration branch", as a short closing paragraph:

> On the final wave only, after the integration branch is green and the run advances, run the advisory terminal artifact review: `/loop-review <pre-run-base>` from the integration branch, so the two-axis Spec and Standards report judges the whole-run diff.
> This review is advisory and non-blocking - the per-unit validators already gated correctness, so it runs after advancement and does not hold it; its findings are recorded at the final human checkpoint (the ask-the-human list above), and a Spec-axis finding is slipped to the plan's downstream review step under the same slip rules used for a stopped unit's design issue.

Update the Step 6 item 6 procedure line so the emitted list names it:

> 6. The wave-loop procedure and gate checklist from Step 5, including slip rules, the ask-the-human list, and the final-wave advisory terminal loop-review review.

Do not change the per-unit validator language in Step 4 or the gate structure in Step 5 items 1-3; the only addition is the advisory terminal review on the final advance.

- [ ] Step 1: Run the acceptance check now - expect FAIL (no `loop-review` mention in loop-drive yet). This is RED.
- [ ] Step 2: Confirm the precondition above by reading loop-drive Step 5 items 2 and 4; then edit `skills/loop-drive/SKILL.md` at the two anchors per the content above, following the markdown rules (one sentence per line, plain dashes).
- [ ] Step 3: Run the acceptance check - expect exit 0 (PASS).
- [ ] Step 4: Commit - `git add skills/loop-drive/SKILL.md && git commit -m "loop-drive: advisory terminal loop-review on the final wave"`
