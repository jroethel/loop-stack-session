# Roadmap

Ordered, low-churn narrative of where this repo goes next.
Detail lives in the linked briefs and plans; this file orders them.
Item 1 is the active stream (scope rule: `config/repo-state.md`).
Ideas not yet scheduled live on the backlog (`gh issue list --label idea`, mirror `BACKLOG.md`).

## 1. Build wave (next)

One brief, then /loop-plan, then /loop-drive, applying the settled ledger (`docs/2026-08-02-settled-decisions-and-sequence.md`) in one pass:

- loop-plan: H (Opus decompose dispatch with session dependency-graph review), K (prefactor rule; expand-contract as reference), lensing per the routing doc.
- loop-drive: in-skill Opus compile dispatch (G), explicit start-from-existing-`_loop.md` entry point, gate-tag consumption (the knob goes live here - `/loop-auto` records intent only until this lands).
- loop-brainstorm: E (domain modeling absorption, scenario stress-tests), parking-lot graduation wiring (auto `gh issue create --label idea` at brief-commit time per `config/repo-state.md`).
- wayfinder: copy Matt's, add the routing hand-off (J); its ticket-type labels layer on the lane scheme.
- loop-which: frontmatter trim.
- frontier-sandwich: rename from fable-sandwich, add as repo skill, config stays generalized.
- Verification carries the HC2 fresh-session routing check from the model-routing thread.
- The build wave itself runs under the autonomy knob as seam C's demonstration (end artifact of `docs/briefs/2026-08-02-autonomy-knob-brief.md`).

## 2. After the build wave

- Migrate sprawl repos (pokemine, vaultwise, substack-scraper) to the repo-state convention as each is next touched (tracked as a backlog idea).
- Revisit parked backlog ideas as they come due: `gh issue list --label idea`.
