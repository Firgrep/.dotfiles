#!/bin/bash

DOTFILES_DIR="$HOME/.dotfiles"

cd "$DOTFILES_DIR"

./scripts/backup-vscode.sh
./scripts/backup-sway.sh
./scripts/backup-waybar.sh
./scripts/backup-kanshi.sh