# Handoff - wayfinder's GitLab/local support claim doesn't match its implementation (2026-08-22)

Filed as [issue #44](https://github.com/jroethel/loop-stack-session/issues/44) against this repo.
This session first built the `WAYFINDER.md` mirror
(github child-issue rendering, closing part of #43), then, asked why GitLab wasn't included,
found a pre-existing gap in wayfinder itself, not something introduced by that work.

## What prompted this

`skills/wayfinder/SKILL.md` states: "Wayfinder requires a remote tracker (`github` or `gitlab`):
its map and tickets are tracker issues end to end, no local-tracker variant." That line is only
partly true. This handoff is the diagnosis; the cited issue is the decision to make about it.

## Diagnosis

Three tracker modes, checked against what's actually implemented (not what the doc claims):

**local** - Correctly documented as unsupported. `SKILL.md` says so outright, and nothing
contradicts it. Not a gap.

**gitlab** - Documented as supported; nothing implements it. Checked two ways:
- `glab issue --help` (glab 1.107.0) lists no `children`/`links`/`tasks`/parent-child subcommand.
- `grep -rn "sub_issue\|child.*issue\|parent.*issue" scripts/ skills/wayfinder/` finds zero gitlab-side
  hits anywhere in the repo, before or after this session's change.

GitHub exposes a stable, documented REST endpoint for issue hierarchy
(`/repos/{owner}/{repo}/issues/{n}/sub_issues`), which `gh api` calls directly - that's what
`scripts/tracker.sh children` (added this session) uses, and it's verified live against the
real `jroethel/sys-prompts-cc` wayfinder map (11 sub-issues, correct types/states, one
multi-blocker ticket resolved correctly). GitLab's equivalent - parent/child work items, not the
older `relates_to`/`blocks`/`is_blocked_by` issue-links API - is GraphQL-only, newer, and has no
`glab` wrapper. There is also no live GitLab wayfinder map anywhere to validate an implementation
against, unlike the GitHub case.

**github** - Only half-built, and this predates today's session too. What now exists is the
*read* side: `tracker.sh children` queries a map's sub-issues (used by the new `WAYFINDER.md`
mirror). The *write* side - `SKILL.md` step 4, "Create the tickets you can specify now as child
issues" - has never been a `tracker.sh` command, in any mode. `tracker.sh create` takes no
`--parent`. The real sub-issue links on `jroethel/sys-prompts-cc` (verified to exist via
`gh api .../sub_issues`) were not made through this codebase's tooling - they were made some
other way during a live wayfinder session (direct `gh api` call or the GitHub web UI; which one,
unverified).

**Net**: the doc's "github or gitlab" claim overclaims for gitlab (nothing works) and slightly
overclaims for github too (only the read half is scripted; the write half is ad hoc every time).

## Options considered

Not exhaustive - these are the shapes I saw during this diagnosis, not a ranked-and-final list.
Someone closer to how wayfinder actually gets used day to day may see a better cut.

1. **Narrow the doc now.** Edit `SKILL.md` to say wayfinder's child-issue mechanism is
   github-only until gitlab support exists; local stays explicitly unsupported as already
   written. Cheapest fix, ships no new capability, just stops the doc overclaiming today's
   reality. Doesn't help anyone who's mid-map in gitlab mode - though nobody currently is.
2. **Finish the github side.** Add the missing write path - a `tracker.sh` command that creates
   an issue and links it as a sub-issue of a map in one call (POST to the same `sub_issues`
   endpoint) - so the fully-supported, actually-used mode is scripted end to end instead of
   read-only-scripted-plus-ad-hoc-write. Self-contained, same API family already proven live.
3. **Build gitlab support.** Heaviest option: GraphQL work-item queries and mutations (`glab api
   graphql` or raw calls), for both read and write. No CLI wrapper to lean on, a less mature
   GitLab feature, and no live gitlab wayfinder map anywhere to test against - higher risk of
   shipping something unverified.
4. **Park it.** Leave the doc as-is and do nothing, on the grounds that nobody has hit this in
   practice yet (wayfinder's only live user, `sys-prompts-cc`, is github mode). Cheapest of all,
   but leaves a false claim standing in the doc.

I lean toward (1) now - it's a one-line accuracy fix with no downside - with (2) and (3) as
separate, independently-sized follow-ups rather than bundled into one piece of work. That's a
recommendation, not a decision; the cited issue is where that gets made.
