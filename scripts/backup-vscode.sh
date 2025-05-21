#!/bin/bash

DOTFILES_VSCODE_DIR="$HOME/.dotfiles/backup/vscode"

# VS Code settings locations
VSCODE_SETTINGS="$HOME/.config/Code/User/settings.json"
VSCODE_KEYBINDINGS="$HOME/.config/Code/User/keybindings.json"

mkdir -p "$DOTFILES_VSCODE_DIR"

cp "$VSCODE_SETTINGS" "$DOTFILES_VSCODE_DIR/settings.json"
cp "$VSCODE_KEYBINDINGS" "$DOTFILES_VSCODE_DIR/keybindings.json"

echo "✅ VS Code settings and keybindings backed up to $DOTFILES_VSCODE_DIR"
