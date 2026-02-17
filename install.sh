#!/bin/bash
# GSD Customizations Installer
# Copies modified workflow files into the GSD installation directory.
# Replaces placeholder paths with the current user's home directory.
# Run after each GSD update to reapply your modifications.

set -e

GSD_DIR="$HOME/.claude/get-shit-done"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_HOME="/Users/tilenkrivec"

# Verify GSD is installed
if [ ! -d "$GSD_DIR" ]; then
  echo "Error: GSD not found at $GSD_DIR"
  echo "Install GSD first, then run this script."
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

  if [ "$HOME" != "$TEMPLATE_HOME" ]; then
    # Replace template paths with current user's home directory
    sed "s|$TEMPLATE_HOME|$HOME|g" "$src" > "$dst"
    echo "  ✓ $name (paths updated for $HOME)"
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
