# Model routing apparatus: findings and gaps

Dated evidence capture from a 2026-08-25 investigation session, prompted by the question "how is
`config/routing/model-benchmarks.md` actually used" and pushed into a full audit at the user's
request. Every claim below was checked against running code or committed data in this session;
none is carried forward from memory or from the routing docs' own framing. Where a claim
contradicts what the routing docs say about themselves, the code wins.

**Design goal driving this doc (stated by the user):** the shape of the work - not habit, not
whoever is easiest to reach for - should determine the model used. This doc exists to name every
place that goal currently fails, precisely enough that a design session can act on it.

**Related:** issue #18 ("Reconcile the 'who routes, and on what basis' seam across loop-drive,
ringer, and the model-intel reference") named this same seam on 2026-08-10 at the idea level.
This doc is the detailed, code-verified version of that same problem, plus one finding #18 didn't
have: the coverage gap in Section 6.

---

## 1. The big picture

```
                         A UNIT OF WORK ARRIVES
                                  |
                                  v
                  +-------------------------------+
                  | Transport decision (per unit,  |
                  | never per wave)                |
                  | needs in-session tools / mid-  |
                  | flight continuation?           |
                  +---------------+-----------------+
                    yes  |                |  no (and ringer present)
                         v                v
              +--------------------+   +---------------------------+
              |   AGENT-TOOL       |   |         RINGER             |
              |   TRANSPORT        |   |         TRANSPORT          |
              | sonnet / opus /    |   | claude/haiku, claude-zai/  |
              | haiku, run as this |   | GLM, opencode/OpenRouter,  |
              | session's own      |   | via ./ringer.py            |
              | subagents          |   |                             |
              +---------+----------+   +--------------+--------------+
                        |                              |
                        | task_type IS recorded         | task_type IS recorded
                        | in the routing table          | in the manifest task
                        | ("so the choice is             |
                        |  legible" - SKILL.md:92)       |
                        |                              |
                        v                              v
              +---------------------+      +-------------------------------+
              | NO WRITE PATH to    |      | Runs via ringer.py            |
              | any evidence store. |      | resolved_task_model() =       |
              | ringer.py never     |      | task.model OR                 |
              | sees this run.      |      | engine.model_default.         |
              | (confirmed: ringer  |      | (ringer.py:9719-9726 -        |
              | only logs its own   |      | ringer NEVER substitutes a    |
              | engine invocations) |      | scoreboard model at run time. |
              +---------+-----------+      | The scoreboard is read-only.) |
                        |                  +---------------+---------------+
                        |                                  |
                        |                                  v
                        |                  +-------------------------------+
                        |                  | Attempt row appended to the   |
                        |                  | model log (JSONL + SQLite     |
                        |                  | mirror, ~/.ringer/ringer.db)  |
                        |                  +---------------+---------------+
                        |                                  |
                        |                                  v
                        |                  +-------------------------------+
                        |                  | ./ringer.py models            |
                        |                  |   --task-type <type>          |
                        |                  | = the POSTERIOR (tier 1 of    |
                        |                  | the routing chain)            |
                        |                  +---------------+---------------+
                        |                                  |
                        |                     read by next  | manually dropped by a
                        |                     orchestrator   | human running
                        |                     session        | `ringer.py models --json`
                        |                     (closes the    | > snapshots/ringer/drop/
                        |                     loop, but only  |
                        |                     for ringer-     v
                        |                     transported    +---------------------------+
                        |                     work)          | ai-benchmark               |
                        |                                     | snapshots/ringer/drop/     |
                        |                                     | ONE file on disk:          |
                        |                                     | RIT-UADV2213-2026-08-12    |
                        |                                     | .json - 13 days stale,     |
                        |                                     | one host, never refreshed  |
                        |                                     +-------------+---------------+
                        |                                                   |
                        |                                                   v
                        |                                     +---------------------------+
                        |                                     | config/roles.json feeds    |
                        |                                     | only 3 of ringer's task    |
                        |                                     | types into 3 of 9 roles:   |
                        |                                     | execution, coding, testing |
                        |                                     +---------------------------+
                        |
                        v
        +----------------------------------------------------+
        | Falls back to TIER 2: config/routing/               |
        | model-benchmarks.md prior table.                    |
        | Static, hand-dated rows. NOT keyed by task_type at  |
        | all - one "Best for" prose cell per model, covering |
        | every kind of work that model might do.             |
        | This is the ONLY tier that ever prices Agent-tool   |
        | work, and it never sees task_type.                  |
        +----------------------------------------------------+
```

