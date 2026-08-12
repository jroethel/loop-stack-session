# Seam A: gitlab correctness Implementation Plan

> For executors: tasks use checkbox syntax; execute in dependency order; a task is done when its
> acceptance check passes. No specific tooling, harness, or skills are assumed.

**Goal:** Stop `/loop-setup` in gitlab mode from shipping GitHub-specific text, a hostless cross-repo query, a hint-less no-remote failure, and an ungitignored runtime file.
**Approach:** Fix all four defects in `skills/loop-setup/setup.sh` (three of them inside `render_gitlab`, one in the finalize) via the per-line-rewrite approach, mirroring the existing `render_github`/`render_local` drop-symmetry rather than introducing a `{{BACKEND}}` template token. Each fix gets its negative/positive assertion in `tests/loop-setup/gitlab-setup.sh` - the missing GitHub-absent assertions in scenario A are the exact shape of #19.
**Tech stack:** Bash, awk, POSIX grep; the repo's self-contained bash test suites.
**Source brief:** none - driven by `docs/handoffs/2026-08-12-gitlab-fallout-triage.md` and `docs/memos/2026-08-10-to-loop-stack.md` (findings 1, 4, 5a, 5b). Issues: #19, #25, #26, #27.

## Global constraints

- The fix for #19 is the **per-line rewrite inside `render_gitlab`**, decided this session. Do NOT introduce a `{{BACKEND}}` template token.
- `config/repo-state.template.md` is NOT edited. All four fixes live in `skills/loop-setup/setup.sh`. (The template already carries both the `gh` lines 38-39 and the `glab` lines 40-41; the renderers decide which survive.)
- Match the existing awk idiom in `render_github`/`render_local`: `index($0, "...") { next }` to drop a line.
- `#26`'s `GITLAB_HOST=` prefix goes only on the **cross-repo** glab line (template line 40, the `--group` one). The per-repo fallback (line 41, `glab issue list --label idea`) stays host-free - it is run from inside the repo where `glab` resolves the host from context.
- `#27`'s `.gitignore` append is mode-independent (chain-state exists in every mode) and idempotent.

## Dependency graph

Single task. All four fixes share `skills/loop-setup/setup.sh` and `tests/loop-setup/gitlab-setup.sh`, so no two can run in parallel (shared-file ownership). One task, one acceptance check.

## Human checkpoints

