---
name: loop-improve
description: >
  Audit this repo for improvements and converge the ones worth doing into a single approved brief.
  Surveys the codebase as a senior advisor, scans the Issues and Backlog lanes for overlap, and
  presents a vetted findings table; the user selects the findings worth briefing (default: the top
  3-5 by leverage) and they converge into ONE brief for /loop-plan. Read-only on source code -
  it never fixes, refactors, or scaffolds. Triggers on "audit this repo for improvements",
  "what should I improve", "improvement brief", and loop-improve.
---

# loop-improve: audit to one approved brief

You are a senior advisor, not an implementer.
You survey the repo for improvement opportunities, match them against what is already tracked, and converge the findings the user picks into one brief for /loop-plan.
How to build it is deliberately absent; that belongs to /loop-plan.

The pipeline position:

```
/loop-improve ──> findings table ──> ONE brief
                                     └─ /loop-plan ──> plan
```

<HARD-GATE>
loop-improve is read-only on source code: it audits and reports, it never edits, fixes, refactors, or scaffolds anything.
The only file it writes is the brief.
It creates no issue and closes none without assent, and it invokes no planning or implementation skill until the brief is approved.
This applies regardless of how obvious the fix looks.
</HARD-GATE>

## Step 1 - Resolve effort and focus

Parse the invocation for an optional focus argument and an effort keyword.
A focus argument scopes the audit to one category (example: `/loop-improve security` audits only security); when absent, all categories run.
The one reserved focus is `--focus harness-drift`: it delegates the whole audit to /loop-molt, which owns the harness-drift-audit protocol; loop-improve keeps no copy of that method.
The effort knob is quick/standard/deep, default standard, and sets audit depth and coverage per the vendored playbook's effort table.

## Step 2 - Audit (read-only)

Run the vendored playbook's categories, depth set by the effort knob from Step 1.
The audit reads code and never writes it.
Every finding row requires file:line evidence - no vibes-only rows and no speculation dressed as a finding.
The playbook is `references/audit-playbook.md` in this skill; read the relevant category sections and the Finding format before reporting.

### Findings table contract

Present findings as an aligned markdown pipe table with exactly these columns, in this order:

| # | Finding | Category | Impact | Effort | Risk | Confidence | Tracker |
|---|---|---|---|---|---|---|---|
| 1 | _short title drawn from the file:line evidence_ | Security | _one-line impact_ | M | LOW | HIGH | covered by #42 |

Every row carries file:line evidence, an impact one-liner, an effort estimate (S / M / L), a risk note, and a confidence level.
The Tracker column renders one of `covered by #N`, `related: #N`, or `-`, set in Step 3.
`covered by #N` means the issue's ask and the finding's fix are the same work; `related: #N` means same area, different ask.

## Step 3 - Scan the tracker

Make one call to `scripts/tracker.sh list` for the open Issues and Backlog lanes. Read `~/.claude/skills/loop-brainstorm/references/tracker-scan.md` in full and follow it before proceeding - do not summarize it from memory.
Render each match against the findings table contract above: `covered by #N`, `related: #N`, or `-` for no match.

## Step 4 - Present findings and select`[gate:ASK]`

Present the findings table, ordered by leverage (impact / effort, discounted by confidence and fix-risk).
Then the user selects which findings to converge, via AskUserQuestion with multiSelect: the default suggestion is the top 3-5 by leverage plus anything they flag, and a single finding is a fine selection when only one is worth doing.
All selected findings converge into the ONE brief - selection sets the brief's scope, never its file count.
Covered findings (Tracker shows `covered by #N`) stay selectable - converging one may be the cleaner path than the open issue.

## Step 5 - Converge through the shared brief pipeline`[gate:DEFAULT]`

Read `~/.claude/skills/loop-brainstorm/references/brief-pipeline.md` in full and follow it before proceeding - do not summarize it from memory.
Follow the shared reference from approaches through the user review gate and the commit offer, then return to Step 6 here.
The shared reference now holds the graduation contract (its single home); loop-improve's Step 6 invokes it and adds only its own supersede-close, and Step 7 is loop-improve's terminal.

The selected findings are the brief's seams, in blast-radius order, and each carries its file:line evidence into the brief's success criteria.
While authoring the brief, write each unselected finding that is NOT covered by an existing open issue into the brief's `## Parking lot` section, one bullet per finding (bullet shape per the shared graduation contract in `brief-pipeline.md`).
Record `Supersedes: #N` in the brief for each selected finding that was covered by issue #N.

## Step 6 - Leftover graduation and supersede-close`[gate:DEFAULT]`

After the Step 5 commit is accepted, graduate the brief's `## Parking lot` per the shared graduation contract in `brief-pipeline.md` (its single home): preview the parked-item count and derived titles, take assent, then `scripts/graduate-parking.sh <brief-path>` opens one `idea`-labeled issue per parked item. The parking-lot bullet shape is specified there.

The supersede-close is loop-improve's own (not part of the shared contract):
Unselected findings that ARE covered by an existing open issue are never graduated; they appear only as a Tracker-column annotation in the findings table.
For each selected finding that was covered, offer `scripts/tracker.sh close <num>` for its issue (assented, announced); declining leaves the issue open with the `Supersedes: #N` link still recorded in the brief.
Closing at brief time rather than merge time is the deliberate, brief-mandated choice: the brief already declares the supersedes, so leaving the issue open would only mislead later readers.

## Step 7 - Terminal state`[gate:DEFAULT]`

Name the approved brief's path and hand it to /loop-plan.
loop-improve's terminal is /loop-plan only; it never invokes /loop-drive or an implementation skill.
The only file it creates is the brief.
