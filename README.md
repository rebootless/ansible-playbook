# Ansible-Playbook

> **A modular Ansible playbook for Debian- and Ubuntu-based systems.**
> Hardened server deployment, Docker services, reverse proxy configuration,
> monitoring stack, and infrastructure automation.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Ansible](https://img.shields.io/badge/Ansible-2.15%2B-EE0000?logo=ansible&logoColor=white)](https://www.ansible.com/)
[![Debian](https://img.shields.io/badge/Debian-Supported-A81D33?logo=debian&logoColor=white)](https://www.debian.org)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-Supported-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com)

All components are optional and can be enabled or disabled via `deploy_*` variables.

| Component       | Description                                   |
|-----------------|-----------------------------------------------|
| **firewall**    | firewalld or ufw (pick one via `firewall_backend`) |
| **SSH**         | OpenSSH server + optional firewall rule       |
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
  - `community.general` ≥ 8.0

### Managed Node(s)

- Debian 12+ or Ubuntu 22.04+
- SSH access with sudo privileges
- Internet access

## Quick Start

```bash
git clone https://github.com/rebootless/ansible-playbook.git && cd ansible-playbook && chmod +x quickstart.sh && ./quickstart.sh
```

The quickstart script:

1. Installs `git`, `python3`, `pipx`, and `nano` if they are missing
2. Reinstalls the latest Ansible via `pipx` (including all CLI tools)
3. Installs the required Ansible collections
4. Opens `group_vars/all/main.yml` in `nano` for configuration

After editing the configuration, deploy the full stack:

```bash
ansible-playbook deploy-server.yml
```

## Manual Setup

```bash
git clone https://github.com/rebootless/ansible-playbook.git
cd ansible-playbook
ansible-galaxy collection install -r requirements.yml
```

Edit connection and service variables:

```bash
nano group_vars/all/main.yml
```

Required placeholders (replace all `<...>` values):

```yaml
ansible_host: "<SERVER_IP_OR_HOSTNAME>"
ansible_user: "<ANSIBLE_USER>"
ansible_password: "<ANSIBLE_PASSWORD>"
ansible_become_password: "<ANSIBLE_BECOME_PASSWORD>"

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

Run selected components (for example):

```bash
ansible-playbook deploy-server.yml --tags ssh,firewall,fail2ban,docker,nginx,portainer
ansible-playbook deploy-server.yml --tags ssh,firewall,fail2ban,docker,nginx,filebrowser
ansible-playbook deploy-server.yml --tags ssh,firewall,fail2ban,docker,nginx,grafana
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

### firewall (firewalld / ufw)
Controlled by `firewall_backend` (`firewalld` or `ufw`, default `firewalld`) and `deploy_firewall`.
`deploy-server.yml` runs whichever role matches `firewall_backend`.

Before installing anything, `deploy-server.yml`'s pre_tasks check installed packages: if the
*other* backend is already present on the host, the run fails with an explanation instead of
installing a second, conflicting firewall. If the *selected* backend is already installed,
installation is simply skipped (idempotent) and configuration proceeds.

- **firewalld** — installs and starts firewalld, sets default zone to `public`.
- **ufw** — installs ufw, sets default policy (deny incoming / allow outgoing), enables it.

### SSH
Installs OpenSSH server, enables the service. If `ssh_allow_firewall` is true, detects whichever
firewall (firewalld and/or ufw) is already installed and active on the host and opens the SSH
service/port on it — independent of `firewall_backend`, so it also works when `deploy_firewall`
is disabled but a firewall already exists.

### fail2ban
Installs fail2ban and deploys a minimal `jail.local` that protects SSH.

### nginx
- Installs nginx
- Optional avahi-daemon (`.local` hostname) and PHP-FPM
- Creates site root and config under the configured domain
- Optional reverse-proxy locations for Grafana / Portainer / Filebrowser
- Optional firewall rules for http / https / mdns, on whichever of firewalld/ufw is
  detected active on the host (same detection approach as the SSH role; nginx itself
  never installs a firewall)
- Pulls in the `docker` role when any proxy is enabled

### grafana
Docker Compose stack:
- Grafana (admin credentials via secret file)
- Prometheus
- Node Exporter
- Auto-imports the “Node Exporter Full” dashboard (ID 19937)
- Supports `grafana_wipe_existing` to recreate from scratch
- Image versions are pinned via `grafana_image_version`, `prometheus_image_version`,
  and `node_exporter_image_version` (defaults are the latest stable releases as of
  July 2026 — check upstream for newer ones before deploying; avoid `latest` in production)

### portainer
Docker Compose Portainer CE with admin password from a secret file.  
Supports `portainer_wipe_existing`.  
Image version is pinned via `portainer_image_version` (default is the latest LTS release
as of July 2026 — avoid `latest` in production).

### filebrowser
Docker Compose File Browser.  
Bootstraps the admin user only on first run (when the database does not yet exist).  
Supports `filebrowser_wipe_existing`.  
Image version is pinned via `filebrowser_image_version` (default is the latest stable
release as of July 2026 — avoid `latest` in production).

### docker (shared role)
Installs Docker Engine (`docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`,
`docker-compose-plugin`) from Docker's official apt repository, as recommended by Docker's
own install docs, rather than the distro-packaged `docker.io`/`docker-compose`. Works the same
way on Debian and Ubuntu (repository URL is picked from `ansible_distribution`). Starts the
Docker service.  
Used by nginx (when proxies are enabled) and by the three Docker-based roles.

## Safety Notes

- Secrets (`*_password`) are written to files with mode `0600` and use `no_log` where appropriate. Prefer Ansible Vault for production.
- Docker services listen on localhost only; expose them exclusively through nginx (or another reverse proxy).
- No TLS/Let’s Encrypt is configured out of the box — add certificates before exposing services to the internet.
- `host_key_checking = False` is set for convenience; re-enable it after the first successful connection.

## License

This project is licensed under the **GNU General Public License v3.0** — see the [LICENSE](LICENSE) file for details.
