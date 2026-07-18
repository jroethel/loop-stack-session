# Paste-ready prompt: unified model routing brainstorm

Paste everything below the line into a fresh Fable session opened in `~/create/loops/loop-stack-session`.

---

/loop-brainstorm

**Topic:** unify model routing across loop-drive's two substrates, and settle whether /loop-setup should exist.

**Settled facts - do not re-litigate (full rationale: `learning_guide.html` section 16, `model-routing-ringer-notes.local.md` / `.remote.md`):**

- The "native vs mixed-provider" framing is fake.
  Ringer's `[engines.claude]` runs Anthropic models under the same auth and quota lane as native Agent-tool subagents.
- The real native-vs-ringer differences are transport and verification: executable check vs validator-subagent judgment; detached spec-only worker vs session-tool inheritance and SendMessage continuation; zero setup vs wired config; and only ringer runs feed the scoreboard.
- The two model-choice logics (native Sonnet/Opus ladder vs ringer scoreboard) are historical accident.
  The ladder is the route-by-vibes P7 forbids; native runs generate zero scoreboard evidence.
- The Agent tool's model set is a fixed harness enum (sonnet, opus, haiku, fable); GLM can never be a native subagent.
  Fable is orchestrator-tier only, never a worker.
- Ringer stays.
  The swap gap analysis (2026-07-18) showed every wishlist gap lives above the substrate; switching cost is the accumulated evidence in `~/.ringer/`.
  Fork policy: upstream PRs first; never let loop-* depend on patched-ringer-only behavior.
- Already landed (commits `dc53a3a`, `2d5ffc6`): verification lessons in loop-drive Steps 4-5, engines-ground-truth line in loop-which, and the managed CLAUDE.md Model routing defaults (claude-zai for execution typing; `~/.config/ringer/config.toml` is ground truth).
- Scoreboard evidence can be poisoned by the ORCHESTRATOR's own check bugs, and currently is: in the stm-nav run (2026-07-17/18), 7 of 8 recorded FAILs were Fable's checks, not the model - glm-5.2's posterior is depressed right now.
  The fix is filed as ringer issue #65 (amendment rows; design in `fixing-agent-errors.md` here, canonical in `~/repos/ringer/docs/AMENDMENT-ROWS.md` + `AMENDMENTS-PENDING.md` on the work PC).
  The patch is owned and specced - NOT a brainstorm deliverable; only its routing implications are in scope.

**Candidate direction to pressure-test (designed, not decided):**

- One model-choice procedure for every unit: scoreboard posterior for the task_type, else benchmark prior, else orchestrator pin (design / math / risk / taste, reason recorded in the evidence column).
- Substrate becomes derived per-unit transport: needs session tools or mid-flight continuation -> Agent tool; ringer absent on this machine -> Agent tool as degraded mode; otherwise -> ringer.
- The Sonnet/Opus promotion ladder demotes from a mechanism to a documented prior.
- Co-dependence stays soft: a runtime capability probe ("if ringer is present, its scoreboard is the evidence source"), so loop-plan's executor-agnostic promise survives.

**Open questions the brainstorm must settle:**

1. Wave vs unit: loop-drive Step 0 currently routes substrate per wave; derived transport implies per unit.
   Can a wave mix transports without breaking the gate/manifest structure, or does wave-level routing survive as a simplification?
2. Where does the demoted ladder's judgment live - the fable-sandwich benchmark prior file, evidence-column guidance in Step 2, or both?
3. Should native runs start feeding evidence (write outcomes to the scoreboard or MODEL-NOTES), or is the evidence gap accepted?
4. Evidence integrity: if routing leans entirely on the scoreboard, how does the procedure read a scoreboard with known-pending amendments?
   (Interim overlay exists: the jq exclusion list in AMENDMENTS-PENDING Section C; post-patch it becomes `./ringer.py amend` + the Amended column.)
   Does the routing step consult MODEL-NOTES / pending amendments before trusting a posterior, and does the same integrity discipline apply to whatever evidence native runs would write (question 3)?
   Reframing to capture in the brief (agreed 2026-07-18): if this brainstorm lands on one evidence procedure for everything, ringer #65 stops being a nice-to-have correction tool and becomes the integrity layer of the entire routing system - use that framing in the upstream PR to strengthen its case for acceptance.
5. /loop-setup verdict: skip entirely, a doctor checklist inside `install.sh` / ringer preflight, or something that earned skill status.

**Deliverable:** a brief that specs the rewrite of loop-drive Steps 0 and 2 (the Step 2 routing block was deliberately deferred for this), plus the /loop-setup verdict.

**Parked - do not pull into scope (separate brainstorm later):** dollar cost ledger with burn-rate projection, quota-aware pause/resume scheduling, long-running streams / autoresearch layer.
