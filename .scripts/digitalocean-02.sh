#!/bin/sh
# shellcheck shell=dash

#
# This script should be run as the unprivileged user.
# ssh unprivileged@<ip-address>
#

# Relevant links:
# https://hyperledger-fabric.readthedocs.io/en/latest/prereqs.html
# https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
# https://zero-to-nix.com/concepts/nix-installer#using

set -eu

DEBIAN_FRONTEND=noninteractive apt-get update  -y && \
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates curl

# Remove docker if exists.
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
sudo apt-get remove $pkg || true
done
sudo rm -f /usr/bin/docker-compose || true

# Remove nix if exists.
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- uninstall --no-confirm || true

# Install docker.
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
printf %s\\n "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
DEBIAN_FRONTEND=noninteractive sudo apt-get update -y
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin \
  git \
  wget

# Patches for docker-compose and root permissions.
USER_CURRENT=$(whoami)
if [ -f /usr/bin/docker-compose ]; then
  printf %s\\n 'docker-compose already exists.'
else
  printf '%s\n%s' '#!/bin/sh' 'docker compose "$@"' | sudo tee /usr/bin/docker-compose >/dev/null
  sudo chmod +x /usr/bin/docker-compose
  sudo chown "$USER_CURRENT":"$USER_CURRENT" /usr/bin/docker-compose
fi
sudo usermod -aG docker "$USER_CURRENT"
unset USER_CURRENT

# Install nix.
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# .bashrc settings.
cp -f /etc/skel/.bashrc ~/.bashrc || true
tee -a ~/.bashrc <<EOF
alias ls="ls -AF --color=auto"
alias nano="nano -L"
alias grep='grep --color=auto'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias rmdir='rmdir -v'
alias ln='ln -v'
alias chmod='chmod -c'
alias chown='chown -c'
EOF

cd "$HOME"
printf %s 'Please enter your GitHub Classic Token: ' && read -r TOKEN
git clone "https://${TOKEN}@github.com/SentinelVote/backend"
git clone "https://${TOKEN}@github.com/SentinelVote/blockchain"

printf %s\\n 'Done'
