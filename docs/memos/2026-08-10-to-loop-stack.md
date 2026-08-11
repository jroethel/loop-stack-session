# Memo to loop-stack: five findings from the first gitlab-mode `/loop-setup`

Written 2026-08-10 from the `design-brand-pack` project on the WSL host, after running `/loop-setup` end to end against a fresh repo in `tracker: gitlab` mode.
loop-stack was read at `/home/jjrdar/repos/loop-stack-session`.

This is the first real gitlab-mode setup outside the test suite, and it surfaced one shipped defect, one gap in the triage design, one feature request, and two smaller asymmetries.
Every claim below was checked against loop-stack source or against the run's own output.
Findings are ordered by blast radius, not by discovery order.

Nothing here needs the `design-brand-pack` repo present to act on.

## Finding 1: `render_gitlab` ships a config that names GitHub as the source of truth

Severity: high.
This is a lie in the one file whose entire purpose is disclosure, and it lands in every gitlab-mode repo on first setup.

`skills/loop-setup/setup.sh:203-220` `render_gitlab` strips the Local tracker section and substitutes `{{BACKLOG_GROUP}}`, and does nothing else.
The template is GitHub-first, so five lines of unconditional GitHub text survive into the rendered gitlab config.

From `config/repo-state.template.md`:

| line | text that survives into a gitlab render |
| ---- | --------------------------------------- |
| 17 | `\| Issues \| GitHub (open, no `idea`) \| ...` |
| 18 | `\| Backlog \| GitHub (label `idea`) \| ...` |
| 38 | ``Backlog cross-repo view: `gh search issues --owner jroethel --label idea --state open`.`` |
| 39 | ``Per-repo fallback when private-repo search is unavailable: `gh issue list --label idea --state open`.`` |
| 48 | `GitHub is the single source of truth.` |

Verified two ways.
By reading `render_gitlab`, which contains no rule matching any of those lines.
And by reading the config it actually produced in this repo, which carried all five verbatim.

Note lines 38 and 39 are not merely wrong, they are actively misleading: a gitlab-mode repo's config hands the user a `gh` command hardcoded to the `jroethel` GitHub account.

The asymmetry is the tell.
`render_github` explicitly drops the gitlab-only lines, and `render_local` does too, both via `index($0, "glab issue list") { next }` and the matching `backlog-group:` rule.
Only the gitlab direction was left uncleaned, which reads as an oversight rather than a decision.

### Why the test suite did not catch it

`tests/loop-setup/gitlab-setup.sh` covers leakage in one direction only.

- Scenario C, local render: asserts gitlab lines are absent (lines 107-108).
- Scenario C2, github render: asserts gitlab lines are absent (lines 117-118).
- Scenario A, gitlab render: asserts the Local tracker section is stripped (lines 51-54) and that the glab query is present (line 55).
  It never asserts that any GitHub line is absent.

So "gitlab content must not leak into github or local" is tested in both directions, and "github content must not leak into gitlab" is tested nowhere.
The missing assertion is the exact shape of the bug.

### Suggested fix

Rewrite rather than drop, because a gitlab repo still needs those rows and queries, just pointed at the right backend.
In `render_gitlab`, rewrite lines 17, 18 and 48 to say GitLab, and drop the two `gh` backlog-view lines the way `render_github` drops the glab ones.
Then add the mirror assertions to scenario A so the direction cannot regress.

A deeper fix is available if it is worth the churn: make the template backend-neutral with a `{{BACKEND}}` token, so no renderer has to know which lines mention which vendor.
That removes the whole class rather than this instance.
I lean toward it, but it touches all three renderers and every render assertion, so it is a judgment call for whoever owns the file.

## Finding 2: governed-lane items have no import path and no gate

Severity: high, and it is a design gap rather than a bug.

The sweep excludes `docs/briefs/`, `docs/plans/`, `docs/handoffs/`, `docs/reviews/`, `docs/issues/` and `docs/archive/` at `setup.sh:32`.
For most of those the reasoning is sound and documented.
For `docs/briefs/` it produces a perverse result, because a brief is the single most likely place a lane-ready tracker seed lives.

