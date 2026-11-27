---
name: handoff
description: Persist session state to .claude/HANDOFF.md so work survives /clear, /compact, rate-limit pauses, and model switches. Use before ending a session mid-task, when context is getting full, or at the start of a session to resume from a previous handoff. Invoke with "resume" to load state instead of saving it.
---

# Session Handoff

Context is lossy: compaction summarizes, /clear erases, rate limits interrupt. This skill makes the durable file on disk — not the conversation — the source of truth for in-flight work.

## Mode: save (default)

Write `.claude/HANDOFF.md` in the project root (create `.claude/` if needed). Overwrite any existing handoff — it describes a moment, not a history. Structure:

```markdown
# Handoff — <one-line goal>
Updated: <ISO date/time>

## State
What is DONE and verified (with how it was verified), what is IN PROGRESS
(exact stopping point: file, function, what's half-finished), what is NOT STARTED.

## Next step
The single concrete action to take first on resume. Specific enough to
execute without re-deriving anything: file, change, command to run.

## Decisions
Choices made this session with one-line rationale each. These are settled —
a future session must not re-litigate them.

## Gotchas
Anything discovered the hard way: commands that fail and why, misleading
code, environment quirks, things that look broken but aren't.

## Files touched
Path — one-line description of the change. Uncommitted work flagged.
```

Rules:
- Write for a reader with zero conversation context. No "as discussed above", no shorthand invented mid-session.
- Record only what cannot be re-derived from the code or git log. The diff shows *what* changed; the handoff records *why* and *what's next*.
- Keep it under ~80 lines. A handoff nobody reads is worse than none.
- If `.claude/HANDOFF.md` would be committed (check .gitignore), that is usually fine — it documents project state — but flag it to the user if the repo is public.
- After writing, tell the user the handoff is saved and it is safe to /clear.

## Mode: resume

When invoked as `/handoff resume` (or at session start when a handoff exists):

1. Run `claude-tools session-brief` — it returns the handoff content, git state, and plan phase statuses in one call.
2. Verify the handoff's claims against that git state before trusting them; check that files mentioned exist in the described state. The handoff may be stale.
3. Summarize to the user: the goal, what's done, and the recorded next step. Ask nothing that the handoff already answers.
4. Proceed with the next step unless the user redirects.
