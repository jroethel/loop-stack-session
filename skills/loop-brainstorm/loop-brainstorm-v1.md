# loop-brainstorm v1 - derivation review

Reviewed 2026-07-17 against `superpowers:brainstorming` 6.1.1
(`~/.claude/plugins/cache/superpowers-marketplace/superpowers/6.1.1/skills/brainstorming/`).
Verdict: a faithful derivative, not a reinvention.
The skeleton is the superpowers version; content differences trace to the re-grounding prompt
("this skill is about brainstorming, not the implementation plan or PRD").
Installed copy at `~/.claude/skills/loop-brainstorm/` is identical to the repo copy.

## Why fewer files

Of superpowers' 8 files, only SKILL.md carries the process.

| Superpowers file                             | Status in loop-brainstorm                          |
|----------------------------------------------|-----------------------------------------------------|
| `SKILL.md`                                   | Ported: same skeleton, adapted content              |
| `visual-companion.md` + `scripts/` (5 files) | Dropped: the browser mockup companion               |
| `spec-document-reviewer-prompt.md`           | Vestigial even in superpowers 6.1.1: current        |
|                                              | SKILL.md uses inline self-review; nothing           |
|                                              | references this file anymore                        |

## Preserved dialogue skeleton

- HARD-GATE block, same placement and force.
- "Too simple to need this" anti-pattern section.
- 9-item checklist in the same order:
  explore → probe scope → one-question-at-a-time → 2-3 approaches → present in sections →
  write file → self-review → user review gate → single pinned handoff.
- One question per message, multiple choice preferred.
- Self-review: same four checks (placeholder, consistency, scope/architecture, ambiguity)
  plus a new tag audit.
- User review gate quote near-verbatim.
- Terminal-state pinning ("the ONLY skill you invoke next is X").
- Dot digraph with the same shape; red-flags rationalization table.

## Deliberate divergences

| Divergence                                             | Traces to                                    |
|--------------------------------------------------------|----------------------------------------------|
| Design doc → idea brief; drops architecture,           | The re-grounding prompt: superpowers drives  |
| components, data flow, testing, "design for isolation" | to a full design; that was cut on purpose    |
| Three scope probes (trenchcoat, meta-tooling probe,    | self-manual: idea cascade, meta-tooling      |
| asset sweep)                                           | gravity, inventory-implies-options           |
| `[executed-check]` / `[judgment]` criterion tagging    | Loop research P1/P6; tags feed /loop-which   |
|                                                        | and /loop-drive downstream                   |
| Terminal state: loop-plan (forthcoming) instead of     | Pipeline position in this repo               |
| writing-plans                                          |                                              |

## Open items for v2

- **Visual companion**: the one superpowers feature genuinely gone rather than adapted,
  and it was dropped silently.
  Assessment: right call for this skill (brief excludes UI/architecture content; companion is
  token-heavy), but it is a user decision.
  If wanted, reference it from the superpowers plugin directory rather than copying.
- **loop-plan placeholders**: resolved 2026-07-17; /loop-plan shipped and both lines now point
  to it.