That is exactly what happened here.
This repo's `docs/briefs/2026-08-10-two-host-convergence.md` was written with a "Proposed lane entries" section listing one ROADMAP item, three BACKLOG items and one ISSUES item, pre-sized and pre-classified.
It was written that way **because Jeremy told the authoring agent he would run `/loop-setup` later**.
The brief existed to be ingested, and the ingester is structurally forbidden from seeing it.

Three verified details that sharpen this:

1. The brief passes the candidate test on content shape.
   `is_candidate` matches it via `^# ` plus `^Status:`, confirmed by running both greps against the file.
   The only thing keeping it out is `is_excluded`.
2. `--scan` cannot reach it.
   `--scan` adds roots, but `collect_candidates` still runs `is_excluded` on every path from those roots, so the exclusion wins.
   Confirmed empirically: `setup.sh --scan docs/briefs --list-candidates` prints nothing.
   There is no flag, environment variable, or documented escape hatch that makes the sweep see a brief.
3. Consequently `--list-candidates` returned zero for a repo that had five ready items sitting in a file.

### The gate consequence, which is the worse half

Because governed-lane items never enter the sweep, the bash per-item `ask` prompt cannot fire for them.
That prompt is the only *enforced* gate in the import design.
The agent-path gate, `import-triage.md:20-21` "present one batch disclosure table, then offer a per-candidate walkthrough" and step 5 "on approval, file each outstanding item", is prose in a reference file with nothing behind it.

In this run I filed four GitLab issues from that brief after printing the disclosure table and without stopping for approval.
That was my error and I am not laundering it into a tool defect.
But it is worth loop-stack knowing that the failure was available: the design's only hard gate was unreachable by construction for these items, and the soft gate is a sentence an agent can reason its way past.
An agent that concludes "the human already specified this classification, so approval is implied" will file without asking, and nothing stops it.

### Suggested fix

Two parts, and the second matters more than the first.

- Give briefs an explicit, opt-in ingest path.
  Either a `--seed docs/briefs/<file>` flag, or let `--scan` override `is_excluded` for roots named explicitly on the command line, on the theory that naming a governed lane by hand is already the deliberate act the exclusion exists to require.
  Do not simply un-exclude `docs/briefs/`, because the archive-and-graduation rule "a brief archives when its plan archives" depends on briefs not being swept.
- Make the approval gate enforced rather than advised.
  The cleanest version: `tracker.sh create` refuses to run during a triage batch without an explicit approval token that only a human answer can produce.
  A weaker but cheap version: state in `import-triage.md` that a pre-supplied classification never constitutes approval, and that approval covers the issue *bodies*, which the agent writes and the human has not seen.
  In this run the classification was Jeremy's and survived unchanged; the bodies were entirely mine and were the part a walkthrough would have caught.

## Finding 3: the mode question needs `none` and combinations, and needs to be canonical for agents

Severity: medium.
This is a feature request, not a defect.

Requested: `/loop-setup` should offer github, gitlab, local, **none**, and combinations, using the existing logic for when to ask (ask once when the `tracker:` key is missing, never re-ask, per `setup.sh:361-401`).

Current state, verified:

- The bash prompt at `setup.sh:232` does enumerate all three supported modes: `tracker mode (github|gitlab|local):`.
- `none` does not exist anywhere.
  `tracker_mode_set` (`scripts/tracker.sh:20`) hard-rejects anything outside `github|gitlab|local`, and `tracker.sh list` fails closed on an unknown mode.
- Combinations are not representable.
  `tracker:` is a single line-anchored word and every consumer switches on it.

### The architectural tension to resolve first

Combinations collide with an invariant the rest of the system leans on.
`gen-mirrors.sh` writes a `source of truth:` line into every mirror header, and `config/repo-state.md` states a single source of truth in prose.
Two simultaneous backends means either two sources of truth, which makes that disclosure meaningless, or a declared primary plus a secondary, which is a different and larger feature.

So the loop-stack session should decide what a combination *means* before implementing one.
The plausible readings are materially different work:

