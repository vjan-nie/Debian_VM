# 🚀 Inception Debian VM Automator

Zero-touch deployment of a headless Debian VM in VirtualBox, pre-provisioned for the 42 **Inception** project. It builds the VM, installs the OS unattended, and on first boot sets up Docker, the build tooling, and a host-only network — so you can open the WordPress site in your host browser at `https://<your-domain>` once the stack is up.
> Built to host the [Inception](https://github.com/vjan-nie/Inception) project.
(But adjustable to meet any other needs!)

## What you get

- A VirtualBox VM with two adapters: **NAT** (internet + SSH) and **host-only** (a fixed IP for browser access).
- Unattended Debian install driven by a preseed file (no clicking through the installer).
- First-boot provisioning: Docker CE + Compose plugin, `make`, `git`, the VM user added to the `docker` group, and the static host-only IP — with no manual steps.
- An `ssh inception` alias and a host `/etc/hosts` entry so `https://<domain>` resolves to the VM.

## Quick start

1. Edit `config.sh` (see the table below).
2. `make`
3. When provisioning finishes, log in, run Inception, and open the site in your host browser.

```bash
make            # create + install + provision the VM
ssh inception   # log into the VM
# inside the VM:
git clone <your Inception repo> && cd inception && make
# then, on the host browser: https://<your-domain>  (accept the self-signed cert)
```

## Configuration — `config.sh`

Everything a user needs to change lives in one file at the repo root; every script sources it.

| Variable | What it sets | Notes |
| :--- | :--- | :--- |
| `VM_NAME` | VirtualBox VM name | |
| `VM_USER` | Linux user inside the VM | also the `ssh inception` target |
| `VM_PASSWORD` | user + root password for the install | disposable VM; a weak local password is fine |
| `DOMAIN` | the site domain | **must match** `DOMAIN_NAME` in the Inception repo, nginx's `server_name`, and the TLS cert CN |
| `HOSTONLY_HOST_IP` | host side of the host-only network | default `192.168.56.1` (inside VirtualBox's default-allowed range) |
| `HOSTONLY_VM_IP` | the VM's fixed IP for browser access | the host `/etc/hosts` maps `DOMAIN` to this |
| `SSH_PORT` | host port forwarded to the VM's SSH | default `4242` |

### Where do the WordPress / MariaDB passwords go?

**Not in this repo.** This project provisions the *VM and its OS only*. The WordPress and database credentials belong to the **Inception** project itself: set them there in `srcs/.env` (non-sensitive values like domain, DB name, admin username) and `secrets/*.txt` (the actual passwords). This repo only needs the VM-level values in `config.sh` above.

## How it works

`make` runs three stages:

1. **`create_vm.sh`** — builds the virtual hardware: NAT + host-only NICs, disk, and the install ISO.
2. **`inject_keys.sh`** — generates the preseed and first-boot script from their templates (via `envsubst`, using your `config.sh`), serves them over a temporary HTTP server, and "ghost-types" the boot parameters so the installer runs unattended.
3. **`setup_host.sh`** — configures the host: the `ssh inception` alias and the `/etc/hosts` entry.

The preseed drops a one-shot systemd service that, on first boot, waits for the network, assigns the static host-only IP, and installs Docker + tooling — then disables itself so it only runs once.

Browser access uses the **host-only network**: `DOMAIN → HOSTONLY_VM_IP:443 →` NGINX inside the VM. No privileged host-port binding is required.

## Commands

| Command | Action |
| :--- | :--- |
| `make` | create, install and provision the VM |
| `make up` / `make down` | start / graceful stop |
| `make clean` | power off, free ports, remove temp files |
| `make fclean` | unregister and wipe the VM and its disks |
| `make re` | `fclean`, then a full rebuild |

## Accessing the site

`setup_host.sh` adds `HOSTONLY_VM_IP DOMAIN` to the host `/etc/hosts`. Once Inception's stack is running inside the VM, open `https://<DOMAIN>` and accept the self-signed certificate warning. If you reach the machine remotely instead of sitting at it, tunnel the port and add the hosts entry on your laptop:

```bash
ssh -L 443:localhost:443 user@machine     # plus: HOSTONLY_VM_IP <domain> in your laptop's /etc/hosts
```

## Acknowledgements

Inspired by LESdylan's work — https://github.com/LESdylan/setup_arch_linux

## AI usage

AI assistants were used as collaborative tools, with every change reviewed and understood before committing — e.g. auditing and adversarial review, the host-only networking and first-boot provisioning design, and the parameterization refactor.