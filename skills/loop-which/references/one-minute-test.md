# The One-Minute Test

Source: https://unlock-ai.natebjones.com/guides/the-one-minute-test
By Nate B. Jones (Unlock AI)

Most AI mistakes are routing mistakes.
The One-Minute Test helps you sort the task before you start.

Describe the job, set the sliders, and use the verdict to choose the lightest tool that can do the work while leaving you with a result you can inspect.
The tool routes a task to CHAT, ONE AGENT, AGENT TEAM, or DON'T BOTHER.
The point is not a magic classifier; it is a fast check on the shape of the work.

## 01 / Four routes

### CHAT is for narrow answer work.
Use chat when the source material fits in the prompt, the task is answer-only, and you can review the result directly.
Meeting-note summarization is the demo case: one transcript, one narrow output, and no app action.
Chat is not the weak option.
It is the clean option when the job is small enough to do in one exchange.

### ONE AGENT is for one goal with tools.
Use one agent when the job has one clear goal, needs a tool, folder, or app action, and can still be checked by one person.
The gym-slot scheduling demo needs calendar access and a clear done state, not a group of agents debating the strategy.
The core pattern is one goal, one loop, and a visible result.

### AGENT TEAM is for separable work with checks.
Use an agent team when the work is too large for one pass, splits cleanly across sources or roles, and the outputs can be checked against citations, tests, or explicit acceptance rules.
The weekly deck earns a small named team because gathering, drafting, gap-checking, and formatting are real separate parts.

### DON'T BOTHER protects your time.
Use don't bother when AI could technically help, but the setup is not earned, the final judgment is not cheap to check, or the work is too sensitive for casual automation.
The tax-folder demo has an AI shape, but it is rare, sensitive, and still needs careful human review.

## 02 / Seven questions

The interface has six sliders: the four estimates plus the two money dials.
The human version adds judgment and access and consequence - seven questions in all: size, independence, separation, checkability, judgment, access and consequence, and whether the payoff earns setup.

### How much source material has to stay in view?
A single meeting transcript can fit in chat.
Last quarter's inbox cannot.
Large jobs force compression or division, so many documents, threads, or source areas make a team more plausible.
If it fits in one prompt, start with chat.

### Can useful parts proceed in parallel?
Reading a pile of documents can split well because one reader per document can gather notes independently.
Most coding changes do not split as cleanly because each change depends on the current state of the repo.
If every worker needs the same full context and constant synchronization, one agent or one person is usually better.

### Does any step need a fresh mind?
Some work gets worse when the same model both makes and judges the output.
A draft benefits from a critic who did not write it.
A weekly deck benefits from a reviewer who checks gaps before it ships.
Separation is not the same as parallelism, but it can justify a team when the check is explicit.

### Is checking cheaper than producing?
A source citation, test suite, acceptance rule, invoice total, or calendar conflict check makes AI work safer because verification is cheaper than generation.
Taste-only work fails this test because judging the answer costs about as much as making it.

### How much is judgment doing?
Low-judgment work routes to agents more easily: collect forms, find renewal dates, compare usage to invoices, or summarize source notes.
High-judgment work should stay with a person or be narrowed until the AI part is clearly support work.

### Do the access, consequence, calendar, and payoff earn setup?
A pasted note is different from private files.
A calendar action is different from account or money risk.
Access is not automatically bad, but tool access earns its keep only when the done state is clear.
Frequency and value matter too: daily and weekly jobs get more room, while rare low-value chores usually do not.

## 03 / What happens next

The verdict matters only if it changes what you do next.
Each route has a practical follow-up shape.

### If the verdict is CHAT, use a narrow prompt.
Use normal Claude or ChatGPT.
Paste the task and source material together, ask for one output, and require assumptions plus anything you should verify before using it.
Review the answer yourself before it goes anywhere.

```
<prompt>
  <task>
    I need help with this task:

[PASTE TASK]

Use only this source material:

[PASTE SOURCE]

Return:
1. The answer
2. Assumptions
3. Anything I should verify before using it
  </task>
</prompt>
```

### If the verdict is ONE AGENT, write the run card first.
Use Open Skills or one accountable runbook.
The one-agent rule is accountability: do not give it a vague mission.
Give it a finish line and a check.

```
<prompt>
  <task>
    Goal: [one sentence describing the finished outcome]
Done state: [the file, message, decision, booking, or update exists and can be inspected]
Tools: [only the folder, app, calendar, or API needed for the run]
Cap: [one pass, time limit, or stop condition]
Check: [source, rule, test, calendar state, acceptance note, or human review]
  </task>
</prompt>
```

### If the verdict is AGENT TEAM, keep the team small and named.
Use Ringer or a small named team.
Add roles only when the work demands them.
The weekly deck can use gather, draft, gap-check, and format; the tool-cost audit can split contracts, invoices, usage, and renewals.

```
<prompt>
  <task>
    Reader: gathers facts from one source area and cites where each claim came from.
Synth: combines the reader notes into the business output.
Reviewer: checks gaps, source support, and acceptance rules.
Gate: a human approves the reviewed output before it ships or changes anything.
  </task>
</prompt>
```

### If the verdict is DON'T BOTHER, take the manual path.
Make a short checklist and work through the task directly.
If taste or strategy is the hard part, ask one trusted person for a second read.
If the task starts recurring, rerun the gut-check with the new frequency and value.

## 04 / Don't bother

Some agent-shaped tasks still should not become agent work.
The tool is useful because it refuses plausible automation when setup, sensitivity, checkability, or judgment make the economics wrong.

### Tax folder organization has shape but not enough payoff.
It has files, missing-item checks, and obvious busywork.
It still routes to DON'T BOTHER because the task is rare, sensitive, and still needs careful human review.
You do not save enough repeated effort to justify a casual automation path through tax documents.

### Product naming makes generation cheap, not judgment cheap.
Naming feels like something a swarm should solve because generating options is easy.
The tool routes it to DON'T BOTHER because judging the winner is the actual work.
More agents create a larger pile of fluent options, but they do not make the final call cheaper.

### New dishwasher research does not earn a swarm.
Consumer research can look splittable across reviews, prices, models, and delivery windows.
For a rare, low-value purchase with weak checkability and mixed judgment, a swarm adds coordination cost before it adds leverage.
Use search, ask chat for a comparison if you want, then choose.

## 05 / Run it yourself

Start with work that is actually on your desk.
Do not overthink the sliders; give each question your best honest answer and inspect the verdict, reasons, and cost/payoff line.

Run one real task through the tool.
If the verdict surprises you, look for the slider that created the surprise.
Usually the task is less checkable than it felt, the calendar does not earn setup, or the work needs one accountable agent rather than a team.

**You do:** Describe the task and answer the sliders honestly.

**The AI does:** Routes the task to chat, one agent, agent team, or don't bother and shows the reasons.

Pick the lightest tool that leaves an inspectable result.
That is the skill: sort the task first, then choose the lightest tool that can do the job and still leave you with a result you can inspect.

Live tool: https://unlock-ai.natebjones.com/guides/the-one-minute-test#run-it-yourself
