#!/bin/bash

set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
export DEBIAN_FRONTEND=noninteractive

echo "==> Preparing ansible-playbook"

if ! dpkg -s git >/dev/null 2>&1; then
    echo "[*] Installing git..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq git
fi

if ! dpkg -s python3 >/dev/null 2>&1; then
    echo "[*] Installing python3..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq python3
fi

if ! dpkg -s pipx >/dev/null 2>&1; then
    echo "[*] Installing pipx..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq pipx
fi

if ! dpkg -s nano >/dev/null 2>&1; then
    echo "[*] Installing nano..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq nano
fi

echo "[*] Installing Ansible via pipx..."

if pipx list 2>/dev/null | grep -q "^package ansible "; then
    echo "[i] Existing Ansible installation found, reinstalling..."
    pipx uninstall ansible
fi

pipx install --include-deps ansible

echo "[*] Installing Ansible collections..."

ansible-galaxy collection install -r requirements.yml -f

echo "[*] Opening configuration..."

nano group_vars/all/main.yml

echo ""
echo "[+] Done."
echo ""
echo "Run the deployment with:"
echo "    ansible-playbook deploy-server.yml"
