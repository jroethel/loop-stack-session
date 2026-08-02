---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work.

Decide where it lands based on the repo the session is working in.
If `config/repo-state.md` exists at the repo root, this is a conforming repo: read its Handoffs lane and write the handoff to `docs/handoffs/YYYY-MM-DD-<slug>.md`, then refresh the mirrors in the same pass with `scripts/gen-mirrors.sh .`.
Otherwise, save to the OS temp directory of the user's OS - not the current workspace.

Include a "suggested skills" section in the document, which suggests skills that the agent should invoke.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs).
Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
