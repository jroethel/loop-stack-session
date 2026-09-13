# Task 3 (U03) - CI: structure, budget, drift, secrets, and consumer checks

Date: 2026-09-13.
Worktree: docs/drive-logs/B32/ringer/wave-2/u03-ci (isolated worktree of jrit-loop at skeleton commit b811337).
Spec of record: docs/plans/2026-09-13.B32.jrit-loop-plugin-port-plan.md, Task 3, lines 685-734, with global constraints 418-432, D5-D9, and verified facts 37-65.

## What I read

Plan lines 685-734 (Task 3), 418-432 (global constraints), 203-234 (D5), 236-280 (D6), 282-306 (D7), 308-346 (D8), 348-355 (D9), 37-65 (verified facts), 560-684 (criterion map, deviations, Tasks 1-2), 735-955 (Tasks 4-9, for skip behavior mid-port).
Host reads: ls and jq over ~/.claude/plugins/ (installed-plugins record), the eleven source skill directories under ~/repos/loop-stack-session/skills/ via the Check B pre-run, ~/repos/loop-stack-session/scripts/clean-room.sh (isolation pattern), config/reviewer-conduct-contract.md and config/routing/model-benchmarks.md (files later tasks ship into skills/).
`npx --yes skills --help` and `--version` (skills 1.5.26) to correct the clean-room installer flags at write time.

## Files I wrote (all owned by this task)

- ci/banned-tokens.txt
- ci/reference-allowlist.txt
- ci/structure-check.sh
- ci/budget-check.sh
- ci/version-drift.sh
- ci/secrets-scan.sh
- ci/consumer-sweep.sh
- ci/clean-room-npx.sh
- ci/single-resolution.sh
- ci/run-all.sh
- .github/workflows/ci.yml
- ./NOTES (this file)

No other path was touched; git status shows only .github/ and ci/ as new, and skills/ still holds only .gitkeep.
Probe files created during step 10 were all deleted; `ls -la skills/` confirms no residue.

## Step 7: the installed-plugins record file

Real filename: ~/.claude/plugins/installed_plugins.json (confirmed with ls ~/.claude/plugins/ before writing the parse).
Shape (confirmed with jq .): { "version": 2, "plugins": { "<plugin>@<marketplace>": [ { "scope": "user", "installPath": "<abs path under plugins/cache>", "version": "...", "installedAt": "...", "lastUpdated": "...", "gitCommitSha": "..." } ] } }.
The record held two entries on this host (drawio@365-skills, ponytail@ponytail); the canonical location for a skill is <installPath>/skills/<name>, read from the record, never globbed.
ci/single-resolution.sh records this in its header comment.
Live behavior check: it currently FAILS for all eleven names with "resolves from 2 locations" naming ~/.claude/skills/<n> and ~/.agents/skills/<n>, which is its correct pre-decommission (pre-C3) behavior, since the symlink farm still exists on this host.

## Check B pre-run and the allow-list lines it added

I ran the exact extractor (backticked tokens matching the path regex, docs/ prefixed skipped, allow-listed skipped) over the eleven source skill directories and read every hit.
The prescribed seed (config/repo-state.md, config/conventions.md, AGENTS.md, CLAUDE.md, README.md, ROADMAP.md, ringer.py, MODEL-NOTES.md, AMENDMENTS-PENDING.md, install.sh, setup.sh, ISSUES.md, BACKLOG.md, WAYFINDER.md) was written first.
I also scanned the two config files that later tasks ship into skills/ (reviewer-conduct-contract.md, model-benchmarks.md): the contract yields exactly install.sh and setup.sh, both already seeded; model-benchmarks.md yields nothing.

Lines my pre-run ADDED beyond the prescribed seed (each already carries its `# why` in the file):

