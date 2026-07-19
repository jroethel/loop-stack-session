# Example emitted plan (skeleton)

A self-contained example of what Step 6 emits, sized down to a two-unit toy build with one unit on each transport.
Use it as the shape reference for `<source-plan-name>_loop.md`.
Source plan for this example: a "release-notes tool" run-book with two independent wave-1 units.

---

## 1. What this file is

This is the agent-orchestrated execution plan derived from `release-notes.md`.
The source plan remains the manual fallback; `release-notes.md` stays ground truth for acceptance criteria and scope.
Spec edits made during the run are applied to `release-notes.md`, not just here.

## 2. Routing table

Wave 1 mixes transports: unit `changelog-doc` rides ringer, unit `parser` rides the Agent tool.

| Unit | Wave | task_type | Model | Transport | Engine | Impl. effort | Val. effort | Evidence |
|---|---|---|---|---|---|---|---|---|
| changelog-doc | 1 | docs | glm-5.2 | ringer | claude-zai | medium | check-only | posterior[^1] |
| parser | 1 | code-feature | sonnet | Agent tool | Agent tool | high | high | pin:continuation[^2] |

[^1]: changelog-doc: glm-5.2 first-try 1.00 on docs (3 rows).
[^2]: parser: pinned - the repair pass needs in-session continuation; model from benchmark prior (sonnet, Strong tier; no scoreboard rows for code-feature on Agent tool).

## 3. Orchestration shape and validation layers

One orchestrator session drives the wave; each unit flows implement then validate independently.

```
orchestrator (this session)
└── wave 1
    ├── changelog-doc  ringer / glm-5.2    ──> executed check
    └── parser         Agent tool / Sonnet ──> Opus validator
        gate: merge to integration branch, full suite, distill
```

Three validation layers: implementer self-check, per-unit validator (a ringer `check` for `changelog-doc`, an Opus validator subagent for `parser`), orchestrator gate.

## 4. Hazard mitigations

- changelog-doc (ringer): deliverable `CHANGELOG.md` is gitignored in this repo, so the check `cp`s it outside the worktree before it is deleted (deviation from the source plan, which assumed a persistent checkout).
- parser (Agent tool): own worktree on its own branch; install step inside the worktree; touches only `parser.py` and `test_parser.py` (disjoint from changelog-doc's files).

## 5. Pre-flight checklist

- [ ] Capability probe: ringer present, engines read from `[engines.*]` blocks - not degraded mode.
- [ ] Repo clean; surface any dirty tree to the human.
- [ ] Integration branch `integration/release-notes-loop` created off HEAD.
- [ ] Log dir `logs/loop/` with a file per unit.
- [ ] Ringer engines present (`claude-zai`) and `~/.config/ringer/` configured; `run_name` chosen (`release-notes-loop`).
- [ ] run-state artifact `run-state.json` created.

## 6. Wave-loop procedure and gates

Wave 1 (both units, parallel):

- Ringer unit: `./ringer.py lint wave1.json && ./ringer.py run wave1.json` with `run_name: release-notes-loop`. Ringer's single retry is the repair pass.
- Agent-tool unit: launch `parser` as a background Agent call; on completion launch its Opus validator; one SendMessage repair on failure; a second failure stops it.

Gate:

- Read the ringer run JSON and `<workdir>/logs/`; read the Agent-tool validator verdict and skim the parser diff.
- Apply the reviewed changelog patch and merge the parser branch into the integration branch; run the full suite there.
- Distill any repeated failure into the specs/templates before any next wave (P10); add a MODEL-NOTES line if a run taught something about glm-5.2.
- Advance only on green.

Ask-the-human: dirty tree at pre-flight; effort-cap exceptions; spec edits beyond a clarification; any outward-facing unit.
Slip rule: a design-issue stop is recorded for downstream review, not silently patched.

## 7. Quota and resume

Implementers commit results and logs before returning; run-state updated at every launch and gate.
Reconciliation trusts git over run-state; any unit not confirmed merged-and-tested is relaunched (never resumed).
Verbatim resume prompt:

> "Resume the release-notes loop from `release-notes_loop.md`. Read run-state.json and the real git state of the integration branch and worktrees. Trust git over the state file. Relaunch any unit not confirmed merged and tested. Continue the wave loop from there."

## 8. Templates

### Ringer manifest task (changelog-doc)

```json
{
  "run_name": "release-notes-loop",
  "workdir": "/tmp/release-notes-loop",
  "worktrees": true,
  "repo": "/path/to/repo",
  "max_parallel": 2,
  "tasks": [
    {
      "key": "changelog-doc",
      "task_type": "docs",
      "engine": "claude-zai",
      "model": "glm-5.2",
      "spec": "Generate CHANGELOG.md from the git log since the last tag. You own ONLY CHANGELOG.md. Group commits under Added/Changed/Fixed. Build/verify with: `git log $(git describe --tags --abbrev=0)..HEAD --oneline`. Deliverable: CHANGELOG.md at repo root.",
      "expect_files": ["CHANGELOG.md"],
      "check": "test -f CHANGELOG.md || { echo 'FAIL: CHANGELOG.md missing'; exit 1; }; grep -qiE '## (Added|Changed|Fixed)' CHANGELOG.md || { echo 'FAIL: no grouped sections'; exit 1; }; mkdir -p /tmp/release-notes-loop/exports && cp CHANGELOG.md /tmp/release-notes-loop/exports/CHANGELOG.md; echo OK",
      "verified": "CHANGELOG.md exists with at least one Added/Changed/Fixed section and is copied outside the worktree before deletion."
    }
  ]
}
```

### Agent-tool implementer prompt (parser)

> You are the implementer for unit `parser`. Create your own worktree: `git worktree add ../parser-wt -b parser` (use `git -C <inner-repo> ...` if the project is a nested repo). Install deps inside the worktree.
> Build `parse_commit(line) -> dict` in `parser.py`; tests in `test_parser.py`; run pytest green. You own ONLY `parser.py` and `test_parser.py`.
> If ambiguous: record it in `logs/loop/parser.md`, take the conservative reading, flag it. Never touch main, never push. Commit work and log before returning.
> Return: `{unit, branch, commit, worktree_path, tests_passed, tests_failed, deviations, open_questions, deferred_items}`.

### Agent-tool validator prompt (parser)

> You validate unit `parser`. Try to refute the claim; judge the raw diff and your own test rerun, ignore the implementer's narrative. Do not fix. Check out `{branch}@{commit}` read-only, rerun the suite yourself, walk each criterion with evidence, audit that the diff touches only owned files.
> Return: `{verdict: pass|fail|spec-problem, criteria: [...], notes}`.

## 9. Kicking it off

Human says: "Run the release-notes loop, wave 1."
Per-wave summaries land in `logs/loop/wave-1-summary.md`.
Watch live: `tail -f /tmp/release-notes-loop/logs/*.log` for the ringer unit; `logs/loop/parser.md` and `run-state.json` for the Agent-tool unit; run JSON in `~/.ringer/runs/` at the gate.
If interrupted, use the resume prompt in section 7.
