#!/usr/bin/env bash
# One-time setup on a new machine: clone this repo anywhere, then run
#   ./scripts/setup.sh
# It creates the symlinks from the live config locations into this repo —
# the repo IS the live config. Idempotent: correct symlinks are left alone;
# real files/dirs found in the way are moved aside (suffixed .pre-dotfiles),
# never deleted.
set -euo pipefail
DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"

link() { # link <live-path> <repo-target>
	local live="$1" target="$2"
	if [ -L "$live" ]; then
		if [ "$(readlink "$live")" = "$target" ]; then
			echo "ok      $live"
			return
		fi
		rm "$live"
	elif [ -e "$live" ]; then
		mv "$live" "$live.pre-dotfiles"
		echo "backed up $live -> $live.pre-dotfiles"
	fi
	ln -s "$target" "$live"
	echo "linked  $live -> $target"
}

mkdir -p "$HOME/.config" "$HOME/.pi/agent" "$HOME/.claude"

link "$HOME/.config/nvim" "$DOTFILES/nvim"
link "$HOME/.zshrc" "$DOTFILES/zsh/.zshrc"
link "$HOME/.config/ghostty" "$DOTFILES/ghostty"
link "$HOME/.pi/agent/settings.json" "$DOTFILES/pi/settings.json"
link "$HOME/.pi/agent/models.json" "$DOTFILES/pi/models.json"
link "$HOME/.pi/agent/agents" "$DOTFILES/pi/agents"
link "$HOME/.claude/CLAUDE.md" "$DOTFILES/claude/CLAUDE.md"
link "$HOME/.claude/settings.json" "$DOTFILES/claude/settings.json"
link "$HOME/.claude/statusline.py" "$DOTFILES/claude/statusline.py"
link "$HOME/.claude/agents" "$DOTFILES/claude/agents"
link "$HOME/.claude/skills" "$DOTFILES/claude/skills"

# pi's mcp.json carries a per-machine token and is not versioned: seed it
# from the example if it does not exist, then fill in the Authorization token.
if [ ! -f "$HOME/.pi/agent/mcp.json" ]; then
	cp "$DOTFILES/pi/mcp.json.example" "$HOME/.pi/agent/mcp.json"
	echo "seeded ~/.pi/agent/mcp.json from example — fill in the Authorization token"
fi

echo "done — repo at $DOTFILES"
