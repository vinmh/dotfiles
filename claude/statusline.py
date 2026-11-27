#!/usr/bin/env python3
"""Statusline for Claude Code: model | dir | git branch | context usage.

Reads the session JSON from stdin. Context usage is derived from the last
assistant message's token usage in the transcript JSONL.
"""
import json
import os
import sys

CONTEXT_WINDOW_DEFAULT = 200_000

DIM = "\033[2m"
RESET = "\033[0m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
CYAN = "\033[36m"
MAGENTA = "\033[35m"


def git_branch(cwd):
    """Read .git/HEAD directly; avoids spawning git."""
    d = cwd
    while d and d != "/":
        head = os.path.join(d, ".git", "HEAD")
        if os.path.isfile(head):
            try:
                with open(head) as f:
                    ref = f.read().strip()
                if ref.startswith("ref: refs/heads/"):
                    return ref[len("ref: refs/heads/"):]
                return ref[:8]  # detached HEAD
            except OSError:
                return None
        # .git may be a file (worktrees)
        gitfile = os.path.join(d, ".git")
        if os.path.isfile(gitfile):
            try:
                with open(gitfile) as f:
                    gitdir = f.read().strip().removeprefix("gitdir: ")
                head = os.path.join(gitdir, "HEAD")
                if os.path.isfile(head):
                    with open(head) as f:
                        ref = f.read().strip()
                    if ref.startswith("ref: refs/heads/"):
                        return ref[len("ref: refs/heads/"):]
                    return ref[:8]
            except OSError:
                return None
        d = os.path.dirname(d)
    return None


def context_tokens(transcript_path):
    """Latest assistant-message usage from the transcript tail."""
    try:
        size = os.path.getsize(transcript_path)
        with open(transcript_path, "rb") as f:
            f.seek(max(0, size - 262_144))
            tail = f.read().decode("utf-8", errors="ignore")
    except OSError:
        return None
    for line in reversed(tail.splitlines()):
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue
        if entry.get("isSidechain"):
            continue
        usage = entry.get("message", {}).get("usage") if isinstance(entry.get("message"), dict) else None
        if usage and "input_tokens" in usage:
            return (
                usage.get("input_tokens", 0)
                + usage.get("cache_read_input_tokens", 0)
                + usage.get("cache_creation_input_tokens", 0)
            )
    return None


def main():
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        data = {}

    parts = []

    model = data.get("model", {}).get("display_name") or "?"
    parts.append(f"{MAGENTA}{model}{RESET}")

    cwd = data.get("workspace", {}).get("current_dir") or data.get("cwd") or os.getcwd()
    parts.append(f"{CYAN}{os.path.basename(cwd) or cwd}{RESET}")

    branch = git_branch(cwd)
    if branch:
        parts.append(f"{DIM}{branch}{RESET}")

    transcript = data.get("transcript_path")
    if transcript:
        used = context_tokens(transcript)
        if used is not None:
            window = 1_000_000 if "[1m]" in str(data.get("model", {}).get("id", "")) else CONTEXT_WINDOW_DEFAULT
            pct = 100 * used / window
            colour = GREEN if pct < 60 else YELLOW if pct < 80 else RED
            parts.append(f"{colour}ctx {pct:.0f}%{RESET}")

    cost = data.get("cost") or {}
    added = cost.get("total_lines_added")
    removed = cost.get("total_lines_removed")
    if added or removed:
        parts.append(f"{DIM}+{added or 0}/-{removed or 0}{RESET}")

    print(f" {DIM}|{RESET} ".join(parts))


if __name__ == "__main__":
    main()
