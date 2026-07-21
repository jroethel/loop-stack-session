---
name: loop-review
description: Two-axis review (Spec and Standards) of the diff since a user-supplied fixed point that discloses its resolved sources before any finding, runs both axes as parallel fresh-context subagents, and works in any repo with zero setup - use when the user wants to judge whether finished work (loop-driven or hand-made) was good, or asks to "review since X".
---

Two-axis review of the diff between `HEAD` and a fixed point the user supplies.

- **Spec** - does the code faithfully implement the originating plan, brief, issue, or PRD?
- **Standards** - does the code conform to this repo's documented coding standards, plus a baseline set of code smells?

Both axes run as parallel fresh-context subagents so they don't pollute each other's context, then this skill aggregates their findings side by side, never merged.

This skill has no setup dependency.
It runs in any repo, even one with zero loop-stack or issue-tracker conventions.

## Process

### 1. Pin the fixed point

Whatever the user passed is the fixed point - a commit SHA, branch name, tag, `main`, `HEAD~5`, and so on.
If they didn't specify one, ask for it.

Capture the diff command once: `git diff <fixed-point>...HEAD` (three-dot, so the comparison is against the merge-base).
Also capture the commit list via `git log <fixed-point>..HEAD --oneline`.

Before going further, confirm the fixed point resolves (`git rev-parse <fixed-point>`) and the diff is non-empty.
A bad ref or an empty diff fails here, not inside a subagent.

On an empty diff, fail with an actionable message rather than a bare error: "No commits between `<fixed-point>` and HEAD. Run loop-review from the branch you finished, or pass the pre-work ref (for example `HEAD~3` or the commit you branched from)."
This is the flagship-command trap: `/loop-review main` run while sitting on `main` produces an empty diff, so the message must point the user to the fix.

### 2. Identify the spec source

Resolve the spec source in this fixed order, stopping at the first hit.

1. An explicit path passed as the second argument to the skill.
2. A plan under `docs/plans/` whose topic slug appears in the current branch name (`git rev-parse --abbrev-ref HEAD`).
3. A brief under `docs/briefs/` by the same branch-name match.
4. Issue references in the commit messages (`#123`, `Closes #45`).
   Fetch the referenced issue with the `gh` CLI (`gh issue view <n>`) if `gh` is available and authenticated.
   If it is not, record the reference text as the spec pointer and note it was not fetched.
5. If nothing matched, default to rung 7 immediately in this same response - do not stop and wait on a question first.
   Never let the current report sit half-finished on a pending reply: a question posed in prose inside a one-shot response has no way to get an answer back inside that same response, so treat "nothing matched" as unresolved for this run and move straight to producing the full report.
   If plans or briefs exist but none matched the branch, name the most recent by `YYYY-MM-DD` filename date as a labeled suggestion inside that same rung 7 warning, but still do not auto-resolve to it - the Spec axis stays skipped for this run.
6. The one exception: if the user's own invocation already told you there is no spec (they said so before or while asking for the review), the disclosure reports "no spec available (confirmed: none exists)" instead of the rung 7 wording, and the Spec axis is skipped; the Standards axis still runs.
7. Default wording when nothing matched and rung 6 does not apply: the disclosure reports "no spec available (not found automatically - none passed and nothing matched under docs/plans or docs/briefs; pass an explicit path if one exists)" as a warning, and the Standards axis still runs in this same response.
   A user who wants to correct this re-invokes with an explicit path, or confirms there is none, which is rung 6.

There is no dependency on `docs/agents/` or any setup file.
When rung 2 or 3 resolves the spec source, name it using the exact phrase "matched by branch name" in the disclosure (see step 4).
Discovery is internal bookkeeping: if rung 2 or 3 matches, do not name or describe any other candidate plan or brief file that did not match anywhere in the disclosure or either axis's findings - state only the one resolved source.

### 3. Identify the standards sources

Collect anything in the repo documenting how code should be written, such as `CODING_STANDARDS.md`, `CONTRIBUTING.md`, and the like.

On top of whatever the repo documents, the Standards axis always carries the smell baseline below - a fixed set of Fowler code smells (_Refactoring_, ch.3) that applies even when a repo documents nothing.
Two rules bind it.

- **The repo overrides.** A documented repo standard always wins; where it endorses something the baseline would flag, suppress that smell.
- **Always a judgement call.** Each smell is a labelled heuristic ("possible Feature Envy"), never a hard violation, and, like any standard here, skip anything tooling already enforces.

