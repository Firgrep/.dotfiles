#!/bin/bash

# Four pane tmux session with additional windows to run servers, designed for frontend and backend development

# Check if tmux is running
if ! tmux has-session -t work 2>/dev/null; then
    # If tmux is not running, start it
    tmux new-session -d -s work

    # Rename newly made window and split it into four panes
    tmux rename-window "cero"
    tmux split-window -h -t work:cero
    tmux split-window -v -t work:cero
    tmux split-window -v -t work:cero
    tmux select-layout -t work:cero tiled

    # Set different directories for each pane
    tmux send-keys -t work:cero.1 'cd ~/dev/work' Enter
    tmux send-keys -t work:cero.1 'clear' Enter
    tmux send-keys -t work:cero.2 'cd ~/dev/work/cerebro-nest' Enter
    tmux send-keys -t work:cero.2 'clear' Enter
    tmux send-keys -t work:cero.3 'cd ~/dev/work/c' Enter
    tmux send-keys -t work:cero.3 'clear' Enter
    tmux send-keys -t work:cero.4 'cd ~/dev/work/c' Enter
    tmux send-keys -t work:cero.4 'clear' Enter

    tmux new-window -t work -n frontend && \
    tmux send-keys 'cd ~/dev/work/c' Enter && \
    tmux send-keys 'clear' Enter

    tmux new-window -t work -n backend && \
    tmux send-keys 'cd ~/dev/work/cerebro-nest' Enter && \
    tmux send-keys 'clear' Enter

    tmux new-window -t work -n mdvh && \
    tmux send-keys 'cd ~/dev/work/medivh' Enter && \
    tmux send-keys 'clear' Enter

    tmux new-window -t work -n types && \
    tmux send-keys 'cd ~/dev/work/cerebro-types' Enter && \
    tmux send-keys 'clear' Enter

    # Attach to the session
    tmux attach-session -t work
else 
    echo "Session 'work' already exists"
fi
