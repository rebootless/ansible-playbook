# Ansible-Playbook

**Modular Ansible playbook for Debian and Ubuntu.**

Automates server hardening, Docker services, nginx reverse proxies, monitoring, and infrastructure configuration.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ansible](https://img.shields.io/badge/Ansible-2.15%2B-EE0000?logo=ansible&logoColor=white)](https://www.ansible.com/)
[![Debian](https://img.shields.io/badge/Debian-12%20%7C%2013-A81D33?logo=debian&logoColor=white)](https://www.debian.org/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20%7C%2024.04%20%7C%2026.04-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)

All components can be enabled or disabled via `deploy_*` variables.

| Component | Description |
|---|---|
| Firewall | firewalld or ufw |
| SSH | OpenSSH and optional firewall rules |
| fail2ban | SSH protection |
| nginx | Reverse proxy, optional PHP-FPM and Avahi |
| Grafana | Grafana, Prometheus, Node Exporter (Docker) |
| Portainer | Docker management UI |
| Filebrowser | Web file manager |

Docker services bind to `127.0.0.1` and are exposed through nginx reverse proxies.

## Requirements

**Control node:** Ansible ≥ 2.15, Python 3, Git, nano.

Required collections: `community.docker` ≥ 3.10, `ansible.posix` ≥ 1.5, `community.general` ≥ 8.0.

**Managed nodes:** Debian 12+ or Ubuntu 22.04+, SSH access with sudo privileges, and internet access.

## Quick Start

```bash
git clone https://github.com/rebootless/ansible-playbook.git
cd ansible-playbook
chmod +x quickstart.sh
./quickstart.sh
```

The script installs missing prerequisites, installs the latest Ansible via pipx, installs required collections, and opens `group_vars/all/main.yml` for configuration.

After configuring, deploy:

```bash
ansible-playbook deploy-server.yml
```

## Manual Setup

```bash
git clone https://github.com/rebootless/ansible-playbook.git
cd ansible-playbook
ansible-galaxy collection install -r requirements.yml
nano group_vars/all/main.yml
```

Replace all `<...>` placeholders, including:

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

All `deploy_*` variables default to `true`.

## Deployment

Deploy everything:

```bash
ansible-playbook deploy-server.yml
```

Deploy selected components:

```bash
ansible-playbook deploy-server.yml --tags ssh,firewall,fail2ban,docker,nginx,portainer
ansible-playbook deploy-server.yml --tags ssh,firewall,fail2ban,docker,nginx,filebrowser
ansible-playbook deploy-server.yml --tags ssh,firewall,fail2ban,docker,nginx,grafana
```

Check mode:

```bash
ansible-playbook deploy-server.yml --check
```

## Inventory and Configuration

The default inventory, `inventory/hosts.yml`, contains `server-01`. Connection settings are defined in `group_vars/all/main.yml`. For multiple hosts, use `host_vars/` or additional `group_vars/` files.

`ansible.cfg` configures the inventory, `roles/` path, sudo privilege escalation, and YAML output. Host key checking is disabled for convenience; enable it in production.

## Available Roles

### Firewall

Select `firewalld` or `ufw` using `firewall_backend` (default: `firewalld`) and `deploy_firewall`.

Pre-tasks prevent installing a second, conflicting firewall. If the other backend is installed, deployment fails with an explanation. If the selected backend is already installed, installation is skipped.

- **firewalld:** starts the service and sets the default zone to `public`.
- **ufw:** sets default policies to deny incoming and allow outgoing traffic, then enables the firewall.

### SSH

Installs and enables OpenSSH. If `ssh_allow_firewall` is enabled, opens the configured SSH service/port in any detected, active firewalld or ufw instance, independently of `firewall_backend` and `deploy_firewall`.

### fail2ban

Installs fail2ban and configures a minimal SSH jail.

### nginx

Installs nginx, creates the site root and virtual host, and optionally configures Avahi (`.local` hostnames), PHP-FPM, reverse proxies, and HTTP/HTTPS/mDNS firewall rules. It never installs a firewall. The Docker role is included when a proxy is enabled.

### Docker

Installs Docker Engine and Compose plugins from Docker's official APT repository on Debian and Ubuntu, then starts Docker. Used by nginx proxies and all Docker-based services.

### Grafana

Docker Compose stack with Grafana, Prometheus, and Node Exporter. Imports the Node Exporter Full dashboard (ID `19937`). Supports `grafana_wipe_existing` and configurable image versions.

### Portainer

Docker Compose deployment of Portainer CE. Admin credentials come from a secret file. Supports `portainer_wipe_existing` and configurable image versions.

### Filebrowser

Docker Compose deployment of File Browser. Creates the admin user on first run only. Supports `filebrowser_wipe_existing` and configurable image versions.

## Security

- Passwords are stored in files with mode `0600`; sensitive tasks use `no_log` where appropriate. Use Ansible Vault for production secrets.
- Docker services bind to localhost and should be exposed only through a reverse proxy.
- TLS certificates and Let's Encrypt are not configured by default.
- Re-enable SSH host key checking for production deployments.

## License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.
