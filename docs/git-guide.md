# Git for Loop-Stack Work

A working guide for driving loop-stack cycles with git: return points, worktrees, merge gates, and recovery.
Written 2026-08-15 during molt cycle 1 setup; examples use that cycle's names.
Audience: you, plus any session doing git plumbing on your behalf.

## 1. The mental model, five lines

A repo is one object store (`.git/`) plus one or more checkouts (working directories showing some branch).
A commit is a permanent snapshot; nothing committed is ever lost easily.
A branch is a movable pointer to a commit; a tag is a frozen pointer that never moves.
A worktree is an EXTRA checkout sharing the same object store - not a copy of the repo, just another window onto it.
Git enforces: one branch can be checked out in only one worktree at a time.

## 2. Return points: tags

Mark a state you might return to:

```sh
git tag -a v1-pre-molt -m "why this point matters"     # create (annotated = has a message)
git tag -l -n1                                          # list tags with messages
git push origin v1-pre-molt                             # publish the tag to GitHub
```

Return to one:

```sh
git diff v1-pre-molt --stat        # FIRST: see what changed since (look before leaping)
git checkout v1-pre-molt           # visit read-only (detached HEAD - see recovery 5.5)
git reset --hard v1-pre-molt       # DESTRUCTIVE: abandon everything after the tag
```

`reset --hard` is the one to respect: it discards uncommitted work and moves the branch pointer back.
Rule: diff first, reset second, and only on a branch you mean to rewind.

## 3. Worktrees: parallel checkouts without risk to production

Why: your installed skills are symlinks into THIS checkout, so any edit here changes live behavior instantly.
A worktree gives a second checkout on its own branch; live skills stay untouched until you merge.

```sh
git worktree add ../loop-stack-molt -b molt-cycle-1    # create sibling dir on a new branch
git worktree list                                       # what exists, which branch where
git worktree remove ../loop-stack-molt                  # done (add --force if it has dirty files)
git worktree prune                                      # clean stale bookkeeping
```

Placement: always a SIBLING directory (`../<repo>-<slug>`), never inside the repo.
Three reasons: recursive tools (tests, install.sh globs, import sweep) would see duplicate files in a nested one; `git clean -fdx` in the parent deletes ignored directories and can vaporize a nested worktree's uncommitted work; nested checkouts invite editing the wrong copy.

Who spawns worktrees, by substrate:

| Substrate            | Who creates them                       | Your job                        |
|----------------------|----------------------------------------|---------------------------------|
| Ringer               | Ringer, one per task, auto-reaped      | Nothing; patch-export out (P9)  |
| Native Agent tool    | The harness (worktree isolation mode)  | Nothing; auto-cleaned           |
| Human-paced streams  | You, `git worktree add`                | Create, merge at gates, remove  |

So "10 agents = 10 worktrees" is true, but they are the substrate's worktrees, not your directories.
Hand-made siblings are only for human-paced streams, and P13 caps those: each stream is a review sitting, so 1-3 at a time is the honest maximum.

## 4. The merge gate ritual

Work happens in the worktree; nothing goes live until this, run from the MAIN checkout:

```sh
cd ~/create/loops/loop-stack-session
git merge molt-cycle-1        # bring the worktree branch's commits in
./install.sh                  # refresh symlinks and the managed CLAUDE.md block
tests/run.sh                  # the executed check; green or it does not ship
```

If the merge reports conflicts: in loop-stack that is a SCOPE VIOLATION signal (P9), not a puzzle to quietly solve.
Two streams touched the same file; stop, decide ownership, redo the losing change - do not hand-blend conflict markers.
To back out of a conflicted merge cleanly: `git merge --abort`.

## 5. Recovery playbook

**5.1 Push rejected: `! [rejected] main -> main (non-fast-forward)`.**
Meaning: the remote has commits you do not have locally.
Fix: `git pull --rebase origin main` (replays your commits on top of theirs), then `git push`.
Never `push --force` to main; force-push is an irreversible-class action.

**5.2 Edited files on main that belong in the worktree.**
`git stash` (parks the edits), `cd` to the worktree, `git stash pop` (unparks them there).
Stash and pop travel across worktrees because the stash lives in the shared store.

**5.3 Committed on the wrong branch.**
`git log --oneline -1` to note the commit hash, then on the RIGHT branch `git cherry-pick <hash>`, then back on the wrong branch `git reset --hard HEAD~1` to drop it there.

**5.4 Undo the last commit but keep the work.**
`git reset --soft HEAD~1` - commit gone, files still staged; re-commit properly.

**5.5 "Detached HEAD" after checking out a tag.**
Not broken - you are visiting a snapshot with no branch attached.
Look around freely; to KEEP work from there, `git switch -c rescue-branch`; to leave, `git switch main`.

**5.6 Genuinely lost? The safety net.**
`git reflog` lists every state HEAD has pointed at for ~90 days, including "lost" commits after a bad reset.
Find the good hash, then `git reset --hard <hash>` or `git cherry-pick <hash>`.
Almost nothing committed is ever truly gone.

## 6. House rules (git meets the loop principles)

- Git over state files: recovery trusts `git log` and `git status` before any run-state artifact (P11).
- Relaunch, never resume: a half-done unit after a crash is redone from its last commit, not continued mid-flight (P11).
- Commit before anything risky; commits are the checkpoints quota death cannot take from you.
- One worktree per concurrent stream, disjoint file ownership by construction (P9).
- Merge conflict at a gate = scope violation, stop and re-decide ownership (P9).
- Tags before big cycles (`v1-pre-molt` pattern); cheap insurance, zero cost to leave behind.
- Irreversible actions (force-push, tag deletion on remote, history rewrite) are Jeremy's trigger to pull, staged never fired by an agent.

## 7. Quick reference

| I want to...                       | Command                                              |
|------------------------------------|------------------------------------------------------|
| Mark a return point                | `git tag -a <name> -m "<why>"`                       |
| See what changed since a point     | `git diff <tag> --stat`                              |
| Start an isolated workstream       | `git worktree add ../<repo>-<slug> -b <branch>`      |
| See my worktrees                   | `git worktree list`                                  |
| Bring finished work live           | `git merge <branch> && ./install.sh && tests/run.sh` |
| Park edits and move them           | `git stash` ... `git stash pop`                      |
| Undo last commit, keep work        | `git reset --soft HEAD~1`                            |
| Abandon everything since a point   | `git reset --hard <tag>` (diff first)                |
| Fix rejected push                  | `git pull --rebase origin main` then `git push`      |
| Find "lost" work                   | `git reflog`                                         |
| Retire a finished worktree         | `git worktree remove ../<repo>-<slug>`               |
