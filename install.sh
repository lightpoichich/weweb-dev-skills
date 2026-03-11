#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────
# WeWeb Dev Skills Installer for Claude Code
# ─────────────────────────────────────────────

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Config
SKILLS_DIR="${HOME}/.claude/skills"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS=("weweb-component-dev" "weweb-visual-qa" "weweb-orchestrator" "weweb-publish" "weweb-kickstart")
MODE="symlink"
ACTION="install"

# ─────────────────────────────────────────────
# Functions
# ─────────────────────────────────────────────

usage() {
  cat <<EOF
${BOLD}WeWeb Dev Skills Installer${NC}

${BOLD}Usage:${NC}
  ./install.sh [options]

${BOLD}Options:${NC}
  --copy        Copy files instead of symlinking (default: symlink)
  --uninstall   Remove installed skills
  --help        Show this help message

${BOLD}Skills installed:${NC}
  weweb-component-dev   Complete WeWeb component development reference
  weweb-visual-qa       Visual QA with Playwright MCP
  weweb-orchestrator    Multi-agent orchestrated development
  weweb-publish         GitHub publishing and version management
  weweb-kickstart       Scaffold new components from empty directory

${BOLD}Install location:${NC}
  ${SKILLS_DIR}/

${BOLD}Examples:${NC}
  ./install.sh              # Install with symlinks (recommended)
  ./install.sh --copy       # Install with file copies
  ./install.sh --uninstall  # Remove all installed skills
EOF
}

info()    { echo -e "${BLUE}ℹ${NC}  $1"; }
success() { echo -e "${GREEN}✓${NC}  $1"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $1"; }
error()   { echo -e "${RED}✗${NC}  $1"; }

install_skill() {
  local skill_name="$1"
  local source_dir="${SCRIPT_DIR}/skills/${skill_name}"
  local target_dir="${SKILLS_DIR}/${skill_name}"

  # Check source exists
  if [ ! -d "$source_dir" ]; then
    error "Source not found: ${source_dir}"
    return 1
  fi

  # Handle existing installation
  if [ -e "$target_dir" ]; then
    if [ -L "$target_dir" ]; then
      info "Removing existing symlink: ${skill_name}"
      rm "$target_dir"
    elif [ -d "$target_dir" ]; then
      warn "Existing directory found: ${skill_name}"
      read -r -p "   Overwrite? [y/N] " response
      if [[ "$response" =~ ^[Yy]$ ]]; then
        rm -rf "$target_dir"
      else
        warn "Skipped: ${skill_name}"
        return 0
      fi
    fi
  fi

  # Install
  if [ "$MODE" = "symlink" ]; then
    ln -s "$source_dir" "$target_dir"
    success "Symlinked: ${skill_name} → ${source_dir}"
  else
    cp -r "$source_dir" "$target_dir"
    success "Copied: ${skill_name}"
  fi
}

uninstall_skill() {
  local skill_name="$1"
  local target_dir="${SKILLS_DIR}/${skill_name}"

  if [ -L "$target_dir" ]; then
    rm "$target_dir"
    success "Removed symlink: ${skill_name}"
  elif [ -d "$target_dir" ]; then
    rm -rf "$target_dir"
    success "Removed directory: ${skill_name}"
  else
    info "Not installed: ${skill_name}"
  fi
}

# ─────────────────────────────────────────────
# Parse arguments
# ─────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case $1 in
    --copy)
      MODE="copy"
      shift
      ;;
    --uninstall)
      ACTION="uninstall"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      error "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────

echo ""
echo -e "${BOLD}WeWeb Dev Skills for Claude Code${NC}"
echo "─────────────────────────────────"
echo ""

if [ "$ACTION" = "uninstall" ]; then
  info "Uninstalling skills from ${SKILLS_DIR}..."
  echo ""

  for skill in "${SKILLS[@]}"; do
    uninstall_skill "$skill"
  done

  echo ""
  success "Uninstall complete."
  exit 0
fi

# Install
info "Mode: ${MODE}"
info "Target: ${SKILLS_DIR}"
echo ""

# Create skills directory if needed
if [ ! -d "$SKILLS_DIR" ]; then
  mkdir -p "$SKILLS_DIR"
  success "Created ${SKILLS_DIR}"
fi

# Install each skill
for skill in "${SKILLS[@]}"; do
  install_skill "$skill"
done

echo ""

# Check Playwright MCP (optional)
if [ -f "${HOME}/.claude/settings.json" ]; then
  if grep -q "playwright" "${HOME}/.claude/settings.json" 2>/dev/null; then
    success "Playwright MCP plugin detected"
  else
    warn "Playwright MCP plugin not detected in ~/.claude/settings.json"
    echo "   Visual QA skill requires it. See: https://github.com/anthropics/claude-code"
  fi
elif [ -f "${HOME}/.claude/settings.local.json" ]; then
  if grep -q "playwright" "${HOME}/.claude/settings.local.json" 2>/dev/null; then
    success "Playwright MCP plugin detected"
  else
    warn "Playwright MCP plugin not detected"
    echo "   Visual QA skill requires it. See: https://github.com/anthropics/claude-code"
  fi
else
  warn "No Claude Code settings file found"
  echo "   Make sure Claude Code is installed and configured"
fi

echo ""
echo "─────────────────────────────────"
echo -e "${BOLD}Summary${NC}"
echo "─────────────────────────────────"
echo ""

for skill in "${SKILLS[@]}"; do
  target="${SKILLS_DIR}/${skill}"
  if [ -e "$target" ]; then
    if [ -L "$target" ]; then
      success "${skill} (symlinked)"
    else
      success "${skill} (copied)"
    fi
  else
    error "${skill} (not installed)"
  fi
done

echo ""
echo -e "${BOLD}Next steps:${NC}"
echo "  1. Start Claude Code in your WeWeb component project"
echo "  2. The skills will activate automatically on relevant tasks"
echo "  3. Try: \"Build a [component] for WeWeb\""
echo "  4. Read docs/getting-started.md for a full walkthrough"
echo ""

if [ "$MODE" = "symlink" ]; then
  info "Skills are symlinked — run 'git pull' in this repo to update them"
fi

echo ""
