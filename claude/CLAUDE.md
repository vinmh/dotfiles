# Global Instructions

*NOTE*: If there are conflicting or incorrect information here, notify the user and propose changes.

## Interaction Style

You are working alongside a human. Communicate what's happening and ask before proceeding on ambiguous tasks. Defer to the user for final decisions, ambiguous situations, and complexity evaluation. Admit knowledge gaps.

**Ask for confirmation when:**
- Multiple valid approaches exist
- Writing significant code without clear requirements
- Solution fights framework conventions or requires meta-programming

## Spelling & Naming

- Documentation, git commits, code comments: Canadian spelling (colour, behaviour, centre)
- Code identifiers: American spelling (color, behavior, center)
- **Forbidden names**: "improved", "new", "enhanced", "updated", "v2", "refactored" — use descriptive, timeless names (`jsonParser` not `newParser`)

## Writing Style

- Clear, direct language; admit uncertainty explicitly
- **Forbidden claims**: "robust", "thorough", "comprehensive", "production ready"
- No temporal references in code comments ("recently changed", "new implementation")

## Testing

**MANDATORY** — always write unit, integration, and end-to-end tests. No exceptions.
- Tests must cover implemented functionality with pristine output
- Never ignore test output/logs; capture and test expected errors
- Never write workarounds to pass tests — investigate root causes

## Development Efficiency

- Skip redundant steps: don't run tests you know will fail (e.g. before implementation in TDD)
- Make the smallest reasonable changes; modify existing code, don't rewrite
- Permission required for: reimplementing from scratch, large refactors, architectural changes

## Verification Discipline

Before declaring any task done:
1. Re-read the original request — check every part of it is addressed, not just the part that was interesting
2. Run the changed code path (tests, build, or the app itself) and report actual output, not expectations
3. If anything was skipped or failed, say so plainly — never present unverified work as done

When debugging: reproduce first, fix second. Never fix a bug you haven't seen fail, and re-run the reproduction after the fix.

## Context Economy

Rate limits are a real constraint in this setup. Spend context deliberately:

- Delegate broad "where is X / what touches Y" searches to the `scout` agent (Haiku) instead of searching inline
- Use `swiss-knife file-outline` before reading any file over ~200 lines; then read only the relevant ranges
- Batch independent tool calls in one message; batch related shell commands into one compound command
- Never re-read files already in context; never dump file contents into responses
- When context passes ~70% (see statusline), suggest `/handoff` to persist state before quality degrades

## Multi-Session Workflow

Durable files, not conversation memory, carry work across sessions:

- Multi-phase work lives in `.claude/PLAN.md` — execute via `/phase`, one verified phase at a time
- Before `/clear`, `/compact`, or stopping mid-task: `/handoff` writes state to `.claude/HANDOFF.md`; at session start, check for one and resume from it
- Before implementing a non-trivial plan: `/plan-review` (spawns the `architect` agent on Opus)
- After completing significant code: spawn the `code-reviewer` agent on the diff before committing
- Treat memory and handoff claims as stale until verified against git/filesystem — memory has previously claimed phases complete in an empty repo

## Shell Gotchas (this machine)

Learned the hard way in past sessions — do not relearn these:

- zsh globbing: quote or isolate arguments containing `=`, `*`, or `--include=*.ext` (`echo ===` fails with "not found"); when a compound command fails oddly, split it
- `grep` is aliased to ugrep, which rejects GNU alternation syntax — use `command grep` when GNU semantics matter, or the Grep tool
- Never `pkill -f`/`pgrep -f` — self-matching has killed the session shell (exit 144) and produced phantom PIDs. Use `swiss-knife proc find|stop` instead; it excludes the invoking shell chain by construction
- `cd` persists across `&&` within a call and leaks into later commands — use absolute paths
- Edit/Write require a prior Read in the current session; this resets after compaction. Read files before editing; don't inspect-with-`cat` files you intend to edit
- Long-running commands: use `swiss-knife run-logged` — pipes block on full buffers, quiet flags hide fatal errors (Hugo writes them to stdout), and `producer | grep -q` under pipefail dies of SIGPIPE with a false failure
- Waiting on ports/files/processes: use `swiss-knife wait-for` — hand-rolled watcher loops have run for 28 hours on permanently-false conditions (`-newermt` freshness windows expire)
- `swiss-knife file-outline` JSON key is `.symbols[]` (not `.items[]`)
- When a complex shell command will recur and trips permission analysis (expansions, inline scripts), propose compiling it into a project helper script (`scripts/` pattern) — reduces both tokens and permission prompts

## Tools

- **GitHub**: Use `gh` CLI
- **Bitwarden**: Use `bw` CLI
- **swiss-knife**: CLI toolkit for common tasks. Prefer these over multiple tool calls:
  - `swiss-knife file-outline <path>` — Get file structure (functions, classes, signatures, line numbers) without reading the full file. Use this instead of reading entire files when you only need to understand structure. Supports: Python, JS/TS, Go, Rust, C.
  - `swiss-knife commit-context --repo <path>` — Get staged diff, branch info, untracked files, and recent log in one call. Use this instead of running separate git commands when preparing commits or PRs. Options: `-n <count>` for log entries.
  - `swiss-knife test-summary <command...>` — Run tests and get structured JSON results (passed/failed/skipped/failures with file:line). Use this instead of running test commands directly when you need to parse results. Auto-detects framework; override with `--framework <name>`. Supports: pytest, jest, vitest, go test, cargo test, rspec, Unity (C).
  - `swiss-knife proc find|stop <pattern>` — Find or terminate processes by command-line pattern. ALWAYS use this instead of `pkill -f`/`pgrep -f`: it can never match the invoking shell, reports listening ports and process age, and confirms each kill.
  - `swiss-knife wait-for [--port N] [--file P] [--touched P] [--gone PAT] [--present PAT] [--http URL] -t SECS` — Poll until conditions hold. Use this instead of hand-rolled `until ...; sleep` loops and foreground sleeps; it always terminates.
  - `swiss-knife run-logged [--timeout S] [--grep RE] [--] <command...>` — Run a command with stdout+stderr captured to a log file; returns exit code, tail, and grep matches. Use for builds/servers/long commands instead of pipes (`cmd | grep -q` under pipefail gives SIGPIPE false failures; pipe buffers block). Put `--` before commands with their own flags.
  - `swiss-knife session-brief` — One call bundling git state, HANDOFF.md, PLAN.md phase statuses, and the project memory index. Run at session start or after compaction instead of separate git/file reads.
  - All commands output JSON to stdout. Exit 0 = success, 1 = negative outcome (test failures, wait-for timeout, non-zero command, kill survivors), 2 = error (with `{"error": "..."}`).
# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.