**The one-sentence version:** the routing chain's live-evidence tier only ever fills from
ringer-transported work; Agent-tool transport - "the default execution worker on the Agent-tool
roster" per `config/routing/model-benchmarks.md:16` - has no write path to any evidence store, so
it can never promote itself
out of the static prior table no matter how much of it runs. The loop closes for the transport
used least and stays permanently open for the transport used most.

---

## 2. The three-tier routing chain, as documented

From `config/routing/model-benchmarks.md:26-41`:

1. **Scoreboard posterior** - `./ringer.py models --task-type <type>`, ringer-transport only.
2. **Benchmark prior** - the static tier table in the same file, used when a model has no local
   scoreboard evidence. This is the *only* tier Agent-tool units ever reach.
3. **Orchestrator pin** - explicit `engine`+`model` override for design/math/risk/taste units,
   always a human-legible reason, never "seems hard."

Distilled: *scoreboard posterior, else benchmark prior, else orchestrator pin.* Every skill that
routes a unit (`loop-drive`, `wayfinder`, `ringer-substrate`) points here rather than restating
it - that part of the architecture is genuinely clean, single-homed, no drift found.

---

## 3. `task_type`: the vocabulary with no definition

`task_type` is a plain string field on ringer's `TaskSpec` (`ringer.py:1644,1694-1696`). The only
validation is "must be a string" - no enum, no schema, no allowed-values check anywhere in the
codebase. Contrast this with `docs/TAXONOMY.md` in the ringer repo, which *is* a real normative
contract for model-identity terms (lab vs harness vs plan). Nothing equivalent exists for
task_type - there is no doc anywhere that says what distinguishes `code-feature` from
`code-fix`, or what `probe` versus `research` means in practice. The choice of type per unit is
entirely a human judgment call, unchecked.

Worse, the vocabulary loop-stack cites as "canonical" is stale against ringer's own usage:

