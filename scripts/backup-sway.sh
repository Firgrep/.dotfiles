#!/bin/bash

DOTFILES_SWAY_DIR="$HOME/.dotfiles/backup/sway"
SWAY_CONFIG="$HOME/.config/sway/config"

mkdir -p "$DOTFILES_SWAY_DIR"

if [ -f "$SWAY_CONFIG" ]; then
  cp "$SWAY_CONFIG" "$DOTFILES_SWAY_DIR/config"
else
  echo "⚠️  Sway config not found at $SWAY_CONFIG"
fi

echo "✅ Sway config backed up to $DOTFILES_SWAY_DIR"