- _loop.md - why: drive-unit run-state file in the target repo, named in loop-drive prose as a file that already exists there, not a skill-shipped file.
- PRODUCT.md - why: illustrative example of a decision doc in the audited repo (loop-improve audit playbook), not a reference that must resolve.
- CODING_STANDARDS.md - why: illustrative example of a standards source in the repo under review (loop-review), not a reference that must resolve.
- CONTRIBUTING.md - why: illustrative example of a standards source in the repo under review (loop-review), not a reference that must resolve.

Stragglers the pre-run leaves for the port tasks (deliberately NOT allow-listed; each maps to a rewrite the plan already instructs, so a survivor is a real finding):

- skills/loop-brainstorm/SKILL.md:31 and skills/loop-drive/SKILL.md:15 - principles.md (loop-stack provenance pointer; decide: rewrite or allow-list with a why).
- skills/loop-brainstorm/references/brief-pipeline.md:79 - tracker.sh (Task 5 step 6 rewrites).
- skills/loop-improve/SKILL.md:77,82 - bare brief-pipeline.md (Task 5 step 10 rewrites line 82; line 77 is an unlisted straggler to prefix with references/).
- skills/loop-drive/SKILL.md:30,66,93 and references/ringer-substrate.md:57 - config/routing/model-benchmarks.md (Task 9 and D5 rewrite).
- skills/loop-review/SKILL.md:84,86 and skills/loop-drive/SKILL.md:157,159 - config/reviewer-conduct-contract.md and ./install.sh (D5 replacement block).
- skills/loop-setup/SKILL.md:27 - config/repo-state.template.md, config/conventions.template.md (Task 8 rewrite).
- skills/loop-setup/SKILL.md:72 - scripts/gen-mirrors.sh (Task 8 step 11 deletes).
- skills/loop-track/SKILL.md:48 - graduate-parking.sh (Task 7 straggler; the script is not ported).
- skills/wayfinder/SKILL.md:78 - config/routing/model-benchmarks.md (Task 7 step 14 rewrites).
- loop-track.sh and loop-auto.sh resolve in the source tree but become Check B failures the moment Task 7 deletes the files; any surviving mention is a straggler.

## Step 10 proofs (fail first, then pass)

Proof 1, banned token: probe skills/tmp-probe/SKILL.md containing `${CLAUDE_PLUGIN_ROOT}`.
Failing line: `STRUCTURE FAIL: check A: banned token '${CLAUDE_PLUGIN_ROOT}' appears in shipped files (allowed only in skills/loop-setup/SKILL.md for the docs/chain-state.md deletion naming):` followed by `skills/tmp-probe/SKILL.md:8:Run \`${CLAUDE_PLUGIN_ROOT}/scripts/receipt.sh\` from the skill root.` with exit 1.
Passing rerun after deletion: `PASS: structure` with exit 0.

Proof 2, version drift: README marker changed to `<!-- jrit-loop-version: 9.9.9 -->`.
Failing line: `DRIFT FAIL: version drift: README marker says 9.9.9, plugin.json says 0.1.0` with exit 1.
Passing rerun after revert: `PASS: drift` with exit 0 (marker restored to 0.1.0, confirmed by grep).

Proof 3, executable markdown: chmod +x on skills/tmp-probe/SKILL.md.
Failing line: `BUDGET FAIL: executable files under skills/ other than skills/loop-drive/scripts/receipt.sh:` naming `skills/tmp-probe/SKILL.md`, with exit 1.
Passing rerun after revert and deletion: `PASS: budget` with exit 0.

Proof 4, Check H: probe skills/loop-drive/references/tmp-probe.md (not the appendix).
Failing line with `SendMessage`: `STRUCTURE FAIL: check H: skills/loop-drive/references/tmp-probe.md:1 names SendMessage; harness primitives live only in references/harness-appendix-claude-code.md` with exit 1.
Passing rerun with the line replaced by `Run /loop-drive to start a unit, or /loop-plan when no plan exists.`: `PASS: structure` with exit 0, which proves the trailing character class ($|[^a-z-]) does exactly what its comment claims: the skill-name forms /loop-drive and /loop-plan do not trip the slash-command ban.
Both probe file and the loop-drive directory were then deleted; structure-check still `PASS: structure`.

