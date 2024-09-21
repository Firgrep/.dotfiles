#!/bin/bash

# Four pane tmux session designed for frontend and backend development

# Check if tmux is running
if ! tmux has-session -t main 2>/dev/null; then
    # If tmux is not running, start it
    tmux new-session -d -s main

    # Rename newly made window and split it into four panes
    tmux rename-window "cero"
    tmux split-window -h -t main:cero
    tmux split-window -v -t main:cero
    tmux split-window -v -t main:cero
    tmux select-layout -t main:cero tiled

    # Set different directories for each pane
    tmux send-keys -t main:cero.1 'cd ~/dev/work' Enter
    tmux send-keys -t main:cero.1 'clear' Enter
    tmux send-keys -t main:cero.2 'cd ~/dev/work/cerebro-nest' Enter
    tmux send-keys -t main:cero.2 'clear' Enter
    tmux send-keys -t main:cero.3 'cd ~/dev/work/c' Enter
    tmux send-keys -t main:cero.3 'clear' Enter
    tmux send-keys -t main:cero.4 'cd ~/dev/work/c' Enter
    tmux send-keys -t main:cero.4 'clear' Enter

    # Attach to the session
    tmux attach-session -t main
else 
    echo "Session 'main' already exists"
fi
