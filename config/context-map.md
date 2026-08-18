# Context map

The orientation index for this repo: every piece of durable, non-derivable memory a fresh agent
needs, reached through one pointer each. Read this file first, then follow any line to its artifact.
This is the repo's answer to "paste everything into the prompt" - the pointers are the context, the
content stays where it lives.

## What earns a line

The durability test: a fresh agent needs it AND cannot derive it from the code or the git history.
Index homes over individual files (one line covers a whole lane forever); a single file earns its
own line only when it is a singular landmark. Additions are rare by construction - a new KIND of
artifact, or a new load-bearing document. Per-user operating lessons are NOT indexed here: those
live in auto-memory (`MEMORY.md`). The boundary is firm - this map holds repo-committed pointers to
in-repo artifacts and external corpora, never anything about how one person likes to work.

## Line shape

Each line is `what - where-or-how-to-retrieve - why it matters`, on one physical line, with ` - `
used only as the top-level clause separator. The why clause is load-bearing: a prune pass reads it
to keep or retire the line without opening the pointee, so it states what the artifact gives an
agent, not merely what it contains.

## Decay: dating plus a usage look

Two signals govern whether a line still earns its place; dating is the reliable one, usage is a
corroborating look with known blind spots.

- Dating is the primary cheap marker. Anything that can rot carries a `(YYYY-MM-DD)` date - external
  paths, retrieval verbs, and transient snapshots. In-repo durable lines carry no date, and
  machinery-supporting operational notes count as durable. A dated line is never auto-dead at any
  age; the date is an input to the prune look, not a timer.
- Usage is a rough corroborating look, not a precise counter. Age cannot tell a pointer used once
  from one used constantly, so at each prune pass a coarse citation count helps: `git grep -l
  <pointee-basename> | grep -v config/context-map.md | wc -l` counts how many tracked files reference
  the pointee. Read it as a weak signal, never a verdict - it over-counts the brief or handoff that
  first named the line, under-counts a real "follow" (a markdown line read directly emits no event),
  and misses any citation phrased without the filename. No live counter is kept: self-reported bumps
  on every orientation would flood git with noise, so usage is derived retrospectively at the gate,
  coarsely, never tracked live. When the count and the date both say a line is cold, retire it; when
  they disagree, the why clause and a human's judgment decide.

## Lifecycle

- Add: at the durability test above, on the write gates below; homes over files; verbose-announce
  the added line.
- Refresh: touching a pointee (edit, supersede, move) revalidates its line's where and why in the
  same change; a move is rewritten in place, never appended as a correction.
- Prune: this map is an explicit target at every molt-close - per line, run the removal test (does
  it still pass the durability test?) plus the usage-and-staleness look above; no retrieval verb is
  executed by the lint.
- Delete: the pointer moves or dies with its pointee (at archive or graduation); verbose-announce
  the moved or deleted line. The class-e lint will go red between removing a pointee and removing
  its map line - that red at an archive or molt gate is expected, and clearing it is this Delete
  step, not a regression to back out.
- Write gates: brief commit, handoff close, molt close, archive/graduation. Every line added, moved,
  or deleted is announced, the same precedent as parking-lot graduation and mirror regeneration.

## The index

### In-repo, durable

- Molt evaluation basis - `docs/memos/2026-08-15-pcs-consolidated-recommendations.md` (protocol at `skills/loop-molt/references/protocol.md`, ledger `docs/molt-ledger.md`) - the pcs verdict and the second axis a molt re-derives its constraints from, without which an audit restarts its reasoning from zero.
- Decision records, four homes - Approach sections under `docs/briefs/`, batch journals under `docs/reviews/`, the drift ledger `docs/molt-ledger.md`, and inline DECISION lines, with the 2026-08 set anchored by `docs/2026-08-02-settled-decisions-and-sequence.md` - where a past "why did we choose X" is written down, so it is read instead of re-litigated.
- Engineering principles - `principles.md` (P1-P14) - the numbered principle vocabulary the diagrams and learning guide cite, needed to read those artifacts or name a principle in review.
- Origin design record - `PLAN.md` and `conversation-archive.md` - the approved full build plan and the 2026-07-10 session behind it, the "why is the stack shaped this way" that code and commits never narrate.
- Model-routing prior tier - `config/routing/model-benchmarks.md` - the routing chain's prior-tier scoreboard and loop-which's tier examples, how an agent resolves a tier to a model before any local scoreboard evidence exists.
- Git conventions for loop work - `docs/git-guide.md` - loop-stack's return points, worktree gates, and recovery moves, which generic git knowledge does not cover.

### External (dated)

- Research corpus - `~/create/research/research/` outside the repo, query via `qmd search '<topic>'` (collection `research`) - the 13 digests behind the 2026-08 evaluation, the evidence a design decision cites without pasting any of it. (2026-08-18)

### Transient (dated, expected to die at a molt or archive pass)

- Agent-error field notes - `fixing-agent-errors.md` - a raw pasted transcript of failure patterns, kept until a molt distills or archives it. (2026-08-18)
- Model-routing run notes, local engine - `model-routing-ringer-notes.local.md` - the raw transcript behind routing-unification work, superseded once its findings land in durable form. (2026-08-18)
- Model-routing run notes, remote engine - `model-routing-ringer-notes.remote.md` - the raw transcript companion for the remote engine, same expiry. (2026-08-18)
- First gitlab-mode setup findings - `docs/memos/2026-08-10-to-loop-stack.md` - a dated cross-host report from a real /loop-setup run, retired once its findings are absorbed or stale. (2026-08-18)
