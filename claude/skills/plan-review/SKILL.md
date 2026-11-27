---
name: plan-review
description: Sanity-check a plan or architecture before implementation starts — hidden complexity, simpler alternatives, framework fights, wrong phase ordering. Use when a plan/design exists and the user wants it reviewed before building ("is this plan sane", "review the architecture first").
---

# Plan Review

Catch the week-costing mistake before any code exists. This review happens at the plan level; it is not a code review.

## Process

1. **Locate the plan.** `.claude/PLAN.md`, `PLAN.md`, a named design doc, or the plan as stated in conversation. If the plan exists only in conversation, first persist it to `.claude/PLAN.md` (see the phase skill's format) — un-persisted plans do not survive compaction.
2. **Spawn the `architect` agent** with: the plan file path, the goal in one sentence, known constraints (deployment target, framework, deadlines), and instructions to read the actual code the plan touches. The architect runs on Opus with a structured interrogation checklist; do not do the review inline in the main thread.
3. **Relay the verdict** — *sound / sound with amendments / rework needed* — with the findings, most consequential first. Distinguish blocking findings from preferences, as the architect does.
4. **Apply accepted amendments to the plan file** once the user decides, so the plan on disk always reflects the reviewed state. Do not start implementing; that is the phase skill's job.

## Rules

- Never skip step 2 by reviewing inline "to save time" — the point of this skill is a fresh, structured pass uncontaminated by the planning conversation.
- If there is genuinely no plan to review, say so and offer to draft one instead of reviewing vibes.
