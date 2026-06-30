#!/bin/bash

DOTFILES_KANSHI_DIR="$HOME/.dotfiles/backup/kanshi"
KANSHI_CONFIG="$HOME/.config/kanshi/config"

mkdir -p "$DOTFILES_KANSHI_DIR"

if [ -f "$KANSHI_CONFIG" ]; then
  cp "$KANSHI_CONFIG" "$DOTFILES_KANSHI_DIR/config"
else
  echo "⚠️  Kanshi config not found at $KANSHI_CONFIG"
fi

echo "✅ Kanshi config backed up to $DOTFILES_KANSHI_DIR"
