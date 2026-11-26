#!/bin/sh
# Copy stdin to the clipboard on GNOME Wayland without wl-copy.
# tmux hands the text to the terminal (OSC 52), which sets the Wayland
# clipboard; xclip mirrors it to X11 for apps that read it from there.
tmux load-buffer -w -b clip - &&
    tmux save-buffer -b clip - | xclip -selection clipboard -in >/dev/null 2>&1
