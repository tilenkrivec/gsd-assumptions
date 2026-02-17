#!/bin/bash
# GSD Customizations Installer (macOS / Linux / Git Bash on Windows)
# Copies modified workflow files into the GSD installation directory.
# Detects OS and replaces placeholder paths with the correct home directory.
# Run after each GSD update to reapply your modifications.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_HOME="/Users/tilenkrivec"

# Detect OS and set GSD directory
detect_platform() {
  case "$(uname -s)" in
    Darwin)
      PLATFORM="macOS"
      GSD_DIR="$HOME/.claude/get-shit-done"
      ;;
    Linux)
      # Could be native Linux or WSL
      if grep -qi microsoft /proc/version 2>/dev/null; then
        PLATFORM="WSL"
        # In WSL, Claude Code uses the Windows-side .claude directory
        WIN_HOME=$(wslpath "$(cmd.exe /C 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')" 2>/dev/null || echo "")
        if [ -n "$WIN_HOME" ] && [ -d "$WIN_HOME/.claude/get-shit-done" ]; then
          GSD_DIR="$WIN_HOME/.claude/get-shit-done"
          HOME_FOR_PATHS="$WIN_HOME"
        else
          GSD_DIR="$HOME/.claude/get-shit-done"
          HOME_FOR_PATHS="$HOME"
        fi
      else
        PLATFORM="Linux"
        GSD_DIR="$HOME/.claude/get-shit-done"
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      PLATFORM="Windows (Git Bash)"
      # Git Bash on Windows: $HOME is /c/Users/username
      GSD_DIR="$HOME/.claude/get-shit-done"
      ;;
    *)
      PLATFORM="Unknown"
      GSD_DIR="$HOME/.claude/get-shit-done"
      ;;
  esac

  # Default HOME_FOR_PATHS if not set by WSL detection
  HOME_FOR_PATHS="${HOME_FOR_PATHS:-$HOME}"
}

detect_platform

echo "Platform: $PLATFORM"
echo "Home: $HOME_FOR_PATHS"

# Verify GSD is installed
if [ ! -d "$GSD_DIR" ]; then
  echo ""
  echo "Error: GSD not found at $GSD_DIR"
  echo "Install GSD first, then run this script."
  if [ "$PLATFORM" = "Windows (Git Bash)" ]; then
    echo ""
    echo "On Windows, you can also try: powershell -File install.ps1"
  fi
  exit 1
fi

echo "GSD found at: $GSD_DIR"
echo "GSD version: $(cat "$GSD_DIR/VERSION" 2>/dev/null || echo 'unknown')"
echo ""

# Backup originals (only if backup doesn't already exist)
BACKUP_DIR="$SCRIPT_DIR/.originals"
if [ ! -d "$BACKUP_DIR" ]; then
  echo "Backing up original files to .originals/..."
  mkdir -p "$BACKUP_DIR/workflows"
  cp "$GSD_DIR/workflows/discuss-phase.md" "$BACKUP_DIR/workflows/discuss-phase.md" 2>/dev/null || true
  cp "$GSD_DIR/workflows/plan-phase.md" "$BACKUP_DIR/workflows/plan-phase.md" 2>/dev/null || true
  echo "Originals backed up."
else
  echo "Backup already exists, skipping."
fi

echo ""

# Copy modified files with path replacement
echo "Installing customizations..."

install_file() {
  local src="$1"
  local dst="$2"
  local name="$3"

  if [ "$HOME_FOR_PATHS" != "$TEMPLATE_HOME" ]; then
    sed "s|$TEMPLATE_HOME|$HOME_FOR_PATHS|g" "$src" > "$dst"
    echo "  ✓ $name (paths updated: $TEMPLATE_HOME → $HOME_FOR_PATHS)"
  else
    cp "$src" "$dst"
    echo "  ✓ $name"
  fi
}

install_file "$SCRIPT_DIR/workflows/discuss-phase.md" "$GSD_DIR/workflows/discuss-phase.md" "workflows/discuss-phase.md"
install_file "$SCRIPT_DIR/workflows/plan-phase.md" "$GSD_DIR/workflows/plan-phase.md" "workflows/plan-phase.md"

echo ""
echo "Done. Customizations installed."
echo ""
echo "Remember to add this to your project .planning/config.json:"
echo '  "workflow": { "discuss_mode": "assumptions" }'
