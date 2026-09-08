#!/usr/bin/env python3
# Emit the four seam-1 wave manifests from the source plan, per the _loop.md Section 8 assembly
# rule: one authored copy (the plan) plus the per-task fields tabled here. Re-runnable; a resume
# session regenerates identical manifests with `python3 emit.py` from this directory.
import json
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
PLAN = REPO / "docs/plans/2026-09-07.I52.seam1-recording-convention-plan.md"
PATCH_DIR = "/Users/jjrdar/.ringer/work/i52-seam1-recording-convention/patches"

lines = PLAN.read_text().splitlines()

# preamble: everything before '### Task 1: '
for i, ln in enumerate(lines):
    if ln.startswith("### Task 1: "):
        preamble = "\n".join(lines[:i])
        break
else:
    sys.exit("plan preamble boundary not found")


def task_section(n):
    out, in_task, fence = [], False, False
    head = re.compile(r"^### Task %d: " % n)
    for ln in lines:
        if not in_task and head.match(ln):
            in_task = True
        if not in_task:
            continue
        if ln.startswith("```"):
            fence = not fence
        if not fence and ln == "---":
            break
        if re.match(r"^- \[ \] Step \d+: Commit", ln):
            continue
        out.append(ln)
    if not out:
        sys.exit("task %d section not found" % n)
    return "\n".join(out)


def canonical_test(n):
    sec = task_section(n).splitlines()
    for i, ln in enumerate(sec):
        if re.match(r"^- \[ \] Step 1: Write the failing test", ln):
            j = i
            while not sec[j].startswith("```"):
                j += 1
            k = j + 1
            while not sec[k].startswith("```"):
                k += 1
            return "\n".join(sec[j + 1:k])
    sys.exit("canonical test for task %d not found" % n)


OWN = {
    "t1-session-card": ["scripts/session-card.sh", "tests/sessions/session-card.sh",
                        "tests/hardcodes/sweep.sh"],
    "t2-handoff-log": ["scripts/handoff-log.sh", "scripts/lifecycle-lint.sh",
                       "config/repo-state.md", "tests/sessions/handoff-lifecycle.sh"],
    "t4-card-marker": ["scripts/board-cards.sh", "scripts/board-render-obsidian.sh",
                       "tests/board/cards.sh", "tests/board/render.sh"],
    "t3-take-stock": ["scripts/take-stock.sh", "tests/sessions/take-stock.sh"],
    "t5-board-wiring": ["scripts/board-cards.sh", "scripts/tracker.sh",
                        "scripts/board-render-obsidian.sh", "tests/board/cards.sh"],
    "t9-template-v7": ["config/repo-state.template.md", "config/conventions.template.md",
                       "config/conventions.md", "skills/loop-setup/setup.sh",
                       "skills/handoff/SKILL.md", "config/context-map.md",
                       "tests/loop-setup/reconcile.sh"],
}
SCOPED = {
    "t1-session-card": "bash tests/sessions/session-card.sh && bash tests/hardcodes/sweep.sh",
    "t2-handoff-log": 'for t in tests/sessions/*.sh tests/loop-setup/*.sh; do bash "$t" || exit 1; done',
    "t4-card-marker": 'for t in tests/board/*.sh; do bash "$t" || exit 1; done',
    "t3-take-stock": "bash tests/sessions/take-stock.sh",
    "t5-board-wiring": "bash tests/board/cards.sh && bash tests/run.sh",
    "t9-template-v7": "bash tests/loop-setup/reconcile.sh && bash tests/loop-setup/docs-gitlab.sh && bash tests/run.sh",
}
TASKNUM = {"t1-session-card": 1, "t2-handoff-log": 2, "t4-card-marker": 4,
           "t3-take-stock": 3, "t5-board-wiring": 5, "t9-template-v7": 9}
