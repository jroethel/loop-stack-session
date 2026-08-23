# loop-setup on a virgin (empty, non-git) directory

Date: 2026-08-22
Target repo: `/Users/jjrdar/create/skills/sys-prompts-cc`
Outcome: succeeded after two clarifying questions and one fix-forward step. Filed [issue #41](https://github.com/jroethel/loop-stack-session/issues/41) against this repo to clean up the failure path hit along the way.

## Context

User ran `/model` (set default model to Sonnet 5, xhigh effort - unrelated housekeeping) then `/loop-setup` inside `sys-prompts-cc`.
That directory turned out to be completely empty (`ls -la` showed only `.` and `..`) and not a git repo (`git status` -> `fatal: not a git repository`).
loop-setup's SKILL.md assumes it runs "inside the target repo," so the first job was deciding what "the repo" even means here before touching `setup.sh`.

## Timeline

1. **Discovered empty, non-git directory.** Ran `pwd`, `ls -la`, `git status` to confirm there was nothing to build on.
2. **Asked the user how to proceed** (AskUserQuestion): init a git repo here, say this is the wrong directory, or just explain what setup.sh would do without running it.
   User answered a custom combo: "init a repo, github" - init git AND use `github` as the tracker mode.
3. **Initialized git.** `git init`, then renamed the default branch from `master` to `main` (`git branch -m main`, confirmed via `git symbolic-ref HEAD` since `git branch` prints nothing on an unborn branch).
4. **First `setup.sh` run** with `LOOP_TRACKER_ANSWER=github` to skip the interactive mode prompt. It got partway through and failed:
   ```
   added docs/chain-state.md to .gitignore
   installed scripts/gen-mirrors.sh
   installed scripts/tracker.sh
   installed scripts/graduate-parking.sh
   installed scripts/migrate-tracker.sh
   installed scripts/lifecycle-lint.sh
   No remote found - choose a tracker mode (no default)
   wrote config/repo-state.md and config/conventions.md (tracker: github)
   github
   no remote - to create one: gh repo create --private
   label idea not created; continuing
   no git remotes found
   FAIL: tracker.sh list failed
   FAIL: gen-mirrors.sh failed
   ```
   Exit code 1. Config and scripts were written, but the mirrors never generated.
5. **Checked `gh auth status`** - already authenticated as `jroethel` with `repo` scope, so nothing blocked on auth.
6. **Asked the user for explicit confirmation before creating a GitHub repo** (an external, shared-state action, not something to fire without a yes): create it private (recommended), create it public, or skip GitHub and fall back to `local` tracker mode.
   User chose public.
7. **Created the remote.** `gh repo create sys-prompts-cc --public --source=. --remote=origin` -> `https://github.com/jroethel/sys-prompts-cc`.
8. **Re-ran `setup.sh`** (no env var needed - the mode was already declared in `config/repo-state.md`, so it didn't re-ask):
   ```
   tracker mode: github (declared); not re-asking
   GitHub remote found: https://github.com/jroethel/sys-prompts-cc.git - suggesting tracker: github
   created label idea
   wrote ./ISSUES.md and ./BACKLOG.md (2026-08-23T00:39:18Z)
   loop-setup complete - nothing to do
   ```
9. **Verified state**: `git status --short` showed the expected untracked scaffold (`.gitignore`, `BACKLOG.md`, `ISSUES.md`, `ROADMAP.md`, `config/`, `scripts/`) - nothing committed yet, by design (loop-setup never commits on your behalf).
10. **Ran the import sweep entry point**, `setup.sh --list-candidates` - empty output, confirming there was nothing to import since the directory started genuinely empty.
11. Reported the summary back to the user; nothing was committed or pushed, left for the user to decide.

## Decisions made (and why)

- **Init git + choose `github` tracker mode**: user's explicit call when asked; not inferred.
- **Public repo, not private**: user's explicit call when asked; the skill's own hint (`gh repo create --private`) defaults to private, but the user overrode it.
- **Did not auto-commit the scaffold**: no instruction to commit was given; per house rules, commits only happen when explicitly requested.

## What went wrong along the way

Step 4's failure is a real bug in `setup.sh`, not user error. Filed as [issue #41](https://github.com/jroethel/loop-stack-session/issues/41); diagnosis below.

### Diagnosis

**Symptom**: in `github` tracker mode with no remote configured, `setup.sh` doesn't cleanly ask for a remote or fail fast - it prints a hint, then crashes two steps later with two stacked `FAIL:` lines and exit 1.

**Root cause** - `setup.sh:462`, in the `github)` case block:
```sh
[ -n "$remote_url" ] || echo "no remote - to create one: gh repo create --private"
```
This is only an `echo`. When `remote_url` is empty it prints the hint and keeps going - there is no branch that stops here. Execution falls through to `setup.sh:470`:
```sh
scripts/gen-mirrors.sh . || fail "gen-mirrors.sh failed"
```
`gen-mirrors.sh` calls `tracker.sh list`, which needs a remote to query GitHub and fails (`no git remotes found`, `FAIL: tracker.sh list failed`), which `gen-mirrors.sh` then propagates as its own `FAIL: gen-mirrors.sh failed`. One missing precondition (no remote) surfaces as two unrelated-looking `FAIL:` lines from two different scripts, plus the earlier unforced `label idea not created; continuing` noise from the label-creation attempt (`gh label create` also silently no-ops without a remote-backed repo).

**Spec/behavior mismatch**: `SKILL.md` describes this path as "offer `gh repo create --private` when no remote exists." The actual code never offers (no prompt, no conditional creation) and never fails fast (no `fail` call) - it hints once and then crashes downstream. "Offer" oversells what the code does.

**Contrast with the working case** - the `gitlab)` branch in the same script (`setup.sh:474-479`) handles the identical precondition correctly:
```sh
host="$(scripts/tracker.sh host 2>/dev/null || true)"
if [ -z "$host" ]; then
  echo "no remote - to create one: GITLAB_HOST=<host> glab repo create <name> --private --skipGitInit"
  echo "then: git remote add origin <url>"
  fail "tracker: gitlab requires an origin remote to resolve the GitLab host"
fi
```
Same shape (print the hint), but it then calls `fail` immediately instead of falling through - one clear message, exit 1, no cascade.

**Recommended fix**: mirror the `gitlab` branch's fail-fast pattern in the `github` branch - when `remote_url` is empty, print the existing hint and call `fail "tracker: github requires an origin remote - create one with: gh repo create --private, then re-run"` right there, before the label-creation attempt and before `gen-mirrors.sh` ever runs. Scoped to the four lines around `setup.sh:462`; no change needed to `gen-mirrors.sh` or `tracker.sh`.

## Final repo state

- `sys-prompts-cc`: local git repo on `main`, remote `origin` -> `https://github.com/jroethel/sys-prompts-cc` (public).
- `config/repo-state.md` / `config/conventions.md` written, tracker declared `github`.
- `scripts/*.sh` installed (`gen-mirrors.sh`, `tracker.sh`, `graduate-parking.sh`, `migrate-tracker.sh`, `lifecycle-lint.sh`).
- `ROADMAP.md`, `ISSUES.md`, `BACKLOG.md`, `.gitignore` present.
- `idea` label created on the GitHub repo.
- Nothing committed to git yet.
