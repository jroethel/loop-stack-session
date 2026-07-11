# Ringer substrate (mixed-provider)

How the orchestrator session drives a wave as a ringer manifest run.
This is the substrate to use when workers should run on non-Anthropic or cheap models (GLM via z.ai, anything via OpenRouter), or when you want executed checks and a scoreboard row alongside Anthropic workers.
Ringer owns isolation, checks, retries, and logging; you own the specs, checks, model routing, and the gate.

## Tier mapping

- **Orchestrator** = this session. Writes the manifest, runs it, reads results, gates. Never a worker.
- **Implementer** = a manifest task (one `tasks[]` entry), run on an engine (`claude`/haiku, `claude-zai`/GLM, `opencode`/OpenRouter).
- **Validation** = the task's executed `check` (the primary, non-negotiable gate), plus an optional separate review task for judgment ringer's check cannot express.

## Manifest conventions, per unit

One task per unit. Each task carries:

- `key`: unit id (unique; becomes the task dir and worktree name).
- `engine` + `model`: the routing decision from Step 2 (`model` fills the engine's `{model}` placeholder; omit to take the engine default).
- `task_type`: from the canonical vocabulary (code-feature, code-fix, code-review, research, persona-review, site-build, image-gen, docs, probe, bakeoff, ...). Untyped tasks teach the scoreboard nothing and draw a lint nudge.
- `spec`: self-contained. Everything the worker needs, no pointer specs, an ownership list of every file it may touch, an embedded how-to-run, and the exact output contract.
- `expect_files`: the deliverables, so the results page shows the right work.
- `check`: prints WHY it fails, verifies substance not just presence, strict on substance and tolerant on format (P14).
- `verified`: one plain-English line stating what the check proves.

Run-level: `run_name` (the SAME across every wave of the build), `workdir`, `worktrees: true`, and `max_parallel`.

## Isolation and the patch-export pattern

Run-level `"worktrees": true` gives each task an isolated git worktree, so you do not re-specify per-task isolation.
But a passing task's worktree is DELETED, and worker commits die with it. Mitigations the plan must carry:

- **Deliverables outside the worktree**, or the check exports them first: `git add -A && git diff --cached > <path-outside-worktree>.patch`; you apply and commit on your branch after review.
- **Gitignored outputs** (`dist/`, build dirs) are not staged by `git add -A`; the check must `cp` them to a path outside the worktree explicitly. Verify the patch AND the copies.
- **Logs survive** in `<workdir>/logs/`, so post-mortems work even on deleted worktrees.
- **Stagger opencode spawns**: concurrent OpenCode workers contend on its shared sqlite state store (WAL); stagger launches or cap parallelism to avoid lock errors.

## The wave gate = ringer's post-run review ritual

At each gate, consume ringer's outputs (do not trust the summary line alone):

1. Read the run JSON in `~/.ringer/runs/` (statuses, retries, durations).
2. For every retried or failed task, read the raw worker log in `<workdir>/logs/` before deciding anything; a retry that passed on attempt 2 often flags a spec ambiguity worth fixing.
3. Spot-check at least one PASSING task's artifact.
4. A failure with a useless error message means the CHECK needs work, not (only) the worker.
5. Apply reviewed patches to the integration branch, run the full suite there, and advance only when green.

Ringer's built-in single retry IS the repair pass; do not add another. A task that fails twice is a stopped unit for the gate to resolve.

## Model assignment: prior then posterior (P7)

Route by evidence, not vibes.

- **Posterior**: `./ringer.py models --task-type <type>` gives the local scoreboard for that task_type (first-try pass rate is the routing signal). Prefer a proven model for the task_type.
- **Prior**: a model with no local evidence yet starts from the benchmark file as its prior, promoted to proven only after it earns rows (untested then probation then proven at 3+ tasks).
- Record on each routing row which evidence drove it (a scoreboard posterior, or a benchmark prior, and which).
- After a run, add a dated line to `docs/MODEL-NOTES.md` (in the ringer repo) when it taught you something about a model, supported only by the executed checks and raw logs.

## W-scaling: fewer, fatter waves (P13)

Marginal overhead per unit is flat; the binding constraint is your gate bandwidth (how many verdicts and diffs you can actually read and reason about at a gate).
So do not shard a build into more waves than the dependency graph forces.
Prefer fewer, fatter waves: put every currently-unblocked unit in the same wave, and let ringer's `max_parallel` and the stagger handle the width.
A plan with W=50 tiny waves is usually a mis-compiled W=8; collapse independent units into the same wave rather than serializing them for tidiness.
