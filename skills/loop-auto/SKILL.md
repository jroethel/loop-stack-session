---
name: loop-auto
description: Set or check the chain autonomy knob (/loop-auto). Turns the chain from human-gated (pause) to autonomous (auto), persisted to docs/chain-state.md with an optional committed per-repo default.
---

# loop-auto

The autonomy knob for the chain.
Two modes: `pause` (the unset default - every gate fires live, the human is asked at each ASK) and `auto` (after the last ASK gate passes, the session runs the rest of the chain without further prompts).

## What it does

Run the knob through the script, or via the `/loop-auto` command:

- `/loop-auto set auto` - turn autonomy on (runtime, this session).
- `/loop-auto set pause` - turn it back off (runtime, this session).
- `/loop-auto get` - print the effective mode as a bare word for script consumers.
- `/loop-auto status` - print the effective mode and its source for the human.
- `/loop-auto default get` - print the committed per-repo default.
- `/loop-auto default set <pause|auto>` - write the committed per-repo default.
- `/loop-auto default clear` - remove the committed per-repo default.

The script is `scripts/loop-auto.sh {set <pause|auto>|get|status|default <get|set <pause|auto>|clear>|preflight <mode>}`.
It writes and reads `docs/chain-state.md`, which is the runtime source of truth for the mode (not `_loop.md`, not session memory).

Setting the mode always ends with a one-line confirmation of the new mode.
It is never silent.

## Consumption is live

Consumption is live: the knob now governs gate behavior per the four gate classes (ASK, STOP, BATCH, DEFAULT) declared in the managed CLAUDE.md / `claude-md/fable.md` block.
Under `auto`, the active session orchestrates the rest of the chain after the last ASK gate passes.
Setting the mode acts on this run, not on a future build wave.

## Per-repo default

The committed per-repo default lives as a line-anchored `autonomy-default:` key in `config/repo-state.md`.
The runtime value in `docs/chain-state.md` overrides it; `get` returns the effective mode (runtime if present, else the committed default, else `pause`).
On the FIRST `set` in a repo, ask whether to persist the mode as the repo default (committed via `default set`, which reminds the human to stage and commit the tracked change) or keep it session-only (runtime `set`).
`status` shows the effective mode and its source, for example `mode: auto (repo default)` or `mode: pause (session)`.

## Recognized phrases

Any of these phrases sets the knob to `auto` with a one-line confirmation:

- "run the rest"
- "run the rest from here"
- "take it from here"
- "go autonomous"
- "auto mode"
- "full auto"

Recognizing a phrase does not skip the confirmation.
The human always sees the new mode in the same turn.

## Where it lives

The runtime mode is persisted in `docs/chain-state.md` (gitignored runtime state, declared in `config/repo-state.md`).
`get` reads the effective mode; an absent runtime file with no committed default means `pause`.
`docs/chain-state.md` is the runtime source of truth - do not shadow it in session memory or a plan artifact.
