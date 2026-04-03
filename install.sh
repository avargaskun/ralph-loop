#!/bin/bash
# install.sh — One-time setup for ralph-loop
#
# Run this after cloning ralph-loop to ~/.ralph:
#   git clone https://github.com/<owner>/ralph-loop ~/.ralph
#   ~/.ralph/install.sh
#
# What this does:
#   1. Makes CLI scripts executable
#   2. Creates ~/.claude/commands/ralph-*.md symlinks pointing to this repo
#   3. Appends ~/.ralph/bin to PATH in your shell RC file (once, guarded)

set -euo pipefail

RALPH_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$RALPH_DIR/bin"
COMMANDS_DIR="$RALPH_DIR/commands"
CLAUDE_COMMANDS_DIR="$HOME/.claude/commands"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Installing ralph-loop"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Step 1: Make CLI scripts executable ───────────────────────
echo "→ Making CLI scripts executable..."
chmod +x "$BIN_DIR/ralph"
chmod +x "$BIN_DIR/ralph-follow"
echo "  $BIN_DIR/ralph"
echo "  $BIN_DIR/ralph-follow"

# ── Step 2: Create ~/.claude/commands/ symlinks ───────────────
echo ""
echo "→ Creating Claude Code skill symlinks..."
mkdir -p "$CLAUDE_COMMANDS_DIR"

for skill_file in "$COMMANDS_DIR"/ralph-*.md; do
    skill_name="$(basename "$skill_file")"
    target="$CLAUDE_COMMANDS_DIR/$skill_name"

    if [ -L "$target" ]; then
        echo "  (already exists) $target"
    elif [ -e "$target" ]; then
        echo "  WARNING: $target exists and is not a symlink — skipping"
        echo "           Remove it manually and re-run install.sh if you want the skill."
    else
        ln -s "$skill_file" "$target"
        echo "  $target → $skill_file"
    fi
done

# ── Step 3: Add ~/.ralph/bin to PATH ──────────────────────────
echo ""
echo "→ Configuring PATH..."

PATH_LINE="export PATH=\"\$HOME/.ralph/bin:\$PATH\""
PATH_GUARD="ralph/bin"  # substring to check for duplicate

# Detect shell RC file
if [ -n "${ZSH_VERSION:-}" ] || [ "$(basename "${SHELL:-}")" = "zsh" ]; then
    RC_FILE="$HOME/.zshrc"
elif [ -n "${BASH_VERSION:-}" ] || [ "$(basename "${SHELL:-}")" = "bash" ]; then
    # macOS uses .bash_profile for login shells
    if [ -f "$HOME/.bash_profile" ]; then
        RC_FILE="$HOME/.bash_profile"
    else
        RC_FILE="$HOME/.profile"
    fi
else
    RC_FILE="$HOME/.profile"
fi

if grep -q "$PATH_GUARD" "$RC_FILE" 2>/dev/null; then
    echo "  PATH already configured in $RC_FILE — skipping"
else
    echo "" >> "$RC_FILE"
    echo "# ralph-loop" >> "$RC_FILE"
    echo "$PATH_LINE" >> "$RC_FILE"
    echo "  Added to $RC_FILE: $PATH_LINE"
fi

# ── Done ──────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Installation complete!"
echo ""
echo "  Next steps:"
echo "  1. Open a new terminal (or: source $RC_FILE)"
echo "  2. In any project, run: ralph <project-name>"
echo "  3. Use /ralph-explore, /ralph-design, /ralph-plan,"
echo "     /ralph-critique, /ralph-loop, /ralph-review,"
echo "     /ralph-address in Claude Code"
echo ""
echo "  To update later:  ralph update"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
