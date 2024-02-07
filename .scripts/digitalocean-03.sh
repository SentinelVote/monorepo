#!/bin/sh
# shellcheck shell=dash

#
# This script should be run as the unprivileged user.
#

# GUIDE:
#
# SSH into the user with tmux, with two tabs (split horizontally):
#   ssh unprivileged@$sentinelvote -t "tmux new-session -A -s main"
#
# Split the tabs either,
# horizontally: Ctrl+B followed by " (that's a double-quote).
# vertically:   Ctrl+B followed by % (percent).
#

# TODO: rest of the guide.
