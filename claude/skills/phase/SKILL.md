---
name: phase
description: Execute the next phase of a persisted project plan (PLAN.md or .claude/PLAN.md), fully verified, then stop at the phase boundary. Use for multi-phase projects where phases run across sessions — "do phase 3", "next phase", "what's the plan status". Also creates the plan file when asked to persist a plan.
---

# Phased Plan Execution

The plan file on disk is the contract. Conversations get compacted; the plan file carries phase status, decisions, and scope across sessions and models.

## Finding the plan

Look for, in order: `.claude/PLAN.md`, `PLAN.md`, then any `*plan*.md` in the project root or `.claude/` or `docs/`. If several exist, ask which one governs. If none exists and the user asked to persist a plan, create `.claude/PLAN.md` using the format below.

## Plan file format

```markdown
# Plan — <goal in one line>

## Phase N: <name> — [pending|in progress|done <date>]
Goal: what must be true when this phase is done.
Verify: the observable check that proves it (command, URL, behaviour).
Steps:
- [ ] concrete step
Notes: (filled in on completion — deviations from plan, gotchas found)
```

Every phase MUST have a `Verify:` line. A phase that cannot be verified independently is two phases glued together — split it.

## Executing a phase (`/phase` or `/phase N`)

1. **Read the plan file.** Report status: which phases are done, which is next. If asked only for status, stop here.
2. **Re-scope before building.** Read the phase's steps against the current code — earlier phases or side work may have changed assumptions. If the phase as written no longer makes sense, say what changed and propose the amendment before proceeding.
3. **Implement the phase.** Smallest reasonable changes. Write the tests the phase's functionality needs (unit/integration/e2e per project convention) — this is mandatory, not optional.
4. **Run the phase's `Verify:` check** and the test suite (`claude-tools test-summary <command>` for structured results). Do not mark a phase done on the strength of "the code looks right".
5. **Update the plan file:** mark the phase done with today's date, check off steps, and fill in `Notes:` with any deviation from the written plan and anything the next phase needs to know.
6. **Stop at the boundary.** Report what was done and what the next phase is. Do not roll into the next phase without being asked — phase boundaries are where the user reviews.

## Rules

- Never delete or rewrite pending phases without asking; amending scope is the user's call.
- If a phase fails verification, the phase stays not-done. Record the failure in Notes and report it plainly.
- Keep the plan file as the single source of truth: if the user changes direction mid-phase, update the plan file in the same turn.
