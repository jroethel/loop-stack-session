# Brief: packaging loop-stack for N hosts (phase 1 of the packaging arc)

## Outcome

The loop-stack installs cleanly, non-interactively, and identically on any of Jeremy's machines, with every host-specific value held in one declared parameter home instead of hardcoded.
Presupposition verdict: "packaging" as a distribution artifact was the hypothesis; the phase-1 outcome is install portability across his own hosts.
The consumer arc is staged deliberately: Jeremy-on-N-hosts now, other developers (public) next, the RIT team (no OS assumption) after that; this brief is only the first stage, shaped so the later stages inherit its parameterization.

## End artifact

First: a clean-room environment containing none of Jeremy's dotfiles that runs the installer non-interactively, passes the full test suite, and completes a no-network degraded-mode compile probe.
Then: the RIT/WSL host installs via git pull and drives one real loop end to end.
The clean room comes first because the WSL host runs live projects and is not an experiment surface.

## Done looks like

- Scratch env: `git clone https://github.com/jroethel/loop-stack-session.git && cd loop-stack-session && LOOP_STACK_SKILL_STYLE=agents ./install.sh && tests/run.sh` all green, followed by the degraded-mode dry compile probe.
- Host 2 (RIT/WSL): `git pull && ./install.sh && tests/run.sh` green, then one real loop driven to a landed unit with receipts.
- A hardcode grep for host-specific values (`~/repos/ringer` literals, `/Users/jjrdar`, wrapper env specifics) returns hits only inside the declared parameter home and historical records (archive, ledger, dated handoffs).
- A written multi-host section documents git push/pull as the supported reconciliation mechanism between hosts, superseding backlog #16.
- The multi-host section also states that scoreboard posteriors stay host-local by design (P7: routing numbers are not portable between users or hosts), so git syncs the repo but never the evidence ledger, and each host re-earns its posteriors.

## Assets and options

| Asset                              | Implied option                                    | Decision                                  |
| ---                                | ---                                               | ---                                       |
| `install.sh` two-style installer   | Evolve in place vs replace                        | Chosen: evolves in place                  |
| `~/repos/ringer` clone             | Parameterize root vs keep convention              | Chosen: root parameterized (convention    |
|                                    |                                                   | default); expected version recorded too   |
| claude-zai wrapper + `zai-token`   | Parameterize path/env; token handling             | Chosen: parameterized; token never in git |
| `~/.agents/skills` neutral home    | Stays default style vs claude-direct default      | Chosen: stays the default style           |
| RIT/WSL host                       | Host-2 proof ground                               | Chosen: after clean-room proof only       |
| git push/pull between hosts        | The multi-host sync mechanism                     | Chosen: documented as the mechanism       |
| Backlog #30 (guard + blacklist)    | Absorb whole vs split                             | Guard chosen; blacklist parked            |
| Backlog #16 (multi-host support)   | Absorb vs keep open                               | Chosen: absorbed, closes when this ships  |
| Backlog #28 (/dev/tty gate)        | Absorb vs keep separate                           | Declined: stays its own item              |

## Approach

Chosen: parameterize-in-place, proven bottom-up - one declared host-config surface owns every host-specific value; `install.sh` consumes it with defaults reproducing today's conventions; the #30 non-interactive guard lands in the same pass; proof order is clean-room then host 2.
Considered: a versioned distribution artifact (template/release) - right shape for the public phase, premature for N=2 self-hosts and divergent from the git-pull workflow already in use.
Considered: containerized runtime - solves hardcodes by construction but fights the stack's nature (skills symlinked into live harness homes, loops over live repos).
Rationale at decision time: Jeremy chose full parameterization now over convention-plus-clean-room-forced, accepting more work in this pass so the public phase inherits it done.

## Success criteria

