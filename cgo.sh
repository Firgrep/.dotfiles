#!/bin/bash

# Four pane tmux session with additional windows to run servers, designed for frontend and backend development

SESSION_ONE="work"
SESSION_TWO="play"
MODE="work"

# Check if tmux is running
if ! tmux has-session -t $SESSION_ONE 2>/dev/null; then
    # If tmux is not running, start it
    tmux new-session -d -s $SESSION_ONE

    # Rename newly made window and split it into four panes
    tmux rename-window "cero"
    tmux split-window -h -t $SESSION_ONE:cero
    tmux split-window -v -t $SESSION_ONE:cero
    tmux split-window -v -t $SESSION_ONE:cero
    tmux select-layout -t $SESSION_ONE:cero tiled

    # Set different directories for each pane
    tmux send-keys -t $SESSION_ONE:cero.1 'cd ~/dev/work' Enter
    tmux send-keys -t $SESSION_ONE:cero.1 'clear' Enter
    tmux send-keys -t $SESSION_ONE:cero.2 'cd ~/dev/work/cerebro-nest' Enter
    tmux send-keys -t $SESSION_ONE:cero.2 'clear' Enter
    tmux send-keys -t $SESSION_ONE:cero.3 'cd ~/dev/work/c' Enter
    tmux send-keys -t $SESSION_ONE:cero.3 'clear' Enter
    tmux send-keys -t $SESSION_ONE:cero.4 'cd ~/dev/work/c' Enter
    tmux send-keys -t $SESSION_ONE:cero.4 'clear' Enter

    tmux new-window -t $SESSION_ONE -n frontend && \
    tmux send-keys 'cd ~/dev/work/c' Enter && \
    tmux send-keys 'clear' Enter

    tmux new-window -t $SESSION_ONE -n backend && \
    tmux send-keys 'cd ~/dev/work/cerebro-nest' Enter && \
    tmux send-keys 'clear' Enter

    tmux new-window -t $SESSION_ONE -n mdvh && \
    tmux send-keys 'cd ~/dev/work/medivh' Enter && \
    tmux send-keys 'clear' Enter

    tmux new-window -t $SESSION_ONE -n types && \
    tmux send-keys 'cd ~/dev/work/cerebro-types' Enter && \
    tmux send-keys 'clear' Enter
    
    tmux new-window -t $SESSION_ONE -n wt-1 && \
    tmux send-keys 'cd ~/dev/work/watchtower' Enter && \
    tmux send-keys 'clear' Enter

    tmux new-window -t $SESSION_ONE -n wt-2 && \
    tmux send-keys 'cd ~/dev/work/watchtower' Enter && \
    tmux send-keys 'clear' Enter

else 
    echo "Session '$SESSION_ONE' already exists"
fi

# Check if tmux is running
if ! tmux has-session -t $SESSION_TWO 2>/dev/null; then
    # If tmux is not running, start it
    tmux new-session -d -s $SESSION_TWO

    # Rename newly made window and split it into four panes
    tmux rename-window "sphil"
    tmux split-window -h -t $SESSION_TWO:sphil
    tmux split-window -v -t $SESSION_TWO:sphil
    tmux split-window -v -t $SESSION_TWO:sphil
    tmux select-layout -t $SESSION_TWO:sphil tiled

    # Set different directories for each pane
    tmux send-keys -t $SESSION_TWO:sphil.1 'cd ~/dev/play' Enter
    tmux send-keys -t $SESSION_TWO:sphil.1 'clear' Enter
    tmux send-keys -t $SESSION_TWO:sphil.2 'cd ~/dev/play/sphil' Enter
    tmux send-keys -t $SESSION_TWO:sphil.2 'clear' Enter
    tmux send-keys -t $SESSION_TWO:sphil.3 'cd ~/dev/play/sphil' Enter
    tmux send-keys -t $SESSION_TWO:sphil.3 'clear' Enter
    tmux send-keys -t $SESSION_TWO:sphil.4 'cd ~/dev/play/sphil' Enter
    tmux send-keys -t $SESSION_TWO:sphil.4 'clear' Enter

else 
    echo "Session '$SESSION_ONE' already exists"
fi

if [[ $# -gt 0 ]]; then
    if [[ "$1" == "work" || "$1" == "play" ]]; then
        MODE="$1"
    else
        echo "Invalid argument. Use 'work' or 'play'."
        exit 1
    fi
fi

# Attach session
tmux attach-session -t $MODE