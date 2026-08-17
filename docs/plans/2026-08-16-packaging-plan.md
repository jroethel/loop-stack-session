# Loop-stack Multi-host Packaging Implementation Plan

> For executors: tasks use checkbox syntax; execute in dependency order; a task is done when its acceptance check passes.
> No specific tooling, harness, or skills are assumed - "the installer" is `install.sh`, "the mixed-provider tool" is the repo Ringer at `LOOP_STACK_RINGER_ROOT`, "the tracker CLI" is `scripts/tracker.sh`.

**Goal:** The loop-stack installs cleanly, non-interactively, and identically on any of the owner's machines, with every host-specific value held in one declared parameter home instead of hardcoded.
**Approach:** Parameterize in place and prove bottom-up: one declared host-config surface (`config/host.env`, sourced by the installer with env override) owns every host-specific value; the installer consumes it with defaults reproducing today's conventions; the non-interactive skill-style guard lands in the same pass; proof order is a dotfile-free clean room first, then the second live host.
**Tech stack:** Plain `bash` (installer, harness), `sed` render, `git grep` sweep, the repo's existing `tests/*/*.sh` auto-discovery runner, Markdown docs.
**Source brief:** `docs/briefs/2026-08-16-packaging-brief.md`

## Global constraints

- No em-dash characters anywhere; plain `-` only. One full sentence per physical line in prose.
- Do not change skill content or loop behavior; this pass touches only install machinery, config surface, tests, and docs, so a clean-room or host-2 red attributes to packaging alone.
- Never commit `config/host.env` (it is gitignored by Task 1); never commit the z.ai token; the installer never writes secrets.
- Preserve the installer's never-clobber-live-config behavior: an existing `~/.config/ringer/config.toml` is kept, never overwritten.
- The installer stays entirely `$HOME`-scoped and makes no network calls (verified: only `command -v`, file ops, and `git rev-parse`), which is what lets the degraded probe run offline.
- Installer skill symlinks embed the repo's absolute path; the parameter home holds no symlink paths, so the only cross-host interaction is "re-run `./install.sh` after moving the repo," which the README already documents. No new machinery is added for this.
- Host-specific literals swept for are `/Users/jjrdar`, `/home/jjrdar`, and the tilde convention form `~/repos/ringer` (the brief's criterion-5 wording); the absolute Ringer engine-bin literals live under the home prefixes, so the sweep covers them. Portable CODE forms (`$HOME/...`) are not matched. Every legitimate home for the tilde convention (installer, README, skill prose, diagrams, the parameter home) is named in the sweep's explicit allowlist.
- Test code in this plan is verbatim (the tests are the spec's teeth). Implementation code is verbatim only where the exact code is the decision (the style-resolution guard, the render substitution, the version check); everything else is specified as a contract.

## Dependency graph

```
Task 1  config surface + hardcode sweep + gitlab-comment genericize
   |    (produces config/host.env.template, config/ringer/config.toml.template, .gitignore entry, the sweep check)
   v
Task 2  install.sh consumes host.env, renders config.toml, enforces the #30 style guard
   |    (consumes Task 1's config surface)
   v
Task 3  clean-room harness: dotfile-free install + full suite + #30 refusal + no-network degraded probe
   |    (consumes the parameterized installer; proves criteria 1-4)
   v
Task 4  README multi-host section + file-map rows + parameter-home doc update
   |    (written only once the clean-room proof passes)
   v
Human checkpoints  host-2 rollout (crit 6), one real loop (crit 7), close #16 (crit 8)
```

This chain is strictly linear, not a parallel wave set, and that is correct: each task's acceptance consumes the artifact the prior task produced (the config surface gates consumption, consumption gates the clean-room proof, the proof gates the documentation that describes it).
Two parallel tasks would have to share `install.sh` or the config surface, which the exclusive-ownership rule forbids.
This is a recorded deviation from a wave-parallel shape: the brief's four seams are genuinely sequential dependencies, so they map one-to-one onto four gated tasks.

## Human checkpoints

Every judgment criterion and every action that touches a real second machine or the live tracker lands here, never as an automated task step.

- **H2 - Host-2 rollout (criterion 6, executed on the WSL host by the owner).**
  On the second host, edit `config/host.env` (created by the first install) so `LOOP_STACK_RINGER_ROOT="$HOME/repos/ringer"` resolves correctly there and set `LOOP_STACK_SKILL_STYLE` to the chosen style, then run:
  ```sh
  cd <loop-stack checkout on host 2>
  git pull
  LOOP_STACK_SKILL_STYLE=<agents|claude> ./install.sh
  tests/run.sh
  ```
  Stale-config recovery: host 2 likely already has a `~/.config/ringer/config.toml` copied verbatim by the old installer, holding `/Users/...` engine bins that are wrong on WSL.
  The installer never clobbers it, but its doctor now WARNS that those bin paths do not exist here.
  If that WARNING fires, run `mv ~/.config/ringer/config.toml ~/.config/ringer/config.toml.pre-render.bak && LOOP_STACK_SKILL_STYLE=<agents|claude> ./install.sh` to render a fresh host-correct config.
  Success: the suite ends "0 failed" with every host-specific value supplied only through `config/host.env`.
  This is the owner's to fire because the WSL host runs live projects and is not an experiment surface.

- **H3 - One real loop on host 2 (criterion 7, judgment).**
  Drive one real loop on the second host to a landed unit with tracker receipts.
  The loop's own checks are executed, but "a real loop on real work" is a judgment call and is never a task acceptance.

- **H4 - Close backlog #16 on ship (criterion 8, touches the live tracker).**
  When this work ships, run `scripts/tracker.sh close 16` with a closing note referencing the new multi-host README section (backlog #16 "multi-host support" is absorbed by this brief).
  `close` is human-only by the tracker's own contract; stage it, the owner fires it.

## How to run

```sh
# after Task 1
bash tests/hardcodes/sweep.sh                 # zero host literals outside the explicit allowlist

# after Task 2
bash tests/install/acceptance.sh              # #30 guard both directions + config.toml render + never-clobber
tests/run.sh                                  # full suite still green

# after Task 3
bash scripts/clean-room.sh                    # dotfile-free install + suite + #30 refusal + degraded probe

# after Task 4
tests/run.sh                                  # suite green with the new README section
grep -n 'Multi-host' README.md                # the mechanism section exists
```

---

### Task 1: Config surface, hardcode sweep, and the gitlab-comment genericize

Depends on: none

**Files (exclusive ownership):**
- Create: `config/host.env.template`
- Rename + Modify: `config/ringer/config.toml` -> `config/ringer/config.toml.template`
- Modify: `.gitignore`
- Modify: `tests/loop-setup/gitlab-setup.sh` (the illustrative comment on line 157 only)
- Modify: `install.sh` (ONE line in the ringer-config copy loop: skip the template so the rename does not leave a broken installer; Task 2 owns every other install.sh change)
- Test: `tests/hardcodes/sweep.sh` (create)

Recorded reason for one task, not two: the sweep check's acceptance (zero host literals outside the allowlist) cannot pass until `config.toml` is templated and the gitlab comment is genericized, so the config surface, the two literal removals, and the check that proves them are one atomic unit.
Recorded reason install.sh is touched here too (a linear-only shared owner, safe because Task 2 depends on Task 1): renaming `config.toml` -> `.template` without teaching the copy loop to skip it would make this task's commit install a literal `config.toml.template` into `~/.config/ringer`, so the one-line skip lands with the rename to keep every commit shippable.

**Interfaces:**
- Produces: three parameter keys read by later tasks - `LOOP_STACK_RINGER_ROOT` (default `"$HOME/repos/ringer"`), `LOOP_STACK_RINGER_VERSION` (floating reference), `LOOP_STACK_SKILL_STYLE` (`agents|claude`, shipped blank on purpose).
- Produces: `config/ringer/config.toml.template` with placeholders `__RINGER_CONFIG_DIR__` (claude-zai bin line) and `__RINGER_ROOT__` (opencode bin line).
- Consumes: nothing.

**`config/host.env.template` - exact content (this file IS the config surface, so its content is the decision):**
```sh
# config/host.env.template - the parameter home for this host's specific values.
# install.sh copies this to config/host.env (gitignored) on first run, then sources it.
# Environment variables OVERRIDE anything set here (env wins).

# Where the mixed-provider tool (ringer) is checked out on this host.
LOOP_STACK_RINGER_ROOT="$HOME/repos/ringer"

# Optional known-good ringer reference (a commit or tag). Left EMPTY by default so a healthy
# checkout never warns; set a specific commit/tag to opt into the doctor's non-fatal drift WARNING.
LOOP_STACK_RINGER_VERSION=""

# Skill install style: agents | claude. LEFT BLANK ON PURPOSE - it must be an explicit choice.
# A non-interactive run with this unset AND no env value REFUSES rather than silently defaulting.
# LOOP_STACK_SKILL_STYLE=
```

**`config/ringer/config.toml.template` edits (only the two `bin =` lines and the header comment change):**
- The line currently `bin = "/Users/jjrdar/.config/ringer/claude-zai.sh"` (claude-zai engine) becomes `bin = "__RINGER_CONFIG_DIR__/claude-zai.sh"`.
- The line currently `bin = "/Users/jjrdar/repos/ringer/engines/opencode-sandboxed.sh"` (opencode engine) becomes `bin = "__RINGER_ROOT__/engines/opencode-sandboxed.sh"`.
- The header comment (`# Copy to ~/.config/ringer/config.toml ...`) gains a note that this is a template rendered by `install.sh`, which substitutes the two placeholders.
- No other line changes; `state_dir`, `jsonl_path`, and artifact paths use `~/.ringer` and are not host-specific beyond `$HOME`.

**`.gitignore` edit:** append the line `config/host.env`.

**`tests/loop-setup/gitlab-setup.sh` edit (line 157 comment only):** replace the literal `/home/jjrdar/claude/forge` with a neutral illustrative placeholder `~/claude/forge`; the comment stays illustrative and the test's scenario-E logic (which keys on the git remote URL, not the comment) is untouched.

**`tests/hardcodes/sweep.sh` - verbatim:**
```bash
#!/usr/bin/env bash
# sweep.sh - host-specific literals may live ONLY in the parameter home and historical records.
# Greps the tracked + untracked (non-ignored) tree; PASSES iff every hit is under an allowlisted prefix.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"   # tests/hardcodes/ -> repo root (TWO levels up)

# Host-specific literals: this owner's absolute home paths on either OS, plus the ringer-root
# convention literal named in the brief's criterion 5. The absolute ringer engine-bin literals
# live under the home prefixes, so they are covered too. Portable CODE forms ("$HOME/...") are NOT
# matched - they resolve per host and are not hardcodes.
PATTERN='/Users/jjrdar|/home/jjrdar|~/repos/ringer'

# EXPLICIT allowlist of path prefixes where these literals are legitimately kept.
# The living-doc prefixes (docs/plans|briefs|memos and the root record files) are allowed BY DESIGN
# as historical-record paths: a literal newly authored into one of them is NOT caught. This is a
# deliberate limitation - narrow these to dated-file globs later if that ever becomes a real path.
ALLOW=(
  tests/hardcodes/                     # this sweep names the literals it hunts, so it matches itself
  config/host.env                      # the parameter home (gitignored)
  config/host.env.template             # ships the ~/repos/ringer convention default
  install.sh                           # the installer's portable fallback + doctor strings
  README.md                            # documents the ~/repos/ringer default
  skills/                              # skill prose references the runtime ringer convention
  diagrams/                            # conversation-evolution diagrams narrate the historical ~/repos/ringer explore
  docs/archive/
  docs/handoffs/
  docs/reviews/
  docs/briefs/
  docs/plans/
  docs/memos/
  docs/molt-ledger.md
  conversation-archive.md
  fixing-agent-errors.md
  model-routing-ringer-notes.local.md
  model-routing-ringer-notes.remote.md
  PLAN.md
)
allowed() {
  local f="$1" p
  for p in "${ALLOW[@]}"; do
    case "$f" in "$p"*) return 0 ;; esac
  done
  return 1
}

cd "$REPO"
# A check that cannot tell "no hits" from "grep never ran" is a false-green generator: require a work tree.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || { echo "FAIL: not a git work tree - sweep cannot run" >&2; exit 1; }
bad=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  allowed "$f" || { echo "HARDCODE outside allowlist: $f"; bad=$((bad + 1)); }
done < <(git grep --untracked -lE "$PATTERN" -- . 2>/dev/null)

if [ "$bad" -gt 0 ]; then
  echo "FAIL: $bad file(s) hold host-specific literals outside the parameter home / historical records"
  exit 1
fi
echo "PASS: no host-specific literals outside the allowlist"
```

**install.sh copy-loop skip (the only install.sh change in this task):** in the ringer-config copy loop (current lines 92-104), immediately after the `[ -e "$src" ] || continue` guard, insert `[ "$(basename "$src")" = config.toml.template ] && continue`, so the renamed template is not copied verbatim into `~/.config/ringer`. Task 2's Edit C later replaces this whole loop and re-includes the skip, so there is no conflict.

**Acceptance check:** `bash tests/hardcodes/sweep.sh && test -f config/ringer/config.toml.template && ! test -f config/ringer/config.toml && test -f config/host.env.template && grep -q '__RINGER_ROOT__' config/ringer/config.toml.template && grep -q '__RINGER_CONFIG_DIR__' config/ringer/config.toml.template && grep -qx 'config/host.env' .gitignore && tests/run.sh` exits 0 `[executed-check]`

- [ ] Step 1: `git mv config/ringer/config.toml config/ringer/config.toml.template`.
- [ ] Step 2: Edit the two `bin =` lines to the placeholders above and update the header comment.
- [ ] Step 3: Create `config/host.env.template` with the exact content above.
- [ ] Step 4: Append `config/host.env` to `.gitignore`.
- [ ] Step 5: Genericize the `tests/loop-setup/gitlab-setup.sh:157` comment (remove `/home/jjrdar`, use `~/claude/forge`).
- [ ] Step 6: Insert the one-line copy-loop skip into `install.sh` as specified just above.
- [ ] Step 7: Create `tests/hardcodes/sweep.sh` verbatim; `chmod +x tests/hardcodes/sweep.sh`.
- [ ] Step 8: Run the acceptance check; expect exit 0 (`tests/run.sh` ends "0 failed"). Confirm `git status` does not stage `config/host.env`.
- [ ] Step 9: `git add -A && git commit -m "param home: host.env template, config.toml template, hardcode sweep"`.

---

### Task 2: Installer consumes the parameter home, renders config.toml, and enforces the style guard

Depends on: Task 1

**Files (exclusive ownership):**
- Modify: `install.sh`
- Test: `tests/install/acceptance.sh` (create)

**Interfaces:**
- Consumes: `config/host.env.template`, `config/ringer/config.toml.template`, and the three parameter keys from Task 1.
- Produces: a `config/host.env` on first run (copied from the template), a rendered `~/.config/ringer/config.toml`, and a non-zero exit when the skill style is undeclared with no TTY.

**Edit A - parameter-home sourcing block (insert near the top of `install.sh`, after the directory definitions around line 12, before the skill-style resolution). Verbatim, because env-over-file ordering is the decision:**
```bash
# 0. parameter home: the one file holding this host's specific values. Env OVERRIDES file.
HOST_ENV="$REPO/config/host.env"
HOST_ENV_TEMPLATE="$REPO/config/host.env.template"
if [ ! -f "$HOST_ENV" ]; then
  cp "$HOST_ENV_TEMPLATE" "$HOST_ENV"
  echo "created $HOST_ENV from template - edit it for this host"
fi
# Capture any env-provided values first so they win over the file's.
_env_style="${LOOP_STACK_SKILL_STYLE:-}"
_env_root="${LOOP_STACK_RINGER_ROOT:-}"
_env_ver="${LOOP_STACK_RINGER_VERSION:-}"
# Source the hand-edited file with nounset OFF, so an operator typo yields a clear message rather
# than a cryptic "unbound variable" abort of the whole installer (host.env is the one file the
# operator hand-edits per host, so it is the likeliest place a human error lands).
set +u
# shellcheck source=/dev/null
. "$HOST_ENV" || { echo "ERROR: could not read $HOST_ENV - check its syntax" >&2; exit 1; }
set -u
[ -n "$_env_style" ] && LOOP_STACK_SKILL_STYLE="$_env_style"
[ -n "$_env_root" ]  && LOOP_STACK_RINGER_ROOT="$_env_root"
[ -n "$_env_ver" ]   && LOOP_STACK_RINGER_VERSION="$_env_ver"
RINGER_ROOT="${LOOP_STACK_RINGER_ROOT:-$HOME/repos/ringer}"
RINGER_VERSION="${LOOP_STACK_RINGER_VERSION:-}"
# Drift note: a write-once host.env can lag a template that a git pull later updated. For each key
# the template declares (active or commented), note when host.env lacks it entirely (non-fatal).
for _k in LOOP_STACK_RINGER_ROOT LOOP_STACK_RINGER_VERSION LOOP_STACK_SKILL_STYLE; do
  grep -qE "^#? *$_k=" "$HOST_ENV" || echo "note: config/host.env lacks '$_k' from the template (using built-in default)"
done
```

**Edit B - replace the entire existing style-resolution block (from `STYLE="${LOOP_STACK_SKILL_STYLE:-}"` through the trailing `echo "skill style: $STYLE"`, currently lines 24-33) with the #30 guard below; do not leave a duplicate echo. Verbatim, because the resolution order and the refusal ARE the fix:**
```bash
# skill style resolution: env > host.env > (TTY) prompt > REFUSE. Never a silent default.
STYLE="${LOOP_STACK_SKILL_STYLE:-}"
if [ -z "$STYLE" ]; then
  if [ -t 0 ]; then
    read -r -p "Skill install style - [a]gents (~/.agents/skills + harness symlinks) or [c]laude (direct into ~/.claude/skills)? [a] " STYLE
    STYLE="${STYLE:-a}"   # a human saw the prompt: empty enter may default
  else
    echo "ERROR: skill install style undeclared and no TTY to ask." >&2
    echo "Set LOOP_STACK_SKILL_STYLE=agents|claude (env or config/host.env) and re-run." >&2
    exit 1
  fi
fi
case "$STYLE" in
  a|agents) STYLE=agents ;;
  c|claude) STYLE=claude ;;
  *) echo "unknown style '$STYLE' (use agents or claude)" >&2; exit 1 ;;
esac
echo "skill style: $STYLE"
```
The load-bearing change from today: the `a` default now lives only inside the TTY branch, and the non-TTY undeclared path exits 1 instead of falling through to `agents`. Reading a value the owner wrote in `host.env` is not a silent default; the guard fires only when nothing declares the style and there is no TTY.

**Edit C - replace the ringer-config copy loop (current lines 92-104) so it skips the template and renders it separately. Verbatim, because the sed substitution IS the render decision:**
```bash
# 2. ringer config: copy each file only if absent (never clobber a live config). chmod +x wrappers.
#    config.toml is RENDERED from its template with host paths substituted, not copied.
mkdir -p "$RINGER_DIR"
for src in "$REPO"/config/ringer/*; do
  [ -e "$src" ] || continue
  base="$(basename "$src")"
  [ "$base" = config.toml.template ] && continue   # rendered separately, below
  dest="$RINGER_DIR/$base"
  if [ -e "$dest" ]; then
    echo "keeping existing $dest"
  else
    cp "$src" "$dest"
    echo "installed $dest"
  fi
  case "$dest" in *.sh) chmod +x "$dest" ;; esac
done
# render config.toml from template ONLY if absent (preserve the never-clobber-live-config behavior).
if [ -e "$RINGER_DIR/config.toml" ]; then
  echo "keeping existing $RINGER_DIR/config.toml"
  # A config.toml kept from a prior install or another host may not reflect this host's RINGER_ROOT;
  # editing config/host.env does NOT re-render an existing file. Warn, never clobber.
  if grep -q '^bin = ' "$RINGER_DIR/config.toml" \
     && ! grep -qF "$RINGER_ROOT/engines/opencode-sandboxed.sh" "$RINGER_DIR/config.toml"; then
    echo "WARNING: existing $RINGER_DIR/config.toml does not reference RINGER_ROOT=$RINGER_ROOT -"
    echo "         delete it and re-run ./install.sh to re-render for this host."
  fi
else
  # The renderer substitutes with sed; reject paths carrying sed metacharacters (| the delimiter,
  # & the match-reference, \ the escape) rather than silently emitting a corrupt config.
  case "$RINGER_ROOT$RINGER_DIR" in
    *'|'*|*'&'*|*'\'*) echo "ERROR: ringer paths contain a character unsupported by the renderer (| & \\)" >&2; exit 1 ;;
  esac
  sed -e "s|__RINGER_ROOT__|$RINGER_ROOT|g" \
      -e "s|__RINGER_CONFIG_DIR__|$RINGER_DIR|g" \
      "$REPO/config/ringer/config.toml.template" > "$RINGER_DIR/config.toml"
  echo "rendered $RINGER_DIR/config.toml from template (RINGER_ROOT=$RINGER_ROOT)"
fi
```

**Edit D - replace the ringer doctor block (current lines 143-145) with the root + floating-version check. Verbatim, because the version-match rule is the resolved decision:**
```bash
# ringer presence + floating-version reference check (both non-fatal, never abort).
if [ -d "$RINGER_ROOT" ]; then
  echo "found ringer: $RINGER_ROOT"
  if [ -n "$RINGER_VERSION" ] && git -C "$RINGER_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    have="$(git -C "$RINGER_ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"
    want="$(git -C "$RINGER_ROOT" rev-parse --short "$RINGER_VERSION" 2>/dev/null || echo "$RINGER_VERSION")"
    [ "$have" = "$want" ] || echo "WARNING: ringer HEAD $have != reference $RINGER_VERSION (floating reference; not fatal)"
  fi
else
  echo "WARNING: $RINGER_ROOT not found - config.toml engine paths point there"
fi

# Stale-config guard: a config.toml kept from a prior install or another host may point its engine
# bins at absolute paths that do not exist here (the exact defect on a second host that still holds
# the old installer's /Users/... bins). Verify only absolute-path bins; bare command names resolve
# via PATH and are skipped. WARN, never abort. No host literals, so the hardcode sweep stays clean.
if [ -f "$RINGER_DIR/config.toml" ]; then
  while IFS= read -r binpath; do
    case "$binpath" in
      /*) [ -e "$binpath" ] || echo "WARNING: config.toml engine bin '$binpath' not found here - delete $RINGER_DIR/config.toml and re-run to re-render" ;;
    esac
  done < <(sed -nE 's/^bin = "([^"]*)".*/\1/p' "$RINGER_DIR/config.toml")
fi
```
The `rev-parse --git-dir` guard honors "only if that dir is a git repo"; resolving the reference through `rev-parse --short` lets a tag or branch reference compare cleanly against the short HEAD, and an unresolvable reference simply warns.

**`tests/install/acceptance.sh` - verbatim:**
```bash
#!/usr/bin/env bash
# install acceptance: the #30 style guard (both directions), the config.toml render, and never-clobber.
# Runs the working-tree install.sh against throwaway HOME + REPO copies; the real HOME is never touched.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
# Control the environment: an inherited LOOP_STACK_* export would leak into the refusal case (turning
# a passing guard into a spurious failure) and into the render/never-clobber runs. Unset all three;
# each case passes the values it needs as per-command prefixes.
unset LOOP_STACK_SKILL_STYLE LOOP_STACK_RINGER_ROOT LOOP_STACK_RINGER_VERSION
LOG=""
fail() {
  [ -n "$LOG" ] && [ -f "$LOG" ] && { echo "--- last install log ($LOG) ---" >&2; cat "$LOG" >&2; }
  echo "FAIL: $1" >&2; exit 1
}

# isolated REPO copy without .git or any gitignored host.env (so nothing pre-declares the style)
mkrepo() {
  local d; d="$(mktemp -d)"
  ( cd "$REPO" && tar --exclude=.git -cf - . ) | ( cd "$d" && tar -xf - )
  rm -f "$d/config/host.env"
  printf '%s' "$d"
}

# --- criterion 1: style set, non-interactive, dotfile-free HOME -> exit 0, skills symlinked ---
H1="$(mktemp -d)"; R1="$(mkrepo)"; trap 'rm -rf "$H1" "$R1"' EXIT
LOG="$H1/install.log"
HOME="$H1" LOOP_STACK_SKILL_STYLE=agents bash "$R1/install.sh" </dev/null > "$LOG" 2>&1 \
  || fail "install with style=agents did not exit 0"
[ -L "$H1/.claude/skills/loop-drive" ] || fail "agents-style install did not symlink loop-drive"

# --- criterion 2 / #30: style unset in BOTH env and host.env, no TTY -> REFUSE nonzero, install nothing ---
H2="$(mktemp -d)"; R2="$(mkrepo)"; trap 'rm -rf "$H1" "$R1" "$H2" "$R2"' EXIT
LOG="$H2/install.log"
if HOME="$H2" bash "$R2/install.sh" </dev/null > "$LOG" 2>&1; then
  fail "no-style non-interactive run exited 0 (silently defaulted instead of refusing)"
fi
[ -e "$H2/.claude/skills/loop-drive" ] && fail "the refused run still installed skills"

# --- decision 4: config.toml rendered from template, placeholders substituted, template not copied ---
H3="$(mktemp -d)"; R3="$(mkrepo)"; trap 'rm -rf "$H1" "$R1" "$H2" "$R2" "$H3" "$R3"' EXIT
LOG="$H3/install.log"
HOME="$H3" LOOP_STACK_SKILL_STYLE=agents LOOP_STACK_RINGER_ROOT=/opt/ringer-xyz \
  bash "$R3/install.sh" </dev/null > "$LOG" 2>&1 || fail "render install did not exit 0"
cfg="$H3/.config/ringer/config.toml"
[ -f "$cfg" ] || fail "config.toml was not rendered"
grep -q '__RINGER_ROOT__\|__RINGER_CONFIG_DIR__' "$cfg" && fail "placeholders left unsubstituted in rendered config.toml"
grep -q '/opt/ringer-xyz/engines/opencode-sandboxed.sh' "$cfg" || fail "RINGER_ROOT not substituted into the opencode bin"
grep -q "$H3/.config/ringer/claude-zai.sh" "$cfg" || fail "RINGER_CONFIG_DIR not substituted into the claude-zai bin"
[ -e "$H3/.config/ringer/config.toml.template" ] && fail "the template file was copied literally into ~/.config/ringer"

# --- decision 4: never clobber a live config.toml ---
H4="$(mktemp -d)"; R4="$(mkrepo)"; trap 'rm -rf "$H1" "$R1" "$H2" "$R2" "$H3" "$R3" "$H4" "$R4"' EXIT
LOG="$H4/install.log"
mkdir -p "$H4/.config/ringer"; printf 'SENTINEL-LIVE-CONFIG\n' > "$H4/.config/ringer/config.toml"
HOME="$H4" LOOP_STACK_SKILL_STYLE=agents bash "$R4/install.sh" </dev/null > "$LOG" 2>&1 \
  || fail "install over an existing config.toml did not exit 0"
grep -q 'SENTINEL-LIVE-CONFIG' "$H4/.config/ringer/config.toml" || fail "install clobbered a live config.toml"

echo "PASS: install style guard + config.toml render + never-clobber"
```

**Acceptance check:** `bash tests/install/acceptance.sh && tests/run.sh` exits 0 `[executed-check]`

- [ ] Step 1: Apply Edit A (parameter-home sourcing).
- [ ] Step 2: Apply Edit B (the #30 style guard, replacing the current resolution).
- [ ] Step 3: Apply Edit C (skip the template in the copy loop, render it separately).
- [ ] Step 4: Apply Edit D (ringer root + floating-version doctor check).
- [ ] Step 5: Create `tests/install/acceptance.sh` verbatim; `chmod +x tests/install/acceptance.sh`.
- [ ] Step 6: Run the acceptance check; expect exit 0 and `tests/run.sh` ending "0 failed".
- [ ] Step 7: `git add -A && git commit -m "install.sh: consume host.env, render config.toml, enforce style guard"`.

---

### Task 3: Clean-room proof harness

Depends on: Task 2

**Files (exclusive ownership):**
- Test: `scripts/clean-room.sh` (create)

Recorded note: this harness is a standalone script under `scripts/`, not under `tests/`, on purpose - it clones and runs the whole suite, so auto-discovery by `tests/run.sh` would nest a suite inside itself.

Run amendment (2026-08-16, orchestrator, BATCH-journaled): `tests/repo-state/live.sh` gained a sandbox guard (SKIP with exit 0 when the checkout's origin is not a GitHub remote).
Without it this harness is unsatisfiable: the clean-room clone's origin is a local path with no gh auth and proof 3 is offline, while `live.sh` hard-gates on mirrors plus a live `gh issue list`.
The guard never fires on the primary checkout, so the live-state gate there is unchanged.

**Interfaces:**
- Consumes: the committed tree after Task 2 (it clones `HEAD`, so run it only after Tasks 1-2 are committed).
- Produces: a single pass/fail proof covering criteria 1, 2, 3, and 4.

**`scripts/clean-room.sh` - verbatim:**
```bash
#!/usr/bin/env bash
# clean-room.sh - prove loop-stack installs and its suite passes in a dotfile-free sandbox,
# that the #30 guard refuses an undeclared style, and that a no-network degraded probe (ringer
# absent) still passes. Uses throwaway HOMEs; the real HOME is never touched.
# Run after Tasks 1-2 are committed (it clones HEAD).
set -uo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "CLEAN-ROOM FAIL: $1" >&2; exit 1; }
# An exported LOOP_STACK_* would leak into proof 2's refusal check; control the environment.
unset LOOP_STACK_SKILL_STYLE LOOP_STACK_RINGER_ROOT LOOP_STACK_RINGER_VERSION
# Seed a git identity into the current sandbox HOME so suites that commit do not depend on the
# host having a global git ident (auto-detection yields "user@host.(none)" and fails on some hosts).
seed_git() { git config --global user.email clean@room.invalid; git config --global user.name cleanroom; }

SANDBOX="$(mktemp -d)"; trap 'rm -rf "$SANDBOX"' EXIT
SRC="$SANDBOX/repo"
# A real local clone (committed HEAD only, no gitignored host.env), so the tree has a .git and
# the tracked-tree checks (the hardcode sweep) actually run instead of trivially passing.
git clone --quiet "$REPO" "$SRC" || fail "could not clone the repo into the sandbox"

# --- proof 1: non-interactive install with style set, then the full suite (criteria 1, 3) ---
export HOME="$SANDBOX/home"; mkdir -p "$HOME"; seed_git
LOOP_STACK_SKILL_STYLE=agents bash "$SRC/install.sh" </dev/null || fail "install.sh (style=agents) did not exit 0"
[ -L "$HOME/.claude/skills/loop-drive" ] || fail "install did not symlink skills"
bash "$SRC/tests/run.sh" || fail "tests/run.sh not green in the clean room"

# --- proof 2: the #30 guard - style undeclared, no TTY, must REFUSE (criterion 2) ---
rm -f "$SRC/config/host.env"   # ensure nothing declares the style
if bash "$SRC/install.sh" </dev/null >/dev/null 2>&1; then
  fail "install.sh defaulted the skill style with no TTY (the #30 guard did not fire)"
fi

# --- proof 3: no-network degraded probe, ringer absent (criterion 4) ---
export HOME="$SANDBOX/home2"; mkdir -p "$HOME"; seed_git
export LOOP_STACK_RINGER_ROOT="$SANDBOX/no-ringer-here"   # guaranteed absent
# Blackhole HTTP egress so any standard network call fails fast. The install/test path makes no
# network calls, so this proves the stack is offline-clean in degraded mode.
# ponytail: proxy-level guard only, not a kernel firewall; sufficient because the stack uses no raw sockets.
export http_proxy=http://127.0.0.1:1 https_proxy=http://127.0.0.1:1 all_proxy=http://127.0.0.1:1
LOOP_STACK_SKILL_STYLE=agents bash "$SRC/install.sh" </dev/null || fail "degraded install (ringer absent) did not exit 0"
bash "$SRC/tests/run.sh" || fail "degraded-mode suite not green (ringer absent)"

echo "CLEAN-ROOM PASS: install green, suite green, #30 guard fires, degraded probe green"
```

**Acceptance check:** `bash scripts/clean-room.sh` exits 0 and prints the `CLEAN-ROOM PASS` line `[executed-check]`

- [ ] Step 1: Create `scripts/clean-room.sh` verbatim; `chmod +x scripts/clean-room.sh`.
- [ ] Step 2: Run it; expect the `CLEAN-ROOM PASS` line and exit 0.
- [ ] Step 3: `git add -A && git commit -m "clean-room harness: dotfile-free install, suite, style-guard, degraded probe"`.

---

### Task 4: Multi-host documentation

Depends on: Task 3

**Files (exclusive ownership):**
- Modify: `README.md`

**Interfaces:**
- Consumes: the parameter surface from Task 1 and the proven install flow from Tasks 2-3 (documented, not re-implemented).
- Produces: a `## Multi-host` section and file-map rows that later phases and the second host read.

**Contract - the README gains a `## Multi-host` section that states:**
- Git push/pull is the supported reconciliation mechanism between the owner's hosts; each host installs via `git pull && ./install.sh && tests/run.sh`.
- Each host's specific values live only in `config/host.env` (gitignored), created from `config/host.env.template` on first install; env vars override the file.
- First run on a new host: `./install.sh` creates `config/host.env`; set `LOOP_STACK_SKILL_STYLE` there (or pass it on the command line) and re-run - a non-interactive first run with the style undeclared refuses by design rather than silently defaulting.
- Stale-config recovery: editing `config/host.env` does not re-render an existing `~/.config/ringer/config.toml`; if the installer's doctor WARNS that config.toml engine bins do not exist, delete that file and re-run to re-render for this host.
- Scoreboard posteriors stay host-local by design (routing numbers are not portable between hosts): git syncs the repo but never the evidence ledger, and each host re-earns its posteriors.
- This section supersedes backlog #16 ("multi-host support"), which closes when this work ships.

**Contract - the README file-map and ringer note are updated for the rename and the new surface:**
- Add rows for `config/ringer/config.toml.template` and `config/host.env.template`; adjust the existing `config/ringer/` map row wording so it no longer implies a plain `config.toml` is shipped.
- Update the two ringer notes that currently reference a shipped `config.toml` and `~/repos/ringer` (around README lines 77 and 131-132) to point at the parameter home (`LOOP_STACK_RINGER_ROOT`, default `~/repos/ringer`) and the rendered config.
- Do not alter the skills-selection table or any content that `tests/readme/selection.sh` asserts; keep the suite green.

**Acceptance check:** `tests/run.sh && grep -q '## Multi-host' README.md && grep -Eq 'git (push/pull|pull)' README.md && grep -qi 'host-local' README.md && grep -q 'config.toml.template' README.md && grep -qi 're-render' README.md` exits 0 `[executed-check]`

- [ ] Step 1: Add the `## Multi-host` section with the four statements above.
- [ ] Step 2: Update the file-map rows and the two ringer notes for the rename and parameter home.
- [ ] Step 3: Run the acceptance check; expect `tests/run.sh` "0 failed" and every grep matching.
- [ ] Step 4: `git add -A && git commit -m "docs: multi-host section, parameter-home README updates"`.

---

## Brief-criteria coverage map

| Criterion                                        | Where it lands                              |
|--------------------------------------------------|---------------------------------------------|
| 1 style-set install exits 0, no prompt           | Task 2 acceptance + Task 3 proof 1          |
| 2 no-style non-interactive REFUSES (#30 guard)   | Task 2 acceptance + Task 3 proof 2          |
| 3 tests/run.sh green in the clean room           | Task 3 proof 1                              |
| 4 no-network degraded probe, ringer absent       | Task 3 proof 3                              |
| 5 hardcode grep zero outside explicit allowlist  | Task 1 acceptance                           |
| 6 host 2 green via the parameter home only       | Human checkpoint H2                         |
| 7 one real loop on host 2 (judgment)             | Human checkpoint H3                         |
| 8 multi-host section exists; #16 closed for it   | Task 4 acceptance + Human checkpoint H4     |

Every executed-check criterion maps to a task acceptance; both judgment/live-machine/live-tracker items (6, 7, 8-close) map to human checkpoints. Plan accepted.
