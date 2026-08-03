---
name: loop-auto
description: Set or check the chain autonomy knob (/loop-auto). Turns the chain from human-gated (pause) to autonomous (auto), persisting intent to docs/chain-state.md.
---

# loop-auto

The autonomy knob for the chain.
Two modes: `pause` (the unset default - every gate fires live, the human is asked at each ASK) and `auto` (after the last ASK gate passes, the session runs the rest of the chain without further prompts).

## What it does

Run the knob through the script, or via the `/loop-auto` command:

- `/loop-auto set auto` - turn autonomy on.
- `/loop-auto set pause` - turn it back off.
- `/loop-auto get` - print the current mode.

The script is `scripts/loop-auto.sh {set <pause|auto>|get|preflight <mode>}`.
It writes and reads `docs/chain-state.md`, which is the single source of truth for the mode (not `_loop.md`, not session memory).

Setting the mode always ends with a one-line confirmation of the new mode.
It is never silent.

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

The mode is persisted in `docs/chain-state.md` (gitignored runtime state, declared in `config/repo-state.md`).
`get` reads it; an absent file means `pause`.
That file is the single source of truth - do not shadow it in session memory or a plan artifact.

## Important - it records intent only

Until the build wave wires consumption into the chain skills, setting `auto` records intent only and changes no runtime behavior.
The skills still fire their gates live.
The mode is written so the build wave can read it later; it does not act on its own today.
State this plainly when the human sets it, so the expectation is honest: the knob is staged, not yet live.
