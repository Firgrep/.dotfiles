#!/bin/bash

SESSION_ONE="work"
SESSION_TWO="play"
MODE="work"

# Check if tmux is running
if ! tmux has-session -t $SESSION_ONE 2>/dev/null; then
    # If tmux is not running, start it
    tmux new-session -d -s $SESSION_ONE

    tmux rename-window "ge1"
    tmux send-keys 'cd ~/dev/work/geir' Enter && \
    tmux send-keys 'clear' Enter

    tmux new-window -t $SESSION_ONE -n ge2 && \
    tmux send-keys 'cd ~/dev/work/geir' Enter && \
    tmux send-keys 'clear' Enter

    tmux new-window -t $SESSION_ONE -n ge3 && \
    tmux send-keys 'cd ~/dev/work/geir' Enter && \
    tmux send-keys 'clear' Enter

    tmux new-window -t $SESSION_ONE -n ge4 && \
    tmux send-keys 'cd ~/dev/work/geir' Enter && \
    tmux send-keys 'clear' Enter
    
else 
    echo "Session '$SESSION_ONE' already exists"
fi

# Check if tmux is running
if ! tmux has-session -t $SESSION_TWO 2>/dev/null; then
    # If tmux is not running, start it
    tmux new-session -d -s $SESSION_TWO

    tmux rename-window "sc1"
    tmux send-keys 'cd ~/dev/play/scholia' Enter && \
    tmux send-keys 'clear' Enter

    tmux new-window -t $SESSION_TWO -n sc2 && \
    tmux send-keys 'cd ~/dev/play/scholia' Enter && \
    tmux send-keys 'clear' Enter

    tmux new-window -t $SESSION_TWO -n sc3 && \
    tmux send-keys 'cd ~/dev/play/scholia' Enter && \
    tmux send-keys 'clear' Enter
else 
    echo "Session '$SESSION_TWO' already exists"
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