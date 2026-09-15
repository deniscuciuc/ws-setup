# 1. Understand the setup

[Handbook index](README.md) · Next: [Terminal](02-terminal.md)

## Two repositories, one workstation

`ws-setup` installs software, configures software sources, applies desktop integration, selects drivers and reports failures. `dotfiles` supplies portable files in your home directory through **chezmoi**, a tool that renders and applies a version-controlled configuration source.

Think of provisioning as furnishing the workstation and dotfiles as arranging the tools you use. A software package belongs in ws-setup; a reusable Bash alias belongs in dotfiles; a secret or machine-specific setting belongs in a private local file.

## Profiles and modules

| Module | Purpose | Included |
|---|---|---|
| `base` | Git, essential CLI tools, build prerequisites, backups, Bitwarden CLI and SSH migration helper | Core and workstation |
| `shell` | Starship prompt, ble.sh editing and shell prerequisites | Both |
| `dotfiles` | Apply portable settings; migrate the old setup-owned Zsh launcher to Bash | Both |
| `runtimes` | .NET, Node/mise/Corepack and Python/uv | Both |
| `ai` | Claude Code and Codex CLIs | Both |
| `containers` | Rootless Podman, Docker command bridge, Compose and user socket | Both |
| `database` | SQL, MongoDB and Redis command-line clients | Both |
| `tools` | Cloudflare, OpenTofu, YAML/tasks and extra network utilities | Workstation |
| `apps` | Browsers, editors, AI desktop apps, office, communication and gaming | Workstation |
| `database-gui` | DBeaver, Compass and Bruno | Workstation |
| `desktop` | Kitty, fonts, GNOME preferences, extensions and Podman Desktop | Workstation |
| `drivers` | Ubuntu-recommended NVIDIA driver and graphics diagnostics | Workstation |
| `maintenance` | Daily storage/backup checks and weekly backup integrity checks | Workstation; core can opt in |
| `devops` | SOPS, age, Ansible and Trivy | Opt-in |
| `diagnostics` | Wireshark and TShark | Opt-in |

Module selection includes dependencies. For example, `./setup.sh --only runtimes` also brings in the base, shell and dotfiles prerequisites. Core omits graphical applications, but its Podman module still needs a normal systemd user session.

```bash
./setup.sh plan --only tools
./setup.sh --only tools
./setup.sh --only devops,diagnostics
```

`--only` selects a subset, rather than adding it to the full workstation in that invocation. Optional modules can be installed after the default setup.

## What provisioning changes

- Installs system packages through sudo and standalone user tools beneath `~/.local/bin`.
- Adds signed software repositories and verifies locked standalone download checksums.
- Enables the rootless Podman user socket, configures Bash and applies dotfiles.
- Sets Brave as default browser; applies dark appearance, reduced GNOME animations and the configured monospace font.
- Adds selected launcher favorites and VS Code extensions.
- Records reports and configuration backups under `~/.local/state/ws-setup`.

Rerunning is intended to converge on the selected configuration: existing repositories/settings are reused, and verified current standalone assets are skipped. A required failure produces a failed report and nonzero exit code. Read the report rather than assuming all later modules ran.

## What you still do

You select and encrypt the Ubuntu installation disk in the installer, verify backups, restore data, complete account sign-ins and test physical hardware. Firmware/Secure Boot prompts, Bitwarden unlocking and service credentials need your participation. Project databases start when you launch their project stack. Incoming SSH, CUDA, WARP, Cockpit, Syncthing and rclone are not enabled by default.

ONLYOFFICE is the chosen office suite. A preinstalled LibreOffice is removed using the documented procedure only after you verify opening and saving a representative document. See [the office transition](../TOOLS.md).

## Setup commands

| Command | Use it when |
|---|---|
| `install`, or no command | Setting up or repairing selected components |
| `plan` | Checking intended modules and platform/session prerequisites without installation |
| `doctor` | Inspecting installed packages, commands and selected configuration without starting workloads |
| `update` | Updating previously managed components after reviewing repository changes |
| `--dotfiles-source ../dotfiles` | Testing or applying a local dotfiles checkout |

An unqualified update follows successful module receipts, including opt-ins. Use `--only` to restrict it. It does not install missing components; use `install` to repair those. Keep both repositories together when testing unpublished changes.
