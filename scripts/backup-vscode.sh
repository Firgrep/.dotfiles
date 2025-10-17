#!/bin/bash

DOTFILES_VSCODE_DIR="$HOME/.dotfiles/backup/vscode"
VSCODE_SETTINGS="$HOME/.config/Code/User/settings.json"
VSCODE_KEYBINDINGS="$HOME/.config/Code/User/keybindings.json"

mkdir -p "$DOTFILES_VSCODE_DIR"

cp "$VSCODE_SETTINGS" "$DOTFILES_VSCODE_DIR/settings.json"
cp "$VSCODE_KEYBINDINGS" "$DOTFILES_VSCODE_DIR/keybindings.json"
code --list-extensions > "$DOTFILES_VSCODE_DIR/extensions.txt"

echo "✅ VS Code settings, keybindings, and extensions backed up to $DOTFILES_VSCODE_DIR"
