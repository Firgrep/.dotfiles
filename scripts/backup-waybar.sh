#!/bin/bash

DOTFILES_WAYBAR_DIR="$HOME/.dotfiles/backup/waybar"
WAYBAR_CONFIG="$HOME/.config/waybar/config"
WAYBAR_STYLE="$HOME/.config/waybar/style.css"

mkdir -p "$DOTFILES_WAYBAR_DIR"

if [ -f "$WAYBAR_CONFIG" ]; then
  cp "$WAYBAR_CONFIG" "$DOTFILES_WAYBAR_DIR/config"
else
  echo "⚠️  Waybar config not found at $WAYBAR_CONFIG"
fi

if [ -f "$WAYBAR_STYLE" ]; then
  cp "$WAYBAR_STYLE" "$DOTFILES_WAYBAR_DIR/style.css"
else
  echo "⚠️  Waybar style not found at $WAYBAR_STYLE"
fi

echo "✅ Waybar config and style backed up to $DOTFILES_WAYBAR_DIR"
