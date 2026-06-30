#!/bin/bash

DOTFILES_FUZZEL_DIR="$HOME/.dotfiles/backup/fuzzel"
FUZZEL_CONFIG="$HOME/.config/fuzzel/fuzzel.ini"

mkdir -p "$DOTFILES_FUZZEL_DIR"

if [ -f "$FUZZEL_CONFIG" ]; then
  cp "$FUZZEL_CONFIG" "$DOTFILES_FUZZEL_DIR/fuzzel.ini"
else
  echo "⚠️  Fuzzel config not found at $FUZZEL_CONFIG"
fi

echo "✅ Fuzzel config backed up to $DOTFILES_FUZZEL_DIR"
