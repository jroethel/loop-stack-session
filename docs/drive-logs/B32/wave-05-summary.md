# Wave 5 summary - B32 jrit-loop port

Date: 2026-09-13.
Units: U10 (T10 eval suite, opus, Agent tool, pin:discovery), U12 (T12 cutover staging, glm-5.2, ringer).

## Results

| Unit | Implementer | Validator | Final | Repairs |
| --- | --- | --- | --- | --- |
| U10 | self-pass, 5 cases at 1.0, $3.74 | pass; independent full rerun 20/20 graders at 1.0, $5.76, no flakiness | cherry-picked to main (5cafafc) | 0 |
| U12 | pass attempt 1 | pass 6/6; non-vacuity proven by three mutations; ordering assertion proven to have teeth | merged (18b9fce) with tilde path scrub | 0 |

run-all green on main; b32-w6-base tagged and pushed.

## Notable

- Rubix eval case NOT demoted: the runner's isolated HOME is unconditional (verified from the binary's env-spread order and a live sandbox inspection), so the absent branch fires for real despite rubix-review being installed on this host.
- Discovery facts (env override EVAL_*-only; the six grader types and exact match syntax; isolated HOME) verified twice independently and recorded as dated lines in docs/eval-fixtures-are-engine-neutral.md.
- HOST CHANGE, disclosed and journaled: socat installed via user-scope brew (the eval sandbox backend requires it; every Bash-granting eval run refuses without it). Reversible: brew uninstall socat.
- U12's decommission doc honestly discloses the plan-vs-disk repo-list gap (resolved count 3 against the brief's 8) and parks it for the C3 handoff; the validator's -maxdepth 5 cross-check shows the gap is not a depth artifact.
- Merge-time fixes: /home/jjrdar paths scrubbed to tilde form in decommission.md (public-flip exposure); "twelve" corrected to "eleven" in one verified-fact line.

## Slip notes added

- D6 disclosure capitalization: spec embeds the sentence lowercase mid-sentence, live agents capitalize it; the two eval graders treat this inconsistently (rubix case-insensitive, ringer case-sensitive). Any future grep -F of the lowercase form will miss.
- Inlined pre-plugin fixture in the eval case is byte-identical to tests/fixtures/pre-plugin-repo/ today, with nothing enforcing the equality; a one-line grep test would close it.
- D11 design ceiling, spec-level: the ## Expected behavior section ships to the agent under test, so the evals prove reachable outcomes, not unbidden behavior; the static tests carry the unled reading.
- Eval suite cost is a range, not a constant ($3.74 and $5.76 across two runs; the ringer case is half of it); the doc's single figure should read as a range.
- Setup case's llm grader silently drops the nothing-outside-the-markers clause (vacuous on a fresh scratch repo); resume case asserts heading order but grades headings independently.
