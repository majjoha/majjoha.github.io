#!/bin/bash
# Create session
SESSION="blog"
cd ~/Dropbox/Tekstdokumenter/blog/
tmux -2 new-session -d -s $SESSION

# Create window
tmux new-window -t $SESSION:1 -n 'vim'
tmux send-keys "vim" C-m
tmux new-window -t $SESSION:2 -n 'zsh'
tmux new-window -t $SESSION:3 -n 'jekyll-server'
tmux send-keys "jekyll serve --watch --drafts" C-m
tmux -2 attach-session -t $SESSION
