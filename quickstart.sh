#!/bin/bash

set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
export DEBIAN_FRONTEND=noninteractive

echo ""
echo "==> Preparing ansible-playbook"

echo ""
echo "[1/6] Installing git..."
if ! dpkg -s git >/dev/null 2>&1; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq git
else 
    echo "git already installed."
fi

echo ""
echo "[2/6] Installing python3..."
if ! dpkg -s python3 >/dev/null 2>&1; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq python3
else
    echo "python3 already installed."
fi

echo ""
echo "[3/6] Installing pipx..."
if ! dpkg -s pipx >/dev/null 2>&1; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq pipx
else 
    echo "pipx already installed."
fi

echo ""
echo "[4/6] Installing nano..."
if ! dpkg -s nano >/dev/null 2>&1; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq nano
else
    echo "nano already installed."
fi

echo ""
echo "[5/6] Installing ansible via pipx..."

if pipx list 2>/dev/null | grep -q "^package ansible "; then
    echo "Existing ansible installation found, reinstalling..."
    pipx uninstall ansible
fi

pipx install --include-deps ansible

echo ""
echo "[6/6] Installing Ansible collections..."

ansible-galaxy collection install -r requirements.yml -f

echo "Opening configuration..."

nano group_vars/all/main.yml

echo ""
echo "==> Done"

echo ""
echo "Run the deployment with:"
echo "  ansible-playbook deploy-server.yml"
