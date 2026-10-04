#!/usr/bin/env bash
# ==============================================================================
# Install Skills for AI Coding Agents (flutter-gemini-live)
#
# Usage:
#   # Auto-detect existing agents or install to all known agent folders:
#   curl -fsSL https://raw.githubusercontent.com/JAICHANGPARK/flutter_gemini_live/main/tool/install_skills.sh | bash
#
#   # Install to specific agent(s):
#   curl -fsSL https://raw.githubusercontent.com/JAICHANGPARK/flutter_gemini_live/main/tool/install_skills.sh | bash -s -- claude gemini
#
#   # Run locally from repo:
#   ./tool/install_skills.sh [agents...]
# ==============================================================================

set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/JAICHANGPARK/flutter_gemini_live/main"
SKILLS=("flutter-gemini-live" "gemini-live-widgets" "gemini-live-firebase-migration")
KNOWN_AGENTS=("agents" "claude" "gemini" "codex" "hermes" "pi")

# Determine script location if running locally
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# Determine target directories
TARGET_DIRS=()

if [ "$#" -gt 0 ]; then
  # User specified specific agents (e.g. bash -s -- claude gemini)
  for arg in "$@"; do
    clean_arg="${arg#\~/.}"
    clean_arg="${clean_arg#.}"
    TARGET_DIRS+=("$HOME/.$clean_arg")
  done
else
  # Auto-detection mode:
  # Check which ~/.<agent> folders already exist in $HOME
  FOUND_ANY=false
  for agent in "${KNOWN_AGENTS[@]}"; do
    if [ -d "$HOME/.$agent" ]; then
      TARGET_DIRS+=("$HOME/.$agent")
      FOUND_ANY=true
    fi
  done

  # If none of the known folders exist, install to all standard ones so they are ready
  if [ "$FOUND_ANY" = false ]; then
    for agent in "${KNOWN_AGENTS[@]}"; do
      TARGET_DIRS+=("$HOME/.$agent")
    done
  fi
fi

echo "==> Installing Gemini Live agent skills..."
echo "    Targets: ${TARGET_DIRS[*]}"
echo "    Skills:  ${SKILLS[*]}"

for target_dir in "${TARGET_DIRS[@]}"; do
  for skill in "${SKILLS[@]}"; do
    dest_dir="$target_dir/skills/$skill"
    mkdir -p "$dest_dir"

    # If running locally from repo and file exists, copy directly
    if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/skills/$skill/SKILL.md" ]; then
      cp "$SCRIPT_DIR/skills/$skill/SKILL.md" "$dest_dir/SKILL.md"
    else
      # Download from GitHub
      curl -fsSL "$REPO_RAW/skills/$skill/SKILL.md" -o "$dest_dir/SKILL.md"
    fi
  done
  echo "  ✓ Installed skills into $target_dir/skills/"
done

echo ""
echo "✨ All skills successfully installed!"
echo "   Your AI agents can now discover flutter-gemini-live, gemini-live-widgets,"
echo "   and gemini-live-firebase-migration skills."