TESTPATH = {
    "t1-session-card": "tests/sessions/session-card.sh",
    "t2-handoff-log": "tests/sessions/handoff-lifecycle.sh",
    "t4-card-marker": "tests/board/cards.sh",
    "t3-take-stock": "tests/sessions/take-stock.sh",
    "t5-board-wiring": "tests/board/cards.sh",
    "t9-template-v7": "tests/loop-setup/reconcile.sh",
}
OVERWRITE = {"t1-session-card", "t2-handoff-log", "t3-take-stock"}
VERIFIED = {
    "t1-session-card": "The canonical session-card lifecycle suite passes: open/log/close, the closed status vocabulary, the -2 collision suffix, the same-second tie exit 7, and harness-agnostic fields; the hardcodes sweep still passes with docs/sessions/ allowed.",
    "t2-handoff-log": "The canonical handoff-lifecycle suite passes: action enumeration including numbered items, consume refused while any action lacks a disposition, an append-only Transitions log, the all-bulk and zero-action paths, the announced auto-archive with its -2 collision, and lint class h gated on lifecycle-lint-since.",
    "t4-card-marker": "The board cards and render suites pass at 13 fields, with marker emitted as frontmatter and as a title prefix, and a 12-field row now rejected atomically.",
    "t3-take-stock": "The canonical take-stock suite passes: the report names the authoritative handoff and a next step, --cards emits 7-field rows with exactly one repo row first, died-mid-work marks at 24 hours, went-stale marks by calendar day, and an empty repo reports rather than failing.",
    "t5-board-wiring": "The board cards suite passes with the session, handoff, and closed-issue sources wired: lanes map per the plan, the wayfinder and lookback exclusions hold, both markers land, the went-stale suppression exception fires, and the failed-source health model is unregressed; the full suite is green.",
    "t9-template-v7": "The reconcile suite passes at template-version 7: rubix-autorun and lifecycle-lint-since both survive a re-render unduplicated, no placeholder is introduced, the Sessions lane row exists, the three new scripts are vendored executable, and conventions.md is byte-identical to the template.",
}
REQUIRED = {
    "t4-card-marker": [
        "a row does not have 13 fields",
        "field 13 (marker) must be empty for an ordinary git card",
        "the marker did not reach the card frontmatter",
        "the marker did not prefix the rendered title",
        "an unmarked card still needs an explicit marker key",
        "an unmarked card must carry no marker prefix in its title",
        "render should reject a 12-field row now that the contract is 13",
        "failed render wiped the prior board",
    ],
    "t5-board-wiring": [
        "a session card closed blocked must land in blocked-on-fact",
        "a live handoff must land in handed-off",
        "a closed issue inside the lookback must land in done",
        "a closed wayfinder issue must get no card, as the open path rules",
        "a done session card outside DONE_LOOKBACK_DAYS must get no card",
        "the blocked-on-fact label is still being skipped (line 104 un-skip)",
        "an unclosed session card older than the threshold must carry the died-mid-work marker",
        "a went-stale repo's git card must carry the went-stale marker",
        "a clean conforming repo with a tracker card must stay suppressed",
        "the went-stale exception must bypass clean-conforming suppression so the marker has a carrier",
        "a row with the session sources wired does not have 13 fields",
        "the failed-source health model regressed once take-stock was wired in",
        "a failed source must still be exactly one card",
    ],
    "t9-template-v7": [
        "v7 accept re-render exited non-zero",
        "re-render did not bump the version to",
        "re-render reset rubix-autorun to ask (the drift bug)",
        "re-render duplicated rubix-autorun",
        "re-render dropped lifecycle-lint-since",
        "re-render duplicated lifecycle-lint-since",
        "the template must carry no LIFECYCLE_LINT_SINCE placeholder",
        "the v7 Lanes table has no Sessions row",
        "the v7 roll did not vendor scripts/",
        "vendored scripts/",
        "the conventions template does not exclude docs/spikes/ from the import sweep",
        "the conventions template does not exclude docs/sessions/ from the import sweep",
        "this repo's conventions.md has drifted from the v7 template",
    ],
}
CUSTODY_OVERWRITE = ("The acceptance test %s is FIXED and AUTHORITATIVE. Write it first, verbatim "
                     "from your task's Step 1 block, exactly as the steps say. The harness then "
                     "OVERWRITES your copy with the canonical text and runs that. You cannot pass "
                     "by editing the test.")
CUSTODY_ASSERT = ("The acceptance test %s is FIXED and AUTHORITATIVE in its assertions. Make "
                  "exactly the replacement or append your task's steps specify, verbatim. The "
                  "harness verifies every required assertion message is present in your file "
                  "before running the suite, and the validator audits your test diff line by "
                  "line. Deleting or weakening any assertion the steps did not authorize "
                  "replacing is an automatic fail.")

HEADER = """You are a code-feature worker (test-first) implementing ONE unit of the loop-stack seam 1 recording convention.
Your current working directory IS a git worktree of the loop-stack-session repo. Edit files here directly.
Do NOT push. Do NOT run git commit at any point: leave every change uncommitted in the worktree.
The harness exports your diff as a patch and the orchestrator applies and commits it. Any commit you make dies with this worktree.
The embedded task text below may end with steps that mention committing; those are stripped, and if any commit instruction survives anywhere in this spec, ignore it.

You own ONLY these paths. Do not create, edit, or delete anything else, anywhere:
%(owned)s

Never touch docs/handoffs/, docs/archive/, docs/reviews/, docs/sessions/, or any repo outside this one. The check audits this mechanically and fails on any path outside the list above.

PORTABILITY (hard constraint): target macOS stock /bin/bash 3.2. No associative arrays, no ${var,,}, no grep -P, no GNU-only flags. `set -uo pipefail` and `export LC_ALL=C` at the top of every new script, BSD `date` first with a GNU `date` fallback, tab-separated pipelines. New scripts get `chmod +x`.

HOW TO RUN YOUR OWN CHECK: %(scoped)s. Do NOT run the full tests/run.sh unless that command includes it; a broader run would trip over a parallel neighbour's in-flight changes. The full suite runs at the wave gate.

ACCEPTANCE TEST CUSTODY: %(custody)s

Work test-first, in the order the task's numbered steps give. If anything is ambiguous, take the most conservative reading, record the question in your final output, and proceed; you cannot ask.
"""

