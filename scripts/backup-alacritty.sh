#!/bin/bash

DOTFILES_ALACRITTY_DIR="$HOME/.dotfiles/backup/alacritty"
ALACRITTY_CONFIG="$HOME/.config/alacritty/alacritty.toml"

mkdir -p "$DOTFILES_ALACRITTY_DIR"

if [ -f "$ALACRITTY_CONFIG" ]; then
  cp "$ALACRITTY_CONFIG" "$DOTFILES_ALACRITTY_DIR/alacritty.toml"
else
  echo "⚠️  Alacritty config not found at $ALACRITTY_CONFIG"
fi

echo "✅ Alacritty config backed up to $DOTFILES_ALACRITTY_DIR"