1. `[executed-check]` A non-interactive `install.sh` run with `LOOP_STACK_SKILL_STYLE` set exits 0 without prompting, in an environment with none of Jeremy's dotfiles.
2. `[executed-check]` A non-interactive run WITHOUT `LOOP_STACK_SKILL_STYLE` refuses with a clear message instead of defaulting - the 2026-08-16 live-install incident cannot recur (#30 guard half).
3. `[executed-check]` `tests/run.sh` passes green in the clean room.
4. `[executed-check]` A no-network degraded-mode compile probe (ringer absent) completes in the clean room.
5. `[executed-check]` The hardcode grep finds zero host-specific values outside the declared parameter home and historical records; the allowlist is explicit in the check.
6. `[executed-check]` Host 2 reaches green (`git pull && ./install.sh && tests/run.sh`) with its host-specific values supplied only through the parameter home.
7. `[judgment]` One real loop driven on host 2 lands its unit with tracker receipts; reformulation attempted (the loop's own checks are executed), but "a real loop on real work" is a judgment call kept as such.
8. `[executed-check]` The multi-host mechanism section exists and #16 is closed referencing it when the brief's work ships.

## Seams

1. Parameter home and hardcode sweep - defines the config surface every later seam consumes; biggest blast radius.
2. `install.sh` parameterized consumption plus the non-interactive guard (#30 guard half).
3. Clean-room proof harness - the scratch-environment check that runs seams 1-2's criteria.
4. Multi-host documentation and host-2 rollout - git push/pull mechanism written down, #16 absorbed, real-loop proof.

## Known vs guessed

- Verified (this session): `install.sh` prompts on a TTY and defaults to agents style; hardcode sites grepped at `install.sh:136,143-145,153`, `README.md:77,131-132`, `config/routing/model-benchmarks.md`; suite 43/43 at `b75ea64`; #16, #28, #30 open on the tracker.
- Verified (repo record): the WSL host reads loop-stack at `/home/jjrdar/repos/loop-stack-session` (memo 2026-08-10) - a different path than this Mac's checkout, which is itself evidence for parameterization.
- Believed-unchecked: the WSL host's current repo state and installed-skill style; reconciling it is part of seam 4, not assumed.
- Guessed: no consumer of host-specific paths exists beyond install.sh, the ringer config/wrappers, and docs; if wrong, the seam-1 sweep widens but nothing downstream changes shape.

## Parking lot

- Reviewer-prompt blacklist for mutating repo scripts (#30's second half) - read-only reviewer prompts must be barred from running install or state-changing scripts
  Restart context: the 2026-08-15 spec-axis reviewer executed install.sh per a How-to-run line despite read-only instructions; see docs/handoffs/2026-08-15-control-plane-drive-close.md
- Public-phase genericization - license posture, stranger-first README onboarding, secrets documentation, template or release form
  Restart context: consumer stage 2 per the 2026-08-16 packaging brief; parameterization from phase 1 is its prerequisite and will already exist
- RIT-team turnkey phase with no OS assumption
  Restart context: consumer stage 3 per the 2026-08-16 packaging brief; depends on the public-phase genericization landing first
- Context-map full index from the consolidated recommendations memo - grow the minimal repo-state section into the ~20-line pointer index, including where decision records live (briefs' Approach sections, batch journals, molt ledger)
  Restart context: recommendations Section 6-2 plus the 2026-08-16 Snipd-source check (four layers mapped; context map partial, decisions distributed and un-indexed); the minimal section landed 2026-08-16 in the pcs disposition pass

## Out of scope

- Public release and anything stranger-facing (stage 2).
- RIT-team onboarding (stage 3).
- Packaging the ringer repo itself - it remains a documented prerequisite with a parameterized location.
- The /dev/tty-hardened gate (#28) and the reviewer-prompt blacklist (parked).
- Any change to skill content or loop behavior - deliberately excluded so the clean-room and host-2 proofs attribute green or red to install machinery alone; a pass that changes skills and packaging together proves neither.
  The adjacent threads have their own homes: the ringer best-practice question was answered 2026-08-16 against the evaluation verdict (no change warranted; check-custody lint is #29), and the context-map full index is parked below.

## Open questions for planning

- The parameter home's form: env vars, a config file, or file-with-env-override, and where it lives.
- How the parameter home records the expected ringer version per host (pinned commit vs floating), and what the install check does on a mismatch.
- Clean-room technology: container, VM, or a temp-HOME sandbox on this Mac.
- Whether `config/ringer/config.toml` needs a render step for parameterized engine paths or stays a documented manual edit.
- How installer-generated symlinks (inherently absolute per host) interact with the parameter home on regeneration.
- The exact allowlist for the hardcode grep (historical records that legitimately keep old paths).
- Close mechanics for #16 (close-on-ship referencing the multi-host section).
