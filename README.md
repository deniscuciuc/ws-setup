# Ubuntu workstation setup

One setup for Ubuntu **26.04 LTS, GNOME, x86_64**: enhanced Bash, VS Code, Node/.NET/Python, Claude and Codex, rootless Podman, database clients, Brave and everyday apps. Kitty is configured alongside Ubuntu's default terminal.

**Candidate status:** implementation and automated checks are tracked in [TESTING.md](docs/TESTING.md). This is not yet a certification to erase Windows: the full Desktop VM and physical-PC checklist must pass first. Test local candidate repositories together before publishing either change.

## Start here

For explanations of every part of the workstation and everyday usage, read the [Workstation Handbook](docs/handbook/README.md). The [documentation index](docs/README.md) links all migration, customization and troubleshooting procedures.

1. **Back up and install Ubuntu:** follow [Windows migration](docs/MIGRATION.md). Verify the external backup, select passphrase encryption on the Samsung SSD, and preserve the Archive HDD.
2. **Provision from Ubuntu's terminal**, after both repository changes are published:

   ```bash
   sudo apt update && sudo apt install -y git
   git clone https://github.com/deniscuciuc/ws-setup.git ~/.local/share/ws-setup
   bash ~/.local/share/ws-setup/setup.sh
   ```

3. **Reboot, sign in and verify:** complete the generated report and [short checklist](docs/SETUP_CHECKLIST.md), then:

   ```bash
   bash ~/.local/share/ws-setup/setup.sh doctor
   ```

The normal-user installer asks for sudo access. It installs tools and settings; it never partitions disks, restores private keys, signs in to services, or starts project databases.

For a candidate checkout, use `bash setup.sh --dotfiles-source ../dotfiles`. The matching source is checked before application. `bootstrap.sh` is an optional download-and-run entry point once published; the clone workflow above is easiest to inspect and troubleshoot.

## Everyday commands

```bash
./setup.sh plan                         # Read-only prerequisites and modules
./setup.sh install                      # Same as ./setup.sh
./setup.sh doctor                       # Read-only status, drift and diagnostics
./setup.sh update                       # Update components this setup already manages
./setup.sh --profile core               # No graphical applications or GPU changes
./setup.sh --only runtimes              # Includes base, shell and dotfiles dependencies
./setup.sh --dotfiles-source ../dotfiles # Apply a candidate/local source without fetching it
```

Core includes native Podman and therefore needs a real systemd user login. Container-only tests select the compatible modules explicitly. `plan`/`doctor` do not authenticate with sudo, fetch repositories, install software or start workloads.

## What belongs where

| Repository | Owns |
|---|---|
| `ws-setup` | Packages, verified downloads, runtime installation, drivers, desktop integration, diagnostics and migration documentation |
| [dotfiles](https://github.com/deniscuciuc/dotfiles) | Bash, prompt, Git, Kitty, VS Code, AI defaults, Podman settings and backup helpers through chezmoi |

Read the [application catalog](docs/APPLICATIONS.md), [customization/update guide](docs/CUSTOMIZATION.md), [Podman guide](docs/PODMAN.md), and [hardware/performance guide](docs/PERFORMANCE.md). Shell shortcuts and Linux backup setup live in the dotfiles repository.

GitKraken, Discord and ONLYOFFICE are included. DBeaver is listed explicitly in `packages/database-gui.txt`. The workstation also includes Cloudflare Tunnel, OpenTofu and system/network utilities. See the [tool guide](docs/TOOLS.md) for practical commands, project-local Wrangler, and opt-in `devops`/`diagnostics` modules.

Bitwarden CLI is included even in core. Follow [SSH migration](docs/SSH_MIGRATION.md) to move existing Windows keys into your vault and use the desktop SSH agent on Ubuntu.

The workstation's [maintenance module](docs/MAINTENANCE.md) checks disk space, attempts external backups daily and verifies them weekly. pnpm reuses a filesystem-local store; `ws-storage` checks sharing and reports worktree/storage usage. No automated cache or volume deletion is configured.

The [audit summary](docs/AUDIT.md) maps the original problems to implemented changes and remaining migration checks.

## Results and recovery

Each run writes a summary to `~/.local/state/ws-setup/latest-report.md`, per-module logs under `reports/`, and configuration backups under `backups/`. Paths follow `XDG_STATE_HOME` if set. Downloaded assets are cached beneath `~/.cache/ws-setup`.

Required failures return a nonzero exit code; dependent modules are marked blocked while independent modules continue. Fix the reported cause and rerun the same command. Existing Docker installations are reported as conflicts; their data is never removed.

See [testing](docs/TESTING.md) for Podman/Docker test commands and the release gate. Historical documents in `docs/superpowers/` are archived designs, not instructions for the current implementation.