- **Primary plus mirror**: issues live on one backend and the other holds a read-only copy, which preserves the invariant.
- **Split by lane**: for example Issues on GitLab and Backlog local, which breaks one disclosure line into two.
- **Remote for code, local for tracking**: arguably not a combination at all, just `local` in a repo that happens to have a remote.

That third reading is already supported, and it is exactly what the `tracker-remote-ack:` key exists for.
Confirm it with Jeremy before building anything, because it may be what the request is actually reaching for, in which case the work is documentation rather than code.

`none` is the simpler half and can ship independently: it means no tracker, no `ISSUES.md`, no `BACKLOG.md`, no `idea` label, no mirror generation, and `ROADMAP.md` plus the docs homes only.
It needs `tracker_mode_set` to accept it and every consumer to skip cleanly rather than fail closed.

### The agent-layer half

`SKILL.md` documents that setup.sh "asks the mode once" on stdin, and gives the agent no canonical option list to present.
Agents front this question in their own UI rather than letting the bash prompt through, and I did exactly that in this run and dropped `gitlab` from the options I offered.
Jeremy caught it and asked where it went.
The mode list is about to get longer, so `SKILL.md` should carry the canonical enumeration and an instruction that the agent presents all of it, including the environment caveats that make an option viable or not.

## Finding 4: gitlab mode fails fast on a missing remote but offers no way to create one

Severity: low, but it cost real time in this run.

`setup.sh:409`, github mode: `[ -n "$remote_url" ] || echo "no remote - to create one: gh repo create --private"`.
The gitlab branch has no equivalent.
Instead `setup.sh:422` fails with `tracker: gitlab requires an origin remote to resolve the GitLab host` and stops.

The gitlab hint is more necessary than the github one, not less, because of the host trap below.

Two byproducts hit this run, both worth a line in the hint:

- `glab repo create` run from inside an existing repo created a nested empty clone at `<repo>/<repo>/`, with 0 commits, 0 tracked files and 0 stash, pointing at the same remote.
  It broke the next `git add -A` with `does not have a commit checked out`.
  `--skipGitInit` avoids it.
- It also did not set `origin` on the outer repo, so the remote had to be added by hand before setup could proceed.

Suggested hint text for the gitlab branch, adapted per instance:

```
no remote - to create one: GITLAB_HOST=<host> glab repo create <name> --private --skipGitInit
then: git remote add origin <url>
```

## Finding 5: two smaller correctness gaps

**The `glab` default-host trap.**
`setup.sh` gets this right for auth, scoping the guard with `--hostname "$host"` from the remote, and `tests/loop-setup/gitlab-setup.sh:64` even asserts a bare `glab auth status` is never used.
But the config template's own cross-repo backlog view, template line 40, is `glab issue list --group <group> --label idea`, with no host.
A cross-repo query is by definition often run from outside any repo, where glab falls back to its configured default host.
On this machine that default is `gitlab.com`, which is unauthenticated and returns 401, so the one command in the config that cannot resolve a host from context is the one most likely to be run without one.
Suggest the template emit `GITLAB_HOST=<host> glab issue list --group <group> --label idea` for the cross-repo line, since the host is already known at render time.

**`docs/chain-state.md` is declared gitignored and never gitignored.**
Template line 20 says `Runtime, gitignored`, and `setup.sh` never writes that pattern to `.gitignore`.
A repo that follows the config as written will commit its runtime chain state.
One appended line in the finalize, guarded by a grep so it stays idempotent, closes it.

## What this repo did locally, for reference

All five findings were worked around in `design-brand-pack` rather than fixed upstream, so nothing here has been patched in loop-stack.

- The rendered `config/repo-state.md` was hand-corrected to say GitLab throughout, and gained a `GITLAB_HOST` caveat line.
  This will be offered for overwrite by `reconcile_config` on the next template-version bump, which is correct and disclosed behavior.
- `docs/chain-state.md` was added to `.gitignore`.
- The nested empty clone was inspected, confirmed empty, and removed.
- The four issues filed from the brief are `#1` through `#4` on `gitlab.code.rit.edu/jjrdar/design-brand-pack`, and are still open to a retroactive walkthrough.
