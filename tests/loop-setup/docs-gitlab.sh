#!/usr/bin/env bash
# The docs no longer assert github-only behavior, the triage reference exists and is pointed at,
# and this repo's own config is at the current template-version.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }

SK="$REPO/skills/loop-setup/SKILL.md"
REF="$REPO/skills/loop-setup/references/import-triage.md"
WF="$REPO/skills/wayfinder/SKILL.md"
IMP="$REPO/skills/loop-improve/SKILL.md"
REV="$REPO/skills/loop-review/SKILL.md"
CFG="$REPO/config/repo-state.md"
TPL="$REPO/config/repo-state.template.md"

# criterion 11: wayfinder no longer states a github-only requirement
grep -q 'Wayfinder requires `tracker: github`' "$WF" \
  && fail "wayfinder still states a github-only tracker requirement (criterion 11)"
grep -qi 'gitlab' "$WF" || fail "wayfinder does not mention gitlab at all"
grep -q 'wayfinder:map' "$WF" || fail "wayfinder lost its map label name"

# the template's local-mode limitation matches
grep -q 'wayfinder requires `tracker: github`' "$TPL" \
  && fail "the template still states wayfinder is github-only"

# the SAME assertions against this repo's own config - it is the file agents actually read,
# and asserting only against the template would pass while the config stayed wrong
grep -q 'wayfinder requires `tracker: github`' "$CFG" \
  && fail "config/repo-state.md still states wayfinder is github-only"
grep -q 'Migration to GitHub' "$CFG" \
  && fail "config/repo-state.md still describes migration as GitHub-only"
grep -qi 'gitlab' "$CFG" || fail "config/repo-state.md never mentions gitlab"

# the second github-only assertion (the numbering limitation) is widened in both files
grep -q 'shared or branched work should use `tracker: github`' "$CFG" \
  && fail "config/repo-state.md still tells shared work to use github only"
grep -q 'shared or branched work should use `tracker: github`' "$TPL" \
  && fail "the template still tells shared work to use github only"

# the config round-trips the v2 template: the autonomy-default prose survives a render
grep -q 'autonomy-default' "$TPL" \
  || fail "the template lacks the autonomy-default paragraph (a v2 re-render would silently drop it from the config)"
grep -q 'autonomy-default' "$CFG" || fail "config/repo-state.md lost its autonomy-default paragraph"

# the sweep's root exclusions are declared where the config claims to be the definitive list
grep -q 'CONTRIBUTING.md' "$TPL" || fail "the template does not declare the sweep's root exclusions"
grep -q 'CONTRIBUTING.md' "$CFG" || fail "config/repo-state.md does not declare the sweep's root exclusions"

# loop-setup SKILL.md documents all three modes and points at the triage reference
for w in github gitlab local; do
  grep -q "$w" "$SK" || fail "loop-setup SKILL.md does not mention $w"
done
grep -q 'references/import-triage.md' "$SK" || fail "SKILL.md does not point at the triage reference"
grep -q 'LOOP_IMPORT_REMOTE' "$SK" \
  || fail "SKILL.md does not document the LOOP_IMPORT_REMOTE guard on unattended remote creation"
grep -q 'LOOP_TRACKER_ANSWER=gitlab' "$SK" || fail "SKILL.md does not document the gitlab non-interactive answer"
grep -qi 'but the remote is' "$SK" || fail "SKILL.md does not document the mode-switch offer"
grep -q 'migrate-tracker.sh --to' "$SK" \
  || fail "SKILL.md does not tell the agent when to suggest the standalone migration (criterion 10)"
grep -q 'tracker-remote-ack' "$SK" \
  || fail "SKILL.md does not document the tracker-remote-ack off switch for the mode-switch offer"
grep -qi 'declin' "$SK" \
  || fail "SKILL.md does not explain that declining the mechanical import routes a file to the triage prose"
[ -f "$REF" ] || fail "skills/loop-setup/references/import-triage.md missing"
grep -qi 'one actionable item' "$REF" || fail "the triage reference does not state the one-item-per-issue rule"
grep -qi 'split' "$REF" || fail "the triage reference does not cover splitting"
grep -qi 'merge' "$REF" || fail "the triage reference does not cover merging"

# the documented remote-report strings match what setup.sh actually prints
S="$REPO/skills/loop-setup/setup.sh"
for s in 'GitHub remote found' 'GitLab remote found' 'Remote found' 'No remote found'; do
  grep -qF "$s" "$S"  || fail "setup.sh does not print '$s'"
  grep -qF "$s" "$SK" || fail "SKILL.md does not document '$s'"
done

# loop-improve and loop-review name the gitlab read path alongside the others
grep -qi 'glab issue view' "$IMP" || fail "loop-improve does not name the gitlab issue-read command"
grep -qi 'glab issue view' "$REV" || fail "loop-review does not name the gitlab issue-read command"

# this repo's own config is current (expected version derived from the template, never pinned)
TV="$(grep -E '^template-version:' "$TPL" | head -1 | sed -E 's/^template-version:[[:space:]]*//; s/[[:space:]]*$//')"
grep -q "^template-version: $TV\$" "$CFG" || fail "config/repo-state.md is not at the template's current version ($TV)"
grep -q '^tracker: github$' "$CFG"     || fail "this repo's tracker mode changed"

# house style: no em dash anywhere this task touched
for f in "$SK" "$REF" "$WF" "$CFG" "$TPL"; do
  grep -q $'—' "$f" && fail "em dash found in $f (house style forbids it)"
done

echo "PASS: gitlab doc and skill sweep"
