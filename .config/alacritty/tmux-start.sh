#!/usr/bin/env bash
# Alacritty's shell: run everything inside tmux.
# The first Alacritty window reattaches to an existing session; later windows get a new one.

command -v tmux >/dev/null || exec "${SHELL:-bash}" -l

if [ "$(pgrep -x -u "$USER" alacritty | wc -l)" -le 1 ] && tmux has-session 2>/dev/null; then
  exec tmux attach
fi

exec tmux new-session
