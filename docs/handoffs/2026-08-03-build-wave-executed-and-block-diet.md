# Handoff: build wave executed, managed block on a diet, superpowers uninstalled

Date: 2026-08-03.
Session: Fable 5 (orchestrator) + Jeremy; /loop-drive of the build-wave plan under knob `auto`, then post-run cleanup.

## Where things stand

The build wave (roadmap item 1) is EXECUTED and merged to `main`, and `main` is pushed through `57df13d`.
Detail lives in the run artifacts, not here:

- Compiled orchestration plan: `docs/plans/2026-08-02-build-wave-plan_loop.md`.
- Run state (waves, gates, receipts): `docs/plans/2026-08-02-build-wave-run-state.md`.
- Gate journal incl. advisory review findings and checkpoint outcomes: `docs/reviews/2026-08-03-build-wave-batch-review.md`.

Result in one line: 3 ringer waves, 10/10 tasks PASS attempt 1 on claude-zai/glm-5.2, zero retries, full suite green, advisory loop-review found one low Spec finding (slipped, see journal).

## What happened after the wave (this session)

1. Post-wave STOPs resolved live: `install.sh` ran from merged main; `~/.agents/skills/benchmark-refresh/SKILL.md` repointed to the frontier-sandwich path.
2. Resume rule updated in `config/repo-state.md` + template: freshest of newest handoff vs newest commit wins; multiple open threads means name them and ask.
3. Managed block diet (`e2e80ac`): autonomy protocol moved to `skills/loop-auto/SKILL.md` (its single home), role pins moved into loop-plan and loop-drive at their use sites, benchmark-prior path into frontier-sandwich.
4. Superpowers plugin fully uninstalled (`860a8d0`); backup at `~/backups/superpowers-plugin-6.1.1-2026-08-03/`; the managed block is now 4 content lines (Fable footguns only); routing rides entirely on skill frontmatter descriptions.
5. Backlog: idea #8 (loop-setup tracker mode, github-or-local); to-do #9 (Criterion 12 one-voice read, with the 7-seam checklist in its body).

## What the next session must know going in

- Knob state: `docs/chain-state.md` still says `auto` from the wave run; set it back with `/loop-auto set pause` if the next session should be human-gated.
- The `systematic-debugging` lane went away with superpowers; the backup holds it if wanted as a standalone skill.
- `skills/frontier-sandwich/references/model-benchmarks.md` is an install-generated symlink, gitignored by design; its absence in a fresh clone is normal until `install.sh` runs.
- Jeremy's open human checkpoints: issue #9 (Criterion 12 read) and HC2 (fresh-session routing question resolving posterior -> prior -> pin) - HC2 must run against the post-diet layout, where the evidence chain loads via skill descriptions, not ambient prose.

## Suggested skills

- `/loop-auto get` (or `status`) first, to see and reset the knob.
- `/loop-brainstorm` when picking up idea #8 (tracker mode) - it is the next shaped-work candidate.
- `/loop-review <base>` for any follow-up change sets.
- `/handoff` at the next session boundary.
