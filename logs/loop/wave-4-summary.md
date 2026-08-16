# Wave 4 summary - T4/T5/T6 parallel

- Run: control-plane-loop-20260816T011443Z-p98459, pass 3 / fail 0, max_parallel 3.
- T4, T5 attempt 1; T6 attempt 2 (attempt 1 rc=143 timeout kill, not logic; retried clean).
- Custody clean on all three; disjointness held (no overlapping paths across patches).
- T6 diff-read (check+read): two disclosed narrowings accepted - remote title-only matching, class-d local-only; both header-documented, fail-safe.
- Patches applied as three commits; suite 43/43 on integration branch.
- Distill: nothing repeated; the timeout was a one-off environment signal.
