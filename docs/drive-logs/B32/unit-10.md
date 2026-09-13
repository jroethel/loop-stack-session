AGENT STATUS unit=u10 branch=b32/u10-evals worktree=/home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/worktrees/u10 verdict=self-pass repairs=0

# Unit 10: Eval suite

## The three discovery answers (step 1), verified 2026-09-13

Verified by two independent routes: the shipped Claude Code 2.1.269 binary's own schema and error strings, and the published `plugin-evals` documentation.
Both agreed on all three.

### (a) Case-level environment override

Claim: a case-level env override exists, as `env:` in `prompt.md` frontmatter (`execution.env` in `case.yaml` form), but its keys are restricted to names matching `EVAL_*`.
How verified: the runner's own rejection message, read out of the binary: `case "<name>" execution.env key "<K>" is not allowed - only EVAL_* keys can be set from case.yaml. Anything else must come from the operator's shell.`
The full frontmatter key sets were read from the same schema: top-level `schema_version, name, description, tags, plugins, runs, expected_outcome`; execution-level `model, max_turns, timeout_seconds, allowed_tools, artifact_publish, growthbook_overrides, append_system_prompt, env`.
Note that `context.scaffold_script` is reachable only from `case.yaml`, never from `prompt.md` frontmatter, where any unknown key is a hard error.
Consequence: `RINGER_ROOT` cannot be set through `env:`.
The `ringer-absent-degraded` case therefore uses the explicit export-first instruction in its prompt body, which is the fallback the plan named.
No guessed `env:` field was written.

### (b) Grader types and match syntax

Claim: the types are exactly `regex`, `tool_order`, `tool_used`, `file_exists`, `llm`, `baseline`.
`regex` takes `pattern`, `flags` (JS RegExp flags), `target`, and `match`, where `match` is `contains`, `not_contains`, or `count:N`.
`file_exists` takes a glob `path` plus an `exists` boolean, and matches the glob against the run's created-file diff, so `*`, `?` and `**/` all work.
`llm` takes `criteria` plus a `focus`.
Both `target` and `focus` accept `last_message`, `trace`, `files`, `mock_calls`, or a `{source: file, path: ...}` mapping.
How verified: read the zod schema and every grader implementation function out of the binary, then cross-checked against the docs.
Consequence: the plan's guesses at `match: count:1`, `file_exists` and `regex` were all real.
The `{source: file, path: ...}` target is what lets the ringer and rubix cases grade the emitted artifact instead of the agent's own account of it.

### (c) Isolated HOME

Claim: the runner isolates `HOME` unconditionally, with no flag or case field to opt out.
Every run gets a throwaway home, a throwaway config directory, and a working directory beneath it, and only the plugin under test is loaded.
How verified: ran a probe case that printed `HOME` and listed the session's skills.
`HOME` was `/tmp/claude-eval-*/home`; the session skill list held only the twelve `jrit-loop:*` skills plus Claude Code's built-ins, with none of the operator's user-level skills present, `rubix-review` among them.
Consequence: `rubix-absent-callout` runs as a real eval, its absent branch fires for real, and it is NOT demoted.
`tests/rubix-callout-wiring.sh` was therefore not written.

## Final case scores, acceptance run of 2026-09-13T21:41:49Z

| Case | Score | Turns | Cost |
| --- | --- | --- | --- |
| `pre-plugin-repo-refusal` | 1.0 | 6 | $0.26 |
| `resume-pointer-written` | 1.0 | 12 | $0.56 |
| `ringer-absent-degraded` | 1.0 | 15 | $1.97 |
| `rubix-absent-callout` | 1.0 | 9 | $0.51 |
| `setup-writes-pointer-docs-only` | 1.0 | 14 | $0.44 |

Every grader passed: 8 in the setup case, 6 in the resume case, 3 in the rubix case, 2 each in the other two.

## Acceptance check exit codes

Step 2, empty scaffold suite, before any case was authored: **exit 1**.
The runner refused to load the single `init --bare` case with `the prompt is still the blank init template`.

Step 12, the five authored cases: **exit 0**, threshold 1.0, every case at 1.0.

Cost reported by the runner for the step 12 run: **$3.74**, 670 seconds wall clock at concurrency 1.
Cost across the whole unit, including three probe runs and one diagnostic pass: roughly $10.9.

## Step 13, the optional stability read

Not run, and it was never a gate.
A three-run sweep projects to roughly $11 against a suite that costs $3.74 for one pass, which is above the `--max-cost-usd 10` ceiling the acceptance command carries, so it would abort partway and report a misleading partial spread.
The flaky surface was identified without paying for the sweep and is recorded in `docs/eval-fixtures-are-engine-neutral.md`: every instability seen while authoring came from an `llm` grader, never from a `regex` or `file_exists` one.

## AMBIGUITIES TAKEN

1. **The pre-plugin fixture is reconstructed in the prompt rather than copied.**
   The plan says the case "points the agent at a copy of `tests/fixtures/pre-plugin-repo/`".
   `CLAUDE_PLUGIN_ROOT` is empty inside a run's shell (verified by probe: `PLUGINROOT=[]`), so the case has no path to the plugin directory and cannot copy anything from it.
   Conservative reading taken: the case reproduces both fixture files byte for byte in its own prompt, so the copy is materialised in the scratch repo.
   Task 8's fixture stays the source of record, and the two must be kept in step by hand if either changes.
   Recorded in the doc as a standing drift risk.

2. **Every case works inside a `repo/` subdirectory, not at the run's working directory root.**
   The plan's assertions name repository-relative paths such as `docs/loop/pointer.md`.
   The run's working directory is seeded with dotfiles that are character devices, so `git add -A` there always fails with exit 128 (`error: .bash_profile: can only add regular files, symbolic links or git-directories`), which would break the two git-dependent cases for a reason having nothing to do with any skill.
   Conservative reading taken: each case creates a `repo/` subdirectory, and the `file_exists` graders use `**/`-prefixed globs so they match with or without the prefix.

3. **`.gitignore` needed no change.**
   Step 11 says to add `evals/results/` if Task 2 did not.
   Task 2 already did, at line 5.
   Checked first, nothing appended.

## DEVIATIONS

1. **`socat` was installed on this host.**
   A case that requests the `Bash` tool cannot run at all without a sandbox backend; the runner refuses rather than running unconfined.
   `bubblewrap` was present via linuxbrew but `socat` was not, and the first probe failed with `sandbox required but unavailable: ... socat not installed`, exit 1, zero turns.
   The acceptance check this task is graded on grants `Bash`, so without it the check cannot pass on this machine at all.
   Installed with `brew install socat` into the existing user-scope linuxbrew prefix: no root needed, additive only, reversible with `brew uninstall socat`.
   Nothing outside that prefix was touched.
   This is the one change made outside the worktree, and it is flagged for the orchestrator because it is a host change, not a repo change.

2. **Two grader assertions were fixed after the diagnostic pass, per step 12's routing rule.**
   Both failures were wrong assertions, not skill misbehaviour, so both were fixed here rather than sent back.
   See FINDINGS for why each was a grader bug rather than a defect.

## FINDINGS

No skill defect was found.
Both diagnostic-pass failures traced to my own grader assertions, and both are recorded here because the near miss is the useful part.

1. **`rubix-absent-callout` failed on letter case, not on behaviour.**
   The `loop-plan` skill emitted the D6 disclose line correctly and exactly once.
   It capitalised the leading word as ordinary sentence capitalisation: `The optional Rubix review skill is not installed in this session; continuing without it.`
   D6 writes that sentence lowercase at `skills/loop-plan/SKILL.md:184` and `skills/loop-brainstorm/SKILL.md:199` only because the spec embeds it mid-sentence.
   My `count:1` regex was case-sensitive and found zero matches.
   Fixed by adding `flags: i` to `evals/rubix-absent-callout/graders/one-absent-callout.md`.
   Worth knowing for any future byte-comparison test of that sentence: a skill that speaks it as a sentence will capitalise it, and a `grep -F` on the lowercase form will miss.

2. **`setup-writes-pointer-docs-only` failed on an ambiguous judge rubric.**
   `loop-setup` did everything the assertions asked: it created only markdown, wrote no executable, touched nothing outside `repo/`, and reported the `find` output as an empty code block.
   The judge voted `PASS FAIL FAIL`, because my criteria said an unpasted `find` output was a FAIL and an empty code block reads as unpasted, and because the agent listed `repo/.git/` among the paths it created, which my "markdown documents only" criterion did not exempt.
   Fixed by rewriting the criteria to accept an empty code block or a plain statement that nothing printed, and to exempt the `.git` directory that `git init` creates.

3. **A design property of D11 worth carrying forward.**
   The `## Expected behavior` section is the last thing in each prompt body, so the agent under test reads its own assertions before acting.
   That is what makes the section portable across runners, and it is what D11 chose, but it does soften every case: a skill that would not reach the right behaviour unprompted can still be led to it by the assertion list.
   These five cases prove the skills CAN reach the named outcomes, not that they reach them unbidden.
   The unled reading is left to the static tests under `tests/`, which read the skill files directly.
   Recorded in `docs/eval-fixtures-are-engine-neutral.md` as well, since it belongs with the fixtures.

4. **Not a defect, but the orchestrator should know:** `ringer-absent-degraded` cost $1.97 of the suite's $3.74 and emitted a 57k-character plan.
   Its `llm` grader carries the runner's own long-input noise warning.
   If this suite ever needs to get cheaper, that case is where the money is.
