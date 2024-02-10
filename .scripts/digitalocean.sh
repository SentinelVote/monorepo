#!/bin/sh
# shellcheck shell=dash

#
# This script should be run as the root user, see ./README.md for the command to run it.
#
# Relevant links:
# https://hyperledger-fabric.readthedocs.io/en/latest/prereqs.html
# https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
# https://zero-to-nix.com/concepts/nix-installer#using
#

set -eu
fail () { printf %s\\n "$1" >&2 ; exit 1 ; }
CURRENT_DIRECTORY="$(pwd)"

# -------------------------------------------------------------------------------------------------
# Add a non-root user.

NONROOT="unprivileged"

# Check if the user 1000 already exists
if test -z "$(getent passwd 1000)" ; then
  sudo useradd -u 1000 -s /bin/bash -m "$NONROOT"
fi
sudo mkdir /home/unprivileged/.ssh || true
sudo cp -f /root/.ssh/authorized_keys /home/"$NONROOT"/.ssh/

# Allow full sudo access to the non-root user.
printf %s\\n "unprivileged ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/"$NONROOT"

# Defer executing chown for the non-root user's home directory until the script exits.
if test -z "$NONROOT"; then
  fail 'Error: NONROOT is not set.'
else
  trap 'sudo chown -R "${NONROOT}:${NONROOT}" "/home/${NONROOT}"' EXIT
fi

# -------------------------------------------------------------------------------------------------
# Update the system and install some basic packages.

alias apt-get="DEBIAN_FRONTEND=noninteractive sudo apt-get"
apt-get update  -y && \
apt-get upgrade -y && \
apt-get install -y --no-install-recommends ca-certificates curl git jq tmux wget

# -------------------------------------------------------------------------------------------------
# Install Docker.

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
printf %s\\n "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && printf %s\\n "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
apt-get update -y
apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# Patches for docker-compose and root permissions.
if test -f /usr/bin/docker-compose; then
  printf %s\\n 'docker-compose already exists.'
else
  printf '%s\n%s' '#!/bin/sh' 'docker compose "$@"' | sudo tee /usr/bin/docker-compose >/dev/null
  sudo chmod +x /usr/bin/docker-compose
  sudo chown "${NONROOT}:${NONROOT}" /usr/bin/docker-compose
fi
sudo usermod -aG docker "$NONROOT"

# -------------------------------------------------------------------------------------------------
# Install Nix Package Manager.
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# -------------------------------------------------------------------------------------------------
# Setup aliases for bash.

sudo cp -f /etc/skel/.bashrc "/home/${NONROOT}/.bashrc" || true
tee -a "/home/${NONROOT}/.bashrc" <<EOF
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

# -------------------------------------------------------------------------------------------------
# Install Caddy
apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
apt-get update -y
apt-get install -y caddy

# Copy over the configuration file
cat <<EOF | sudo tee /etc/caddy/Caddyfile
api.sentinelvote.tech {
	reverse_proxy localhost:8080
}

fablo.sentinelvote.tech {
	reverse_proxy localhost:8801
}

blockchain-explorer.sentinelvote.tech {
	reverse_proxy localhost:7011
}
EOF

# Reload Caddy
sudo systemctl reload caddy

# -------------------------------------------------------------------------------------------------
# Install Golang

# shellcheck disable=SC2016
printf 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile

GO_VERSION="1.21.7"
GO_URL="https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
GO_TAR="go${GO_VERSION}.linux-amd64.tar.gz"

sudo wget -O "$GO_TAR" "$GO_URL"
sudo tar -C /usr/local -xzf "$GO_TAR"
rm -f "$GO_TAR"
PATH="${PATH}:/usr/local/go/bin"
unset GO_VERSION GO_URL GO_TAR

# -------------------------------------------------------------------------------------------------
# Clone and build the backend

cd "/home/${NONROOT}"
git clone https://github.com/SentinelVote/backend.git
cd backend || fail 'Error: Could not change to the backend directory.'
go mod download && CGO_ENABLED=0 go build -o ./api

# -------------------------------------------------------------------------------------------------
# Clone and build the blockchain

cd "/home/${NONROOT}"
git clone https://github.com/SentinelVote/blockchain.git
cd blockchain || fail 'Error: Could not change to the blockchain directory.'

# TODO: Use maximum number of instances (9).
sed -i 's/instances: [2-9]/instances: 9/' fablo-config.yaml

# Set up the blockchain.
./setup-fablo.sh || fail 'Error: Could not set up the blockchain.'
./fablo.sh prune
./fablo.sh generate

# Add a symlink to the fablo.sh script as 'fablo' in /usr/local/bin
sudo ln -s "/home/${NONROOT}/blockchain/fablo.sh" /usr/local/bin/fablo

# Pre-pull the docker images
docker pull softwaremill/fablo:1.2.0
docker pull hyperledger/fabric-tools:2.5.4
docker pull hyperledger/explorer-db:1.1.8
docker pull hyperledger/explorer:1.1.8
docker pull hyperledger/fabric-baseos:2.5.4
docker pull hyperledger/fabric-ca:1.5.5
docker pull hyperledger/fabric-ccenv:2.5.4
docker pull hyperledger/fabric-orderer:2.5.4
docker pull hyperledger/fabric-peer:2.5.4

# -------------------------------------------------------------------------------------------------
# Print the final instructions.

# shellcheck disable=SC2016
printf %s\\n '
# The setup is complete. You can now log in as the unprivileged user and start the services.
# SSH into the unprivileged user, and start tmux so that you can use multiple tabs.

ssh unprivileged@service.sentinelvote.tech
tmux

# Split the tabs either,
# horizontally: Ctrl+B followed by " (that is a double-quote).
# vertically:   Ctrl+B followed by % (percent).

# To start the blockchain, run the following commands:
cd $HOME/blockchain
fablo recreate

# To start the backend, wait for the blockchain to start. Then, run the following commands:
cd $HOME/backend
./api --users 10000 --schema simulation-full
'

cd "$CURRENT_DIRECTORY" || fail 'Error: Could not change to the original directory.'
sudo chown -R "${NONROOT}:${NONROOT}" "/home/${NONROOT}"
unset CURRENT_DIRECTORY NONROOT apt-get fail || true
printf %s\\n "Setup completed successfully."
exit 0
