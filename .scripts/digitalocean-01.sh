#!/bin/sh
# shellcheck shell=dash

#
# This script should be run as the root user.
# ssh root@<ip-address>
#

set -eu

# Check if the user 1000 already exists
if test -z "$(getent passwd 1000)" ; then
sudo useradd -u 1000 -s /bin/bash -m unprivileged
fi
mkdir /home/unprivileged/.ssh || true
cp -f ~/.ssh/authorized_keys /home/unprivileged/.ssh/
chown -R unprivileged:unprivileged /home/unprivileged/.ssh

# Allow full sudo access to the unprivileged user.
printf %s\\n "unprivileged ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/unprivileged

printf %s\\n 'Done'
