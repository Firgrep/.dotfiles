#!/bin/bash

# Four pane tmux session designed for frontend and backend development

# Check if tmux is running
if ! tmux has-session -t cgo 2>/dev/null; then
    # If tmux is not running, start it
    tmux new-session -d -s cgo

    # Rename newly made window and split it into four panes
    tmux rename-window "cero"
    tmux split-window -h -t cgo:cero
    tmux split-window -v -t cgo:cero
    tmux split-window -v -t cgo:cero
    tmux select-layout -t cgo:cero tiled

    # Set different directories for each pane
    tmux send-keys -t cgo:cero.1 'cd ~/dev/work' Enter
    tmux send-keys -t cgo:cero.1 'clear' Enter
    tmux send-keys -t cgo:cero.2 'cd ~/dev/work/cerebro-nest' Enter
    tmux send-keys -t cgo:cero.2 'clear' Enter
    tmux send-keys -t cgo:cero.3 'cd ~/dev/work/c' Enter
    tmux send-keys -t cgo:cero.3 'clear' Enter
    tmux send-keys -t cgo:cero.4 'cd ~/dev/work/c' Enter
    tmux send-keys -t cgo:cero.4 'clear' Enter

    # Attach to the session
    tmux attach-session -t cgo
else 
    echo "Session 'cgo' already exists"
fi
