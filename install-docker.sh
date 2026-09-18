#!/bin/sh
# Install Docker Engine from Docker's official apt repository (Debian).
# Auto-detects the Debian codename (trixie/bookworm/bullseye) and arch, so it
# works on any supported Debian release. Idempotent: safe to re-run.
#
# Usage:  sudo ./install-docker.sh
#
# Installs: docker-ce, docker-ce-cli, containerd.io, docker-buildx-plugin,
#           docker-compose-plugin
set -eu

# --- sanity checks ---------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
    echo "error: run as root (sudo ./install-docker.sh)" >&2
    exit 1
fi
if [ ! -f /etc/os-release ] || ! grep -q '^ID=debian$' /etc/os-release; then
    echo "error: this script targets Debian only (/etc/os-release says otherwise)" >&2
    exit 1
fi

codename=$(sed -n 's/^VERSION_CODENAME=//p' /etc/os-release)
arch=$(dpkg --print-architecture)
case "$codename" in
    trixie|bookworm|bullseye) : ;;
    *) echo "error: unsupported Debian codename '$codename' (want trixie/bookworm/bullseye)" >&2; exit 1 ;;
esac

# Already installed? (re-run just refreshes to latest)
if command -v docker >/dev/null 2>&1; then
    echo "docker already present: $(docker --version 2>/dev/null || true)"
fi

echo "==> Installing Docker Engine for Debian $codename ($arch) from download.docker.com"

# --- prerequisites ---------------------------------------------------------
apt-get update
apt-get install -y ca-certificates curl gnupg

# --- Docker's official GPG key (modern keyring location) -------------------
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg \
    -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# --- the apt source --------------------------------------------------------
echo "deb [arch=$arch signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $codename stable" \
    > /etc/apt/sources.list.d/docker.list

# --- install ---------------------------------------------------------------
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

echo
echo "==> Docker installed: $(docker --version)"
echo
echo "To run docker as $SUDO_USER (if set) without sudo, add them to the docker group:"
echo "    sudo usermod -aG docker $SUDO_USER"
echo "    newgrp docker   # or log out and back in"
echo
echo "Verify with:  docker run --rm hello-world"
