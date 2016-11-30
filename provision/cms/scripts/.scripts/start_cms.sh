#!/usr/bin/env bash

# <contest_id> argument is required, if not specified print
# usage information and exit
if [ -z "$1" ]; then
    (>&2 echo "Usage:")
    (>&2 echo "    ./start_judge <contest_id>")
    exit 1
fi

contest_id="$1"

# bash strict mode: 
# See:
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

# create new tmux session called cms, with a window
# celled 'cms_services'
tmux new-session -d -s cms
tmux rename-window 'cms_services'

# split the window in two vertical panes and split
# the right pane also horizontally
tmux select-window -t 'cms:cms_services'
tmux split-window -h
tmux split-window -v -t 1

# send cms commands to the panes, "C-m" is Enter
# pane 0 (left):         cmsLogservice
# pane 1 (top right):    cmsResourceService -a
# pane 2 (bottom right): cmsRankingWebServer
tmux send-keys -t 0 "cmsLogService" "C-m"
tmux send-keys -t 1 "cmsResourceService -a $contest_id" "C-m"
tmux send-keys -t 2 "cmsRankingWebServer" "C-m"

