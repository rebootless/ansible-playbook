# ansible-playbooks

> **A modular collection of Ansible playbooks for Debian- and Ubuntu-based systems.**
> Hardened server deployment, Docker services, reverse proxy configuration,
> monitoring stack, and infrastructure automation.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Ansible](https://img.shields.io/badge/Ansible-2.15%2B-EE0000?logo=ansible&logoColor=white)](https://www.ansible.com/)
[![Debian](https://img.shields.io/badge/Debian-Supported-A81D33?logo=debian&logoColor=white)](https://www.debian.org)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-Supported-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com)

All components are optional and can be enabled or disabled via `deploy_*` variables.

| Component       | Description                                   |
|-----------------|-----------------------------------------------|
| **firewalld**   | Firewall with public zone                     |
| **SSH**         | OpenSSH server + optional firewalld rule      |
| **fail2ban**    | SSH jail protection                           |
| **nginx**       | Reverse proxy (optional PHP, avahi, proxies)  |
| **Grafana**     | Grafana + Prometheus + Node Exporter (Docker) |
| **Portainer**   | Docker management UI (Docker)                 |
| **Filebrowser** | Web file manager (Docker)                     |

Docker-based services bind to `127.0.0.1` only and are exposed through nginx reverse proxies.

## Requirements

### Control Node

- `ansible` ≥ 2.15
- `python3`
- `git`
- `nano`
- Collections:
  - `community.docker` ≥ 3.10
  - `ansible.posix` ≥ 1.5

### Managed Node(s)

- Debian 12+ or Ubuntu 22.04+
- SSH access with sudo privileges
- Internet access

## Quick Start

```bash
bash -c 'command -v git >/dev/null || (sudo apt-get update -qq && sudo apt-get install -y -qq git); command -v ansible >/dev/null || (sudo apt-get update -qq && sudo apt-get install -y -qq ansible); command -v nano >/dev/null || (sudo apt-get update -qq && sudo apt-get install -y -qq nano); command -v python3 >/dev/null || (sudo apt-get update -qq && sudo apt-get install -y -qq python3); git clone https://github.com/rebootless/ansible-playbooks.git && cd ansible-playbooks && ansible-galaxy collection install -r requirements.yml -f && nano group_vars/all/main.yml && echo -e "\n>>> Edit complete. Run the deploy with:\n\n  ansible-playbook deploy-server.yml\n\n(or with tags, e.g. --tags nginx,grafana)\n"'
```

The one-liner:
1. Checks for `git`, `ansible`, `nano`, `python3` and installs missing ones via `apt`
2. Clones this repository
3. Installs required Ansible collections
4. Opens `group_vars/all/main.yml` in nano for you to fill in placeholders
5. Prints the command to start the deployment

## Manual Setup

```bash
git clone https://github.com/rebootless/ansible-playbooks.git
cd ansible-playbooks
ansible-galaxy collection install -r requirements.yml
```

Edit connection and service variables:

```bash
nano group_vars/all/main.yml
```

Required placeholders (replace all `<...>` values):

```yaml
ansible_host: "<SERVER_IP_OR_HOSTNAME>"
ansible_user: "<SSH_USER>"

nginx_domain: "<DOMAIN>"

grafana_user: "<GRAFANA_USER>"
grafana_password: "<GRAFANA_PASSWORD>"
grafana_domain: "<GRAFANA_DOMAIN>"

portainer_password: "<PORTAINER_PASSWORD>"
portainer_domain: "<PORTAINER_DOMAIN>"

filebrowser_user: "<FILEBROWSER_USER>"
filebrowser_password: "<FILEBROWSER_PASSWORD>"
filebrowser_domain: "<FILEBROWSER_DOMAIN>"
```

Enable or disable components using the `deploy_*` variables (all default to `true`).

## Deployment

Full stack:

```bash
ansible-playbook deploy-server.yml
```

Run selected components:

```bash
ansible-playbook deploy-server.yml --tags ssh,firewalld,docker,nginx,portainer
ansible-playbook deploy-server.yml --tags ssh,firewalld,docker,nginx,filebrowser
ansible-playbook deploy-server.yml --tags ssh,firewalld,docker,nginx,grafana
```

Dry-run / check mode:

```bash
ansible-playbook deploy-server.yml --check
```

## Inventory

Default inventory (`inventory/hosts.yml`) contains a single host `server-01`.  
Connection details are taken from `group_vars/all/main.yml`.

To manage multiple hosts, extend the inventory and move per-host variables to `host_vars/` or additional group_vars files.

## ansible.cfg Highlights

- Inventory: `inventory/hosts.yml`
- Roles path: `roles/`
- Privilege escalation: `become = True` (sudo)
- `host_key_checking = False` (convenient for first runs; consider enabling in production)
- YAML stdout callback

## Available Roles

### firewalld
Installs and starts firewalld, sets default zone to `public`.

### SSH
Installs OpenSSH server, enables the service, optionally opens the SSH service in firewalld when it is already active.

### fail2ban
Installs fail2ban and deploys a minimal `jail.local` that protects SSH.

### nginx
- Installs nginx
- Optional avahi-daemon (`.local` hostname) and PHP-FPM
- Creates site root and config under the configured domain
- Optional reverse-proxy locations for Grafana / Portainer / Filebrowser
- Optional firewalld rules for http / https / mdns
- Pulls in the `docker` role when any proxy is enabled

### grafana
Docker Compose stack:
- Grafana (admin credentials via secret file)
- Prometheus
- Node Exporter
- Auto-imports the “Node Exporter Full” dashboard (ID 19937)
- Supports `grafana_wipe_existing` to recreate from scratch

### portainer
Docker Compose Portainer CE with admin password from a secret file.  
Supports `portainer_wipe_existing`.

### filebrowser
Docker Compose File Browser.  
Bootstraps the admin user only on first run (when the database does not yet exist).  
Supports `filebrowser_wipe_existing`.

### docker (shared role)
Installs `docker.io` + `docker-compose` and starts the Docker service.  
Used by nginx (when proxies are enabled) and by the three Docker-based roles.

## Safety Notes

- Secrets (`*_password`) are written to files with mode `0600` and use `no_log` where appropriate. Prefer Ansible Vault for production.
- Docker services listen on localhost only; expose them exclusively through nginx (or another reverse proxy).
- No TLS/Let’s Encrypt is configured out of the box — add certificates before exposing services to the internet.
- `host_key_checking = False` is set for convenience; re-enable it after the first successful connection.

## License

This project is licensed under the **GNU General Public License v3.0** — see the [LICENSE](LICENSE) file for details.
