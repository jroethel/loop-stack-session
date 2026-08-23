---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work.

Decide where it lands based on the repo the session is working in.
If `config/repo-state.md` exists at the repo root, this is a conforming repo: read its Handoffs lane and write the handoff to `docs/handoffs/YYYY-MM-DD.<tokens>.<slug>.md`, then refresh the mirrors in the same pass with `scripts/gen-mirrors.sh .`, then run `scripts/lifecycle-lint.sh .` and surface any findings.
Otherwise this is a non-conforming repo: create `docs/handoffs/` inside the project on demand and write the handoff to `docs/handoffs/YYYY-MM-DD.<tokens>.<slug>.md` there, never outside the project.
When the work belongs to a logged tracker item, include its token segment(s) (e.g. .I6 for issue 6, .B4 for backlog item 4, .R1 for roadmap item 1, .W3 for wayfinder ticket 3); when the item is not yet logged, omit the token segments entirely and insert them when the item is created.

Include a "suggested skills" section in the document, which suggests skills that the agent should invoke.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.