Each smell reads *what it is* then *how to fix*; match it against the diff.
Reproduce this baseline verbatim - the Standards subagent has no other access to it.

- **Mysterious Name** - a function, variable, or type whose name does not reveal what it does or holds. -> rename it; if no honest name comes, the design is murky.
- **Duplicated Code** - the same logic shape appears in more than one hunk or file in the change. -> extract the shared shape, call it from both.
- **Feature Envy** - a method that reaches into another object's data more than its own. -> move the method onto the data it envies.
- **Data Clumps** - the same few fields or params keep travelling together (a type wanting to be born). -> bundle them into one type, pass that.
- **Primitive Obsession** - a primitive or string standing in for a domain concept that deserves its own type. -> give the concept its own small type.
- **Repeated Switches** - the same `switch`/`if`-cascade on the same type recurs across the change. -> replace with polymorphism, or one map both sites share.
- **Shotgun Surgery** - one logical change forces scattered edits across many files in the diff. -> gather what changes together into one module.
- **Divergent Change** - one file or module is edited for several unrelated reasons. -> split so each module changes for one reason.
- **Speculative Generality** - abstraction, parameters, or hooks added for needs the spec does not have. -> delete it; inline back until a real need shows.
- **Message Chains** - long `a.b().c().d()` navigation the caller should not depend on. -> hide the walk behind one method on the first object.
- **Middle Man** - a class or function that mostly just delegates onward. -> cut it, call the real target direct.
- **Refused Bequest** - a subclass or implementer that ignores or overrides most of what it inherits. -> drop the inheritance, use composition.

### 4. Disclosure opener

Before the two axis sections, the report opens with a short disclosure block that names, in plain text:

- The resolved spec source and which discovery rung produced it, using the exact phrase "matched by branch name" when rung 2 or 3 resolved it (for example: "Spec source: `docs/plans/2026-07-21-loop-review-plan.md` (plan, matched by branch name)"), or one of the two no-spec wordings from step 2 rungs 6 and 7.
- The standards sources (each documented file found, plus "Fowler 12-smell baseline").

Name only the resolved source.
Do not list, name, or otherwise reference any other plan or brief file that discovery considered but did not choose - the disclosure states the outcome, not the search.
This block is the skill's basis-before-findings contract.
It always precedes `## Spec` and `## Standards`.

### 5. Spawn both subagents in parallel

Send a single message with two `Agent` tool calls.
Use the `general-purpose` subagent for both, at medium reasoning effort.

Choose the reviewer model by its role (a review / validation gate) per the user's routing conventions if present, else the session's default capable model.
Do not hard-pin a model name.

**Standards subagent prompt** - include:

- The diff command and commit list.
- The standards-source file list found in step 3, plus the full smell baseline from step 3 pasted in - the subagent has no other access to it.
- The brief: "Report, per file/hunk where relevant: (a) every place the diff violates a documented standard, citing the standard (file plus the rule); and (b) any baseline smell you spot, naming it with its baseline label verbatim (for example 'Mysterious Name') and quoting the offending symbol or hunk. Distinguish hard violations from judgement calls; documented-standard breaches can be hard, baseline smells are always judgement calls, and a documented repo standard overrides the baseline. Skip anything tooling enforces. Under 400 words."

**Spec subagent prompt** - include:

- The diff command and commit list.
- The path or fetched contents of the spec.
- An instruction that it judges the diff only against the one spec handed to it, and does not go looking for or mention any other plan or brief file it may notice in the repo.
- The brief: "Report: (a) requirements the spec asked for that are missing or partial; (b) behaviour in the diff that was not asked for (scope creep); (c) requirements that look implemented but where the implementation looks wrong. Quote the spec line for each finding. Under 400 words."

If the spec is missing, skip the Spec subagent and note it in the final report.

### 6. Aggregate

Present the two reports under `## Spec` and `## Standards` headings, verbatim or lightly cleaned.
Do not merge or rerank findings - the two axes are deliberately separate (see _Why two axes_).

End with a one-line summary per axis: findings per axis, and the worst issue within each axis (if any).
Don't pick a single winner across axes - that's the reranking the separation exists to prevent.

Every finding must cite its spec line or its named standard.

## Why two axes

A change can pass one axis and fail the other:

- Code that follows every standard but implements the wrong thing -> **Standards pass, Spec fail.**
- Code that does exactly what the plan or issue asked but breaks the project's conventions -> **Spec pass, Standards fail.**

Reporting them separately stops one axis from masking the other.