None. Every criterion here is an executed check. The one design fork (#19 per-line vs `{{BACKEND}}`) was resolved before planning.

## How to run

```
# the seam's own suite (primary acceptance check)
bash tests/loop-setup/gitlab-setup.sh        # prints "PASS: loop-setup gitlab mode", exits 0

# the full suite (regression guard)
bash tests/run.sh                            # prints "ran N suites: N passed, 0 failed", exits 0
```

---

### Task 1: gitlab-mode correctness fixes (#19, #25, #26, #27)

Depends on: none

**Files (exclusive ownership):**
- Modify: `skills/loop-setup/setup.sh` (`render_gitlab` at :203-220; its two callers at :257 and :391; the gitlab finalize at :419-437; the mkdir block at :122)
- Test: `tests/loop-setup/gitlab-setup.sh` (add assertions to scenario A; add scenario I)

**Interfaces:**
- `render_gitlab` gains a third positional parameter `host` (after `url`, `grp`). Both callers must pass it.
- `scripts/tracker.sh host` prints the GitLab host derived from `origin` (empty + non-zero when no origin). `scripts/tracker.sh group` prints the backlog group. Both already exist - do not modify `tracker.sh`.

**Acceptance check:** `bash tests/loop-setup/gitlab-setup.sh` exits 0, AND `bash tests/run.sh` exits 0 `[executed-check]`

---

#### Fix 1 - #19 + #26: rewrite `render_gitlab`

Replace the whole `render_gitlab` function (`setup.sh:203-220`) with this. The four changes over today's version: a `gsub(/GitHub/, "GitLab")` on the body (rewrites template lines 17, 18, 48); two drop rules for the `gh` backlog-view lines (template 38, 39) mirroring how `render_github` drops the glab lines; a third `host` parameter; and a `sub` that prefixes only the cross-repo glab `--group` line with `GITLAB_HOST=<host>` (#26), guarded so an empty host leaves the line untouched.

```bash
render_gitlab() {
  # Like render_github but substitutes the backlog group into the gitlab-only lines instead of
  # dropping them, and rewrites the GitHub-named lanes/source-of-truth text to GitLab (the template
  # is GitHub-first). Drops the two gh backlog-view lines the way render_github drops the glab ones.
  # Prefixes ONLY the cross-repo glab query with GITLAB_HOST (it is run from outside any repo, where
  # glab cannot resolve a host from context); the per-repo fallback stays host-free. Strips the Local
  # tracker section, drops the "Render it into" line, rewrites the dangling Local-tracker pointer.
  awk -v url="$1" -v grp="$2" -v host="$3" '
    BEGIN { skip = 0 }
    { gsub(/{{BACKLOG_GROUP}}/, grp); gsub(/GitHub/, "GitLab") }
    index($0, "Render it into") { next }
    index($0, "gh search issues") { next }
    index($0, "gh issue list") { next }
    index($0, "glab issue list --group") { if (host != "") sub(/glab issue list --group/, "GITLAB_HOST=" host " glab issue list --group") }
    index($0, "{{REMOTE_OR_FALLBACK}}") { print "Remote: " url; next }
    /^## Local tracker/ { skip = 1; next }
    /^## / { skip = 0 }
    index($0, "the Local tracker section governs local mode") {
      print "The tracker backend (github, gitlab, or local) is declared in the `tracker:` key below."
      next
    }
    { if (skip) next; print }
  ' "$TPL"
}
```

Edge notes (already handled above, do not re-add):
- `gsub(/GitHub/, "GitLab")` is safe: "GitHub" appears in the template only on lines 17, 18, 48, all of which must become GitLab in gitlab mode. The lowercase `(github, gitlab, or local)` sentence is untouched (different case), and the pointer-rewrite line prints a literal, so the gsub'd `$0` is discarded there.
- `index($0, "gh issue list")` does NOT match `glab issue list` (the substring is not contiguous: `...gl` + `ab issue list`).

**Update both callers to pass `host`:**

Caller at `setup.sh:391` (first setup, gitlab branch of the render case):
```bash
gitlab)  render_gitlab "$remote_url" "$(scripts/tracker.sh group 2>/dev/null || true)" "$(scripts/tracker.sh host 2>/dev/null || true)" > config/repo-state.md ;;
```

Caller in `reconcile_config`, gitlab branch (`setup.sh:252-257`) - resolve host alongside grp and pass it:
```bash
    gitlab)
      remote="$(grep -E '^Remote:' config/repo-state.md | head -1 | sed -E 's/^Remote:[[:space:]]*//')"
      if [ -z "$remote" ] || [ "${remote#none}" != "$remote" ]; then remote="$remote_url"; fi
      grp="$(grep -E '^backlog-group:' config/repo-state.md | head -1 | sed -E 's/^backlog-group:[[:space:]]*//')"
      [ -n "$grp" ] || grp="$(scripts/tracker.sh group 2>/dev/null || true)"
      host="$(scripts/tracker.sh host 2>/dev/null || true)"
      cand="$(render_gitlab "$remote" "$grp" "$host")"
      ;;
```
Add `host` to `reconcile_config`'s `local ... grp` declaration line (`setup.sh:241`) so it is a locally-scoped variable: change `local tv cv cand remote grp` to `local tv cv cand remote grp host`.

#### Fix 2 - #25: remote-creation hint before the gitlab fail-fast

In the gitlab finalize (`setup.sh:419-424`), replace the bare host resolve + fail:
```bash
      host="$(scripts/tracker.sh host 2>/dev/null || true)"
      [ -n "$host" ] || fail "tracker: gitlab requires an origin remote to resolve the GitLab host"
```
with a hint before the fail, mirroring the github branch's `:409` hint:
```bash
      host="$(scripts/tracker.sh host 2>/dev/null || true)"
      if [ -z "$host" ]; then
        echo "no remote - to create one: GITLAB_HOST=<host> glab repo create <name> --private --skipGitInit"
        echo "then: git remote add origin <url>"
        fail "tracker: gitlab requires an origin remote to resolve the GitLab host"
      fi
```
(`--skipGitInit` avoids the nested-empty-clone trap from the memo; the `git remote add` line covers `glab`'s failure to set `origin` on the outer repo.)

#### Fix 3 - #27: gitignore `docs/chain-state.md` in the target repo

Directly after the mkdir at `setup.sh:122` (`mkdir -p config docs/handoffs docs/reviews docs/archive`), add an idempotent, announced append. It bumps `offers` when it acts so the run never claims "nothing to do" on a run that mutated `.gitignore`:
```bash
if ! grep -qxF 'docs/chain-state.md' .gitignore 2>/dev/null; then
  echo 'docs/chain-state.md' >> .gitignore
  echo "added docs/chain-state.md to .gitignore"
  offers=$((offers + 1))
fi
```

---

#### Test assertions

**A. Extend scenario A** (the fresh gitlab repo `$A`, after its existing assertions at `gitlab-setup.sh:40-66`). Insert this block after line 66:

```bash
# #19: no GitHub source-of-truth text leaks into a gitlab render; the GitLab-correct text is present
grep -q '^GitHub is the single source of truth' "$A/config/repo-state.md" \
  && fail "gitlab render leaked 'GitHub is the single source of truth'"
grep -q 'GitHub (open' "$A/config/repo-state.md" \
  && fail "gitlab render leaked the GitHub Issues lane row"
grep -q 'GitHub (label' "$A/config/repo-state.md" \
  && fail "gitlab render leaked the GitHub Backlog lane row"
grep -q 'gh search issues' "$A/config/repo-state.md" \
  && fail "gitlab render leaked the gh cross-repo backlog view"
grep -q 'gh issue list --label idea --state open' "$A/config/repo-state.md" \
  && fail "gitlab render leaked the gh per-repo fallback"
grep -q '^GitLab is the single source of truth' "$A/config/repo-state.md" \
  || fail "gitlab render did not rewrite the source-of-truth line to GitLab"
grep -q 'GitLab (open' "$A/config/repo-state.md" \
  || fail "gitlab render did not rewrite the Issues lane row to GitLab"

# #26: the cross-repo glab backlog view carries an explicit GITLAB_HOST; the per-repo fallback does not
grep -q 'GITLAB_HOST=gitlab.code.rit.edu glab issue list --group university-advancement --label idea' "$A/config/repo-state.md" \
  || fail "gitlab render did not prefix the cross-repo glab query with GITLAB_HOST"
grep -q 'Per-repo fallback, gitlab: `glab issue list --label idea`' "$A/config/repo-state.md" \
  || fail "gitlab render altered or dropped the host-free per-repo glab fallback"

# #27: setup added docs/chain-state.md to the target repo's .gitignore, and does not duplicate it on re-run
grep -qxF 'docs/chain-state.md' "$A/.gitignore" \
  || fail "setup did not gitignore docs/chain-state.md"
( cd "$A" && LOOP_ASSUME_NO=1 "$SETUP" </dev/null >/dev/null 2>&1 ) \
  || fail "re-run of settled gitlab repo exited non-zero"
[ "$(grep -c '^docs/chain-state\.md$' "$A/.gitignore")" -eq 1 ] \
  || fail "re-running setup duplicated the chain-state gitignore line"
```

**B. Add scenario I** (gitlab mode, no remote, prints the hint before failing). Append before the final `echo "PASS: ..."` at `gitlab-setup.sh:225`:

```bash
# ---------- scenario I: gitlab mode with no remote prints a creation hint before failing (#25) ----------
I="$(mktemp -d)"; trap 'rm -rf "$BIN" "$A" "$B" "$C" "$C2" "$D" "$E" "$F" "$G" "$H1" "$H2" "$I"' EXIT
( cd "$I" && git init -q )   # no origin remote
out="$( cd "$I" && LOOP_TRACKER_ANSWER=gitlab "$SETUP" </dev/null 2>&1 )" \
  && fail "gitlab setup with no remote exited 0 (should fail-fast on the missing host)"
printf '%s\n' "$out" | grep -q 'glab repo create <name> --private --skipGitInit' \
  || fail "gitlab no-remote path did not print the repo-creation hint"
printf '%s\n' "$out" | grep -q 'git remote add origin' \
  || fail "gitlab no-remote hint did not include the git remote add follow-up"
```

- [ ] Step 1: Add the scenario-A assertion block and scenario I to `tests/loop-setup/gitlab-setup.sh` (verbatim above).
- [ ] Step 2: Run `bash tests/loop-setup/gitlab-setup.sh` - expect FAIL (leaked GitHub lines, missing `GITLAB_HOST`, no `.gitignore` line, no hint - the four bugs).
- [ ] Step 3: Apply Fix 1, Fix 2, Fix 3 to `skills/loop-setup/setup.sh` (verbatim above).
- [ ] Step 4: Run `bash tests/loop-setup/gitlab-setup.sh` - expect PASS (`PASS: loop-setup gitlab mode`). Then `bash tests/run.sh` - expect `0 failed`.
- [ ] Step 5: Commit:
```bash
git add skills/loop-setup/setup.sh tests/loop-setup/gitlab-setup.sh
git commit -m "loop-setup: fix gitlab render leak, hostless query, no-remote hint, chain-state gitignore (#19, #25, #26, #27)"
```
