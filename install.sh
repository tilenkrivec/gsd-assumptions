#!/bin/bash
# GSD Customizations Installer
# Copies modified workflow files into the GSD installation directory.
# Run after each GSD update to reapply your modifications.

set -e

GSD_DIR="$HOME/.claude/get-shit-done"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

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

# Copy modified files
echo "Installing customizations..."

cp "$SCRIPT_DIR/workflows/discuss-phase.md" "$GSD_DIR/workflows/discuss-phase.md"
echo "  ✓ workflows/discuss-phase.md"

cp "$SCRIPT_DIR/workflows/plan-phase.md" "$GSD_DIR/workflows/plan-phase.md"
echo "  ✓ workflows/plan-phase.md"

echo ""
echo "Done. Customizations installed."
echo ""
echo "Remember to add this to your project .planning/config.json:"
echo '  "workflow": { "discuss_mode": "assumptions" }'