FOOTER = """End your run by printing exactly one JSON object on its own line:
{"unit": "%(key)s", "files_changed": [...], "tests_passed": <n>, "tests_failed": <n>, "deviations": [...], "open_questions": [...], "deferred_items": [...]}
Leave everything uncommitted. The harness exports the patch."""


def check_body(key):
    tp = TESTPATH[key]
    own_re = "|".join(re.escape(p) for p in OWN[key])
    parts = ["set -uo pipefail", "export LC_ALL=C",
             "PATCH=%s/%s.patch" % (PATCH_DIR, key),
             'mkdir -p "$(dirname "$PATCH")"', ""]
    if key in OVERWRITE:
        parts += ["# acceptance-test custody: canonical overwrite",
                  'mkdir -p "$(dirname %s)"' % tp,
                  "cat > %s <<'CANONICAL_TEST_EOF'" % tp,
                  canonical_test(TASKNUM[key]),
                  "CANONICAL_TEST_EOF", ""]
    else:
        parts += ["# acceptance-test custody: every required assertion message must be present",
                  "missing=0",
                  "while IFS= read -r line; do",
                  '  [ -n "$line" ] || continue',
                  '  grep -Fq -- "$line" %s || { echo "CHECK FAIL: required assertion missing from %s: $line"; missing=1; }' % (tp, tp),
                  "done <<'REQUIRED_EOF'",
                  "\n".join(REQUIRED[key]),
                  "REQUIRED_EOF",
                  '[ "$missing" -eq 0 ] || exit 1', ""]
    parts += ["# run the acceptance test, printing everything",
              "bash %s; rc=$?" % tp,
              '[ "$rc" -eq 0 ] || { echo "CHECK FAIL: acceptance test %s exited $rc; its output above names the failed assertion"; exit 1; }' % tp,
              "",
              "# scoped regression gate (this task's suites only)",
              SCOPED[key],
              "rc=$?",
              '[ "$rc" -eq 0 ] || { echo "CHECK FAIL: the scoped regression gate exited $rc; a suite this task can affect regressed"; exit 1; }',
              "",
              "# ownership audit",
              "git add -A",
              'extra="$(git diff --cached --name-only | grep -vE \'^(%s)$\' || true)"' % own_re,
              '[ -z "$extra" ] || { echo "CHECK FAIL: files outside the ownership list were changed:"; printf \'%s\\n\' "$extra"; exit 1; }' % "%s",
              "",
              "# portability audit on changed shell files",
              'bad="$(git diff --cached --name-only | grep -E \'\\.sh$\' | xargs grep -nE \'declare -A|\\$\\{[A-Za-z_]+,,\\}|grep -P\' 2>/dev/null || true)"',
              '[ -z "$bad" ] || { echo "CHECK FAIL: bash 3.2 portability violation (associative array, lowercase expansion, or grep -P):"; printf \'%s\\n\' "$bad"; exit 1; }' % "%s",
              "",
              "# export the patch outside the worktree",
              'git diff --cached > "$PATCH"',
              '[ -s "$PATCH" ] || { echo "CHECK FAIL: exported patch $PATCH is empty; the worker produced no applicable work"; exit 1; }',
              'echo "CHECK PASS: %s"' % VERIFIED[key].replace('"', "'")]
    return "\n".join(parts)


def spec_for(key):
    tp = TESTPATH[key]
    custody = (CUSTODY_OVERWRITE if key in OVERWRITE else CUSTODY_ASSERT) % tp
    header = HEADER % {"owned": "\n".join("- " + p for p in OWN[key]),
                       "scoped": SCOPED[key], "custody": custody}
    footer = FOOTER % {"key": key}
    return (header
            + "\n--- SOURCE PLAN, SHARED CONTRACT (verbatim) ---\n" + preamble
            + "\n--- SOURCE PLAN, YOUR TASK (verbatim) ---\n" + task_section(TASKNUM[key])
            + "\n--- OUTPUT CONTRACT ---\n" + footer)


def task_obj(key):
    return {"key": key, "engine": "claude-zai", "model": "glm-5.2",
            "task_type": "code-feature", "timeout_s": 3600,
            "spec": spec_for(key), "check": check_body(key),
            "expect_files": ["%s/%s.patch" % (PATCH_DIR, key)],
            "verified": VERIFIED[key]}


WAVES = {"wave-1.json": (["t1-session-card", "t2-handoff-log", "t4-card-marker"], 3),
         "wave-2.json": (["t3-take-stock"], 1),
         "wave-3.json": (["t5-board-wiring"], 1),
         "wave-4.json": (["t9-template-v7"], 1)}

for name, (keys, par) in WAVES.items():
    manifest = {"run_name": "i52-seam1-recording-convention",
                "repo": str(REPO),
                "workdir": "/Users/jjrdar/.ringer/work/i52-seam1-recording-convention",
                "worktrees": True, "max_parallel": par,
                "tasks": [task_obj(k) for k in keys]}
    (HERE / name).write_text(json.dumps(manifest, indent=2) + "\n")
    print(name, [(t["key"], len(t["spec"])) for t in manifest["tasks"]])
