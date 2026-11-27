---
name: ui-workflow
description: The process for designing and building UI with the user in rounds — user flow, skeleton, conversion to existing elements, new elements, animation, then live test-and-iterate — with a gate at each step and a fast preview loop. Use when planning or running any UI phase, screen, redesign or mockup, or when the user says "let's do the UI", "plan the screens", "mockup", "design round". Complements frontend-design (which covers aesthetic direction): this skill covers how the work moves and when the user decides.
---

# UI workflow

The user owns the visible product. Your job is to move a design from "what does the user do" to
"shipped and checked" in small rounds, putting each decision in front of them at the right moment
and never inventing visual direction they haven't given. Aesthetic guidance lives in the
`frontend-design` skill and in the project's design system doc; this skill is the process.

## Before starting

1. Read the project's design system doc (e.g. `docs/ui_design.md`) and any UI process notes it
   keeps (e.g. `docs/ui_process.md`): tokens, components, motion rules, conformance checklist.
2. Check the **preview loop**. A round must take seconds, not a rebuild: a dev server with hot
   reload, against a running backend or seeded data, reachable where the user reviews (their
   phone, a tailnet URL). If the project has none, say so and propose one before designing
   anything: rebuilding and restarting a whole environment per tweak makes rounds clunky and the
   user stops iterating.
3. Get **data for every state** the screens show: seed scripts or fixtures for empty, typical,
   crowded, error, and the rare states (pending, unconfirmed, conflict). A state you can't produce
   is a state nobody reviews.

## The steps

Run them per journey (one flow end to end), not per screen across the whole app. Each step ends at
a gate; don't start the next until the gate is passed or the user waives it.

| # | Step | You produce | Gate |
|---|---|---|---|
| 1 | **User flow** | Each journey as numbered steps: entry point, what the user sees, what they do, what changes, every state (empty, loading, error, partial, permission-limited), and who may see what | The user agrees on the journeys and what's out |
| 2 | **Skeleton** | Bare layout on real or seeded data: placement and hierarchy only, no styling | Screenshots at phone and wide widths; the user picks the layout |
| 3 | **Conversion to elements** | A table, block → existing component or token; reuse first | Optional review; flag every block with no fit |
| 4 | **New elements** | Only for the blocks with no fit: options shown live, then built into the shared component layer and written into the design system doc (and a decision record if the project keeps them) | The user approves each new element |
| 5 | **Animation** | Motion from the motion tokens, proportional to what moves, reduced-motion and effects settings respected, nothing moving under content that's being read or streamed | Mid-motion screenshots and timing checks; the user sees it live |
| 6 | **Test and iterate** | Live rounds on the user's notes; then code review, end-to-end/browser checks extended for the journey, accessibility pass, commit | The user calls it done ("diminishing returns") |

## Running a round

- **Small rounds.** A round is one batch of the user's notes. Apply them, check them yourself,
  then hand back. Don't bundle your own unrequested ideas into a round; offer them separately.
- **Check before handing back.** Screenshots at a narrow phone width (emulated), a mid width and a
  wide one, plus mid-motion frames when motion changed. Look at them: clipping, overflow, touch
  targets under ~44–48 px, text that wraps badly, focus visibility.
- **Proportional, not pixels.** Sizes from tokens and grid cells; motion distances as shares of
  what moves. Hard-coded pixel values are a smell; the user's screens vary.
- **References beat descriptions.** When the user has references (screenshots, sites, a folder of
  images), study them and name what you take from each.
- **Try, show, drop.** An idea that doesn't land after one look is dropped, not tuned for three
  rounds. Note it so it isn't tried again.
- **Record as you go.** Each settled choice goes into the design system doc in the same round, not
  at the end. New shared pieces go into the shared component layer, never forked per screen.
- **Don't disturb the review.** Anything that resets data or restarts what the user is looking at
  (browser regression suites, resets) runs only before a commit, never mid-review.

## Gaps to name, always

Say plainly what wasn't checked: real devices (touch, fonts, address bars, keyboards), platforms
not built (native vs web), screen readers, real data volumes. Put them in the plan's notes as open
checks, not in a footnote.

## Output at the end of a phase

- The journeys as built, the elements added, the design doc and decision updates.
- Screenshots of the final state at each width (or where to find them).
- The checks that run, their results, and the open gaps above.
