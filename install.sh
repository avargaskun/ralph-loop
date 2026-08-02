#!/bin/bash
# install.sh — One-time setup for ralph-loop
#
# Run this after cloning ralph-loop to ~/.ralph:
#   git clone https://github.com/<owner>/ralph-loop ~/.ralph
#   ~/.ralph/install.sh
#
# What this does:
#   1. Makes CLI scripts executable
#   2. Installs skill files into ~/.claude/commands/ (symlinks if supported, copies otherwise)
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

# ── Step 2: Install skill files into ~/.claude/commands/ ──────
#
# Prefer symlinks (files stay in sync with the repo automatically).
# Fall back to copies on systems where symlinks aren't available
# (e.g. Windows without Developer Mode).

mkdir -p "$CLAUDE_COMMANDS_DIR"

can_symlink() {
    local test_link="$CLAUDE_COMMANDS_DIR/.ralph_symlink_test"
    if ln -s "$COMMANDS_DIR/ralph-plan.md" "$test_link" 2>/dev/null; then
        rm -f "$test_link"
        return 0
    fi
    return 1
}

if can_symlink; then
    INSTALL_METHOD="symlink"
else
    INSTALL_METHOD="copy"
fi

echo ""
if [ "$INSTALL_METHOD" = "symlink" ]; then
    echo "→ Creating Claude Code skill symlinks..."
else
    echo "→ Copying Claude Code skill files (symlinks not supported)..."
fi

for skill_file in "$COMMANDS_DIR"/ralph-*.md; do
    skill_name="$(basename "$skill_file")"
    target="$CLAUDE_COMMANDS_DIR/$skill_name"

    if [ "$INSTALL_METHOD" = "symlink" ]; then
        if [ -L "$target" ]; then
            echo "  (already linked) $target"
        elif [ -e "$target" ]; then
            echo "  WARNING: $target exists and is not a symlink — skipping"
            echo "           Remove it manually and re-run install.sh if you want the skill."
        else
            ln -s "$skill_file" "$target"
            echo "  $target → $skill_file"
        fi
    else
        # Copy mode: always overwrite to keep files current
        if [ -L "$target" ]; then
            rm -f "$target"
        fi
        cp "$skill_file" "$target"
        echo "  $target (copied)"
    fi
done

if [ "$INSTALL_METHOD" = "copy" ]; then
    echo ""
    echo "  NOTE: Skills were copied, not symlinked. Run 'ralph update'"
    echo "        after pulling new versions to refresh them."
fi

# Remove installed links/copies for skills that no longer exist in the repo
RETIRED_SKILLS="ralph-address.md"
for retired in $RETIRED_SKILLS; do
    target="$CLAUDE_COMMANDS_DIR/$retired"
    if [ -L "$target" ] || [ -f "$target" ]; then
        rm -f "$target"
        echo "  removed retired skill: $target"
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
echo "     /ralph-auto in Claude Code"
echo ""
echo "  To update later:  ralph update"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