Extra fail-first proofs beyond the mandated four (same probe allowance, same cleanup):

- Check B: probe backticking `references/nope.md` failed with `backticked token 'references/nope.md' does not resolve at skills/tmp-probe/references/nope.md`, naming file and line.
- Check F: probe frontmatter carrying `license: MIT` failed with `frontmatter key 'license' is not one of name, description, argument-hint, disable-model-invocation`, naming file and line.

## Final acceptance

Command: `bash ci/run-all.sh; echo PASS`.
Exit code: 0 (recorded from the actual run; final line `PASS: all`, then `PASS` echoed).
Both real `claude plugin validate --strict` commands ran (claude binary on PATH) and passed: the marketplace manifest and the plugin manifest.
Skip lines in the passing run, exactly where the spec allows: five byte-equality pairs, helper SLOC, openai.yaml existence, eleven-directory count.
secrets-scan printed `engine: grep fallback (gitleaks not on PATH)`, as expected on this host.

## Ambiguities taken (conservative reading in each case)

1. Check H pointer count when the portable core exists: the spec explicitly fails on more than one appendix-naming sentence but is silent on zero once skills/loop-drive/SKILL.md exists.
I made zero a failure too, because a missing pointer quietly undoes the split the check exists to protect; before the SKILL.md exists the check stays vacuous, so no parallel task is blocked.
2. Check H's scan set when only some loop-drive files exist: I scan whatever exists of SKILL.md plus references/* (minus the appendix), so the check is meaningful the moment any core file lands, not only after Task 9 completes.
3. single-resolution with multiple installed-plugins record entries resolving for one name: I count the canonical category once if any record path resolves, but fail outright if two or more distinct record paths resolve, since that is two real copies.
4. `principles.md` and `loop-improve/SKILL.md:77` from the pre-run: I did not allow-list them, because the plan instructs rewrites of their neighborhoods and a survivor should surface as a straggler to the owning task rather than be silently blessed here.
5. clean-room-npx flag: the plan's `--skill <name>` matched the installer's `--help` exactly (skills 1.5.26: `-s, --skill <skills>`), so no correction was needed; I added `-y` (skip confirmation prompts) because a sandboxed non-TTY run would otherwise hang at the prompt.
6. budget-check SLOC definition for the manifests: same formula as the helper (non-blank, non-whitespace-comment lines); JSON has no comments, so this is simply non-blank lines, printed as info only.

## Open questions

- None blocking. The straggler list above is the only judgment surface, and every entry routes to a task the plan already scopes.
- ci/clean-room-npx.sh was never executed end to end by design: it fetches jroethel/jrit-loop anonymously, the repo is private until checkpoint C4, and the script's header comment says exactly this.
- The GitHub workflow (gitleaks-action, claude CLI install) is unexercised until the repo has a remote and a push; its steps mirror commands verified locally in this session except the action itself.

## Retry 2 record (2026-09-13)

Previous attempt finished the task but exported no patch: the orchestrator's check crashed at line 5 with "TASKDIR: unbound variable" (wave-2.json invokes the check as bare `bash .../checks/u03.sh`, nothing sets TASKDIR), so step 8's export never ran.
Fix on orchestrator instruction: added `TASKDIR="${TASKDIR:-/home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/ringer/wave-2/u03-ci}"` in manifests/checks/u03.sh (outside my owned set, edited only because the orchestrator's retry prompt said "Fix it"; env override still wins).
Verified: `bash .../checks/u03.sh` run bare, as ringer runs it, exits 0 with `PASS: u03-ci`, including the planted-token probe and a clean rerun of run-all.sh.
Patch now exported: docs/drive-logs/B32/patches/u03.patch (950 lines), staging exactly the eleven owned artifacts plus NOTES; no probe residue (skills/ contains only .gitkeep).