| Value in loop-stack's stated list (`SKILL.md:91`, `ringer-substrate.md:19`) | Actually used in a ringer template | Actually used in a loop-stack plan |
| --- | --- | --- |
| `code-feature` | yes (`repo-feature`) | yes, most common |
| `code-fix` | yes (`fix-swarm`, `migration-swarm`) | yes, second most common |
| `code-review` | yes (`review-swarm`, `adversarial-review`) | yes (twice) |
| `docs` | yes (`doc-swarm`) | yes |
| `research` | yes (`research-with-proof`, `competitive-teardown`, bakeoff-kit) | no |
| `persona-review` | yes (`focus-group`, `launch-kit` round 2) | no |
| `site-build` | yes (`launch-kit`) | no (one mention, but describing another project's scoreboard rows, not a type this repo set) |
| `image-gen` | yes (`asset-swarm`) | no |
| `probe` | yes (`probe`) | yes (once) |
| `bakeoff` | yes (`bakeoff`) | no |
| *(not in loop-stack's list)* `copywriting` | yes (`launch-kit`) | no |
| *(not in loop-stack's list)* `motion-design` | yes (`asset-swarm`) | no |
| *(not in loop-stack's list)* `data-pipeline` | yes (`data-pipeline`) | no |
| *(not in loop-stack's list)* `test-hardening` | yes (`test-hardening`) | no |

Four real, template-backed task_types are missing from the list loop-stack calls canonical. The
list was never generated from ringer's actual template set; it was typed once and drifted.

---

## 4. How "trusted model status" actually works (the promotion ladder)

This answers the question directly: `./ringer.py models --task-type <type>` computes, per bucket,
one of three states.

```
   (engine, model, reasoning_effort, task_type) bucket
                     |
                     v
        +---------------------------+
        |  0 attempt rows            |
        |  = UNTESTED                |
        |  (not even displayed until |
        |   a first row lands, or    |
        |   surfaced via --explore   |
        |   as an untested catalog   |
        |   candidate)                |
        +-------------+---------------+
                       | first attempt logged
                       v
        +---------------------------+
        |  PROBATION                 |
        |  1-2 tasks, OR             |
        |  >=3 tasks but first-try   |
        |  pass rate < 2/3           |
        +-------------+---------------+
                       | tasks >= 3 (PROVEN_MIN_TASKS,
                       | ringer.py:3072)
                       | AND
                       | first_try_pass_rate >= 2/3
                       | (PROVEN_MIN_FIRST_TRY,
                       | ringer.py:3073)
                       v
        +---------------------------+
        |  PROVEN                    |
        +---------------------------+

   Side states, excluded from tiering entirely (never proven, never probation, never ranked):
   - UNATTRIBUTED: historical row with a blank model field (ringer.py: unattributed rows are
     quarantined per engine, "(unattributed legacy rows)").
   - MISROUTED: a historical row that reached the model through a declared-noncanonical
     engine/slug route (docs/TAXONOMY.md - e.g. an OpenRouter route to a model whose canonical
     route is a native CLI). Resolved to the correct model/lab for display, marked `misrouted`,
     assigned no tier.
   - RESERVED FIXTURE: rows for `proven-model`, `probation-model`, `mock-model`, `test-model` -
     reserved for tests, excluded from every real aggregation.
```

Three mechanics worth naming precisely, because they change what "trusted" means in practice:

- **Volume alone never proves a model.** The threshold is explicitly AND, not OR (comment at
  `ringer.py:7550-7551`: "volume alone never proves a model - a 0% pass rate with many tasks is
  evidence against, not for"). A model can run 50 tasks and still sit in probation forever if its
  first-try pass rate stays under 2/3.
- **Task-type scoping is opt-in, not default.** When you run `./ringer.py models` with no
  `--task-type` filter, the top-level `tier` badge (proven/probation) is computed on the model's
  aggregate pass rate across *every* task_type combined; the per-task_type breakdown table
  underneath shows raw stats (tasks, pass_rate, first_try_pass_rate) but carries **no tier of its
  own**. Only when you explicitly pass `--task-type <type>` does the aggregation filter to that
  type before computing tier (`aggregate_model_scoreboard_rows`, `ringer.py:7564-7589`). So a
  model can show "proven" overall while actually being probation-grade or untested on the
  specific task_type you're about to route - if nobody thinks to ask with the filter, the
  blended badge is what gets read.
- **Trust is retroactively adjustable.** A `check-bug` amendment (`ringer.py amend --reclassify
  check_bug`) reclassifies a failed attempt as a check defect rather than a model failure,
  removing it from the failed count on replay. This is legitimate (a bad check shouldn't
  convict a model) but it means "proven" is a computed-at-query-time judgment, not a permanent
  fact - a currently-open example is glm-5.2's depressed posterior from seven pending stm-nav
  amendments (`docs/AMENDMENTS-PENDING.md`), meaning its true tier is presently understated until
  those land.

**On the specific hypothesis "ringer overrides the model chosen for the task based on its
scoreboard": checked, and false as coded.** `resolved_task_model()` (`ringer.py:9719-9726`) is
`task.model or engine.model_default` - full stop. `models --task-type` is a separate, read-only
report subcommand; nothing in `run` ever consults it or substitutes a model into a manifest. If
the model that actually ran didn't match what the evidence would have recommended, that is a
human/orchestrator process failure at manifest-drafting time, not a ringer mechanism acting behind
anyone's back. Worth being precise about, because it puts the fix in the drafting step, not in
ringer's execution path.

---

## 5. Templates designed for task types, never used by loop-drive

`ringer/templates/*/manifest.json` hardcode a correct task_type per swarm pattern - choosing the
pattern chooses the type correctly, for free:

| Template | task_type baked in |
| --- | --- |
| `repo-feature` | `code-feature` |
| `fix-swarm`, `migration-swarm` | `code-fix` |
| `review-swarm`, `adversarial-review` | `code-review` |
| `doc-swarm` | `docs` |
| `research-with-proof`, `competitive-teardown` | `research` |
| `focus-group`, `launch-kit` (round 2) | `persona-review` |
| `launch-kit` (round 1/3) | `copywriting`, `site-build` |
| `asset-swarm` | `motion-design`, `image-gen` |
| `probe` | `probe` |
| `bakeoff` | `bakeoff` |
| `data-pipeline` | `data-pipeline` |
| `test-hardening` | `test-hardening` |

`loop-drive/SKILL.md` and `ringer-substrate.md` never mention `templates/` once. They use the word
"template" for something unrelated - the prompt paste-blocks converted in Step 4
(`SKILL.md:63,123`). loop-drive always hand-authors a fresh manifest from scratch and asks the
orchestrator to pick a task_type by judgment, instead of drawing from the dozen patterns that
already encode a correct type-to-work mapping.

---

## 6. The structural coverage gap (the biggest finding, not in issue #18)

Transport is chosen per unit, never per wave, and the two transports are mutually exclusive
(`ringer-substrate.md`). Only ringer-transported units ever write an attempt row to the model log.
Agent-tool units - sonnet/opus/haiku run as this session's own subagents, "the default execution
worker on the Agent-tool roster" per `model-benchmarks.md:16` - **never touch `ringer.py` and can
never produce a scoreboard row, by construction**, no matter how many of them run. `SKILL.md:92`
asserts "task_type drives scoreboard routing and must be set even for Agent-tool units" - but
there is no scoreboard for Agent-tool units to route by; recording task_type there is
documentation, not routing. This is the structural reason the routing apparatus stays
evidence-poor no matter how often it's used: the volume of work is going through the transport
that structurally cannot feed the loop back.

---

## 7. ai-benchmark: not stale everywhere, but the ringer bridge is

Checked directly (not from memory): `ai-benchmark`'s `model_intel/` pipeline is real, tested,
stdlib-only, and *is* actively refreshable - live AA and Nate snapshots dated 2026-08-25 were
sitting uncommitted in the repo at the time of this check, meaning it was run today. Two of its
three sources are healthy.

The third source, the ringer bridge, is not:

- `config/roles.json` already wires ringer buckets into the role view - `execution` feeds on
  `ringer:code-feature` + `ringer:docs`, `coding` on `ringer:code-feature` + `ringer:code-fix`,
  `testing` on `ringer:code-fix`. The integration point genuinely exists.
- `snapshots/ringer/drop/` contains exactly one file: `RIT-UADV2213-2026-08-12.json` - 13 days
  stale relative to this session, from one host, never re-dropped since, and this repo's host has
  never contributed a drop at all.
- Only 3 of the ~14 task_types in circulation (`code-feature`, `code-fix`, `docs`) feed anything
  into ai-benchmark's role view. `research`, `persona-review`, `site-build`, `image-gen`,
  `bakeoff`, `probe`, `copywriting`, `motion-design`, `data-pipeline`, `test-hardening` have zero
  linkage to model intelligence data anywhere in either repo.

---

## 8. Three taxonomies, not talking to each other

```
   RINGER task_type              LOOP-STACK prior-tier            AI-BENCHMARK role-view
   (14 values, no shared         tiers                             (9 roles: brainstorming,
    definition doc)              (Frontier / Strong / Fast /       design, planning,
                                   Specialty - config/routing/      orchestration, execution,
   code-feature   code-fix        model-benchmarks.md)             coding, evals, writing,
   code-review    docs                                             testing - config/roles.json)
   research       persona-review  Not keyed by task_type at
   site-build     image-gen       all - one prose "Best for"       Only 3 roles (execution,
   probe          bakeoff         cell per model, covering         coding, testing) ingest
   copywriting    motion-design   every kind of work.               ANY ringer signal, and
   data-pipeline  test-hardening                                    only 3 of the 14
                                                                     task_types feed them.
        |                                  |                                |
        | (ringer scoreboard reads         | (Agent-tool units land         | (bridge is one
        |  task_type directly, but         |  here permanently - no        |  stale, single-host
        |  only ringer-transport           |  path out no matter how       |  manual snapshot
        |  work ever reaches it)           |  much evidence accrues)       |  drop away)
        v                                  v                                v
   Real per-type evidence,           Real fallback, but              Real capability data,
   but coverage-limited to           blind to task_type               but only reachable for
   the minority transport            entirely                        3 of 14 shapes of work
```

None of these three vocabularies map onto each other. A task_type set in a ringer manifest has no
defined relationship to a loop-stack tier or to an ai-benchmark role; the only connective tissue is
the narrow, stale, three-type-wide bridge in Section 7.

---

## 9. Net assessment

| Claim examined | Verdict | Where the evidence lives |
| --- | --- | --- |
| Task type chosen without regard to model fit | **Confirmed**, and worse than framed: only the posterior tier is type-aware, and it only fills from a minority of transport | Sections 1, 2, 6 |
| Task type chosen without regard to what it means | **Confirmed**: no definition doc; loop-stack's own vocabulary list is already stale against ringer's real usage | Section 3 |
| Templates built for task types, ignored by loop-drive | **Confirmed**: zero mentions of `templates/` in loop-drive's routing skills | Section 5 |
| Ringer overrides the chosen model from its own scoreboard | **Refuted**: `resolved_task_model()` never reads the scoreboard; it is `task.model or engine.model_default` only | Section 4 |
| ai-benchmark is fragmented and not refreshable | **Half true**: AA/Nate sources refresh fine and were refreshed today; the ringer bridge is the one genuinely stale, single-host, narrow-coverage piece | Sections 7, 8 |
| The apparatus is stale and mostly driven by manual model choice | **Confirmed, with a structural cause**: Agent-tool transport (the majority of actual work) has no write path to any evidence store at all, so no amount of usage self-corrects it | Section 6 |

---

## 10. Open design questions (not a plan - the decisions a design session needs to make)

Named, not answered, per the goal stated at the top: the shape of the work should determine the
model.

1. **Coverage:** should Agent-tool transport gain a write path into ringer's model log (even a
   thin one - log the attempt without ringer owning execution), or should the routing chain accept
   that Agent-tool work will only ever route on the static prior, and instead invest in making that
   prior richer and more current instead of live?
2. **Vocabulary:** does task_type need an owned definitions doc analogous to `docs/TAXONOMY.md`,
   and does loop-stack's routing skills need to read ringer's actual template set as the source of
   truth instead of a hand-typed list that already drifted?
3. **Templates:** should loop-drive's manifest-drafting step check ringer's `templates/` library
   for a matching pattern before hand-authoring a task_type and spec from scratch?
4. **Prior tier granularity:** should `config/routing/model-benchmarks.md` grow a task_type
   dimension (a model-x-type matrix) instead of one prose "Best for" cell per model, so the tier
   fallback that Agent-tool work permanently lives in is actually shape-aware?
5. **The ai-benchmark bridge:** who owns keeping `snapshots/ringer/drop/` current and
   multi-host, and should `config/roles.json` extend its `ringer:*` feeds to more than 3 of the 14
   task_types, or is 9 roles the wrong shape to unify with 14 task_types in the first place?
6. **Which layer decides:** issue #18's original framing - loop-drive by type, ringer by
   trust/performance, ai-benchmark by capability/cost/access - still stands as the central
   question. This doc adds that a fourth axis, transport, silently gates which of those three
   signals a given unit can ever benefit from before the other three questions are even asked.

---

*Evidence discipline: every file:line citation above was read in this session on 2026-08-25;
every count (snapshot dates, template list, vocabulary usage) was grepped, not recalled. Numbers
describing "today" reflect this session's clock and will drift the moment more ringer runs or
ai-benchmark refreshes land - treat the specific staleness figures (13 days, one host, 3 of 14) as
a dated snapshot of the gap's shape, not a permanent measurement.*
