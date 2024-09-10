#!/bin/bash

# Four pane tmux session designed for frontend and backend development

SESSION="main"
WINDOW="symposia"

PATH1="~/dev/play"
PATH2="~/dev/play/symposia"
PATH3=$PATH2
PATH4=$PATH2

# Check if tmux is running
if ! tmux has-session -t $SESSION 2>/dev/null; then
    # If tmux is not running, start it
    tmux new-session -d -s $SESSION

    # Rename newly made window and split it into four panes
    tmux rename-window $WINDOW
    tmux split-window -h -t $SESSION:$WINDOW
    tmux split-window -v -t $SESSION:$WINDOW
    tmux split-window -v -t $SESSION:$WINDOW
    tmux select-layout -t $SESSION:$WINDOW tiled

    # Set different directories for each pane
    tmux send-keys -t $SESSION:$WINDOW.1 "cd $PATH1" Enter
    tmux send-keys -t $SESSION:$WINDOW.1 'clear' Enter
    tmux send-keys -t $SESSION:$WINDOW.2 "cd $PATH2" Enter
    tmux send-keys -t $SESSION:$WINDOW.2 'clear' Enter
    tmux send-keys -t $SESSION:$WINDOW.3 "cd $PATH3" Enter
    tmux send-keys -t $SESSION:$WINDOW.3 'clear' Enter
    tmux send-keys -t $SESSION:$WINDOW.4 "cd $PATH4" Enter
    tmux send-keys -t $SESSION:$WINDOW.4 'clear' Enter

    # Attach to the session
    tmux attach-session -t $SESSION
else 
    echo "Session '$SESSION' already exists"
fi