#!/bin/bash

DOTFILES_VSCODE_DIR="$HOME/.dotfiles/backup/vscode"
VSCODE_SETTINGS="$HOME/.config/Code/User/settings.json"
VSCODE_KEYBINDINGS="$HOME/.config/Code/User/keybindings.json"

mkdir -p "$DOTFILES_VSCODE_DIR"

if [ -f "$VSCODE_SETTINGS" ]; then
  cp "$VSCODE_SETTINGS" "$DOTFILES_VSCODE_DIR/settings.json"
else
  echo "⚠️  VS Code settings not found at $VSCODE_SETTINGS"
fi

if [ -f "$VSCODE_KEYBINDINGS" ]; then
  cp "$VSCODE_KEYBINDINGS" "$DOTFILES_VSCODE_DIR/keybindings.json"
else
  echo "⚠️  VS Code keybindings not found at $VSCODE_KEYBINDINGS"
fi

if command -v code >/dev/null 2>&1; then
  code --list-extensions > "$DOTFILES_VSCODE_DIR/extensions.txt"
else
  echo "⚠️  'code' command not found; skipping extensions list"
fi

echo "✅ VS Code settings, keybindings, and extensions backed up to $DOTFILES_VSCODE_DIR"
