# 8. Configuration and package reference

[Index](README.md) · Previous: [Maintenance](07-maintenance.md)

## Where installed settings live

Paths below are in your Ubuntu home unless absolute. The dotfiles repository uses chezmoi source names such as `private_dot_config` to render `.config`; edit the source through the managed workflow rather than assuming source and installed filenames are identical.

| Installed path | Purpose | Ownership |
|---|---|---|
| `~/.bashrc`, `~/.profile` | Include shared interactive/login configuration while preserving unrelated content | Managed includes |
| `~/.config/bash/` | Interactive shell behavior and aliases | Dotfiles; `local.bash` is private |
| `~/.config/shell/environment.sh` | User PATH, editor variables and default Podman endpoint | Dotfiles |
| `~/.config/shell/local.sh` | Personal environment overrides | Private, untracked |
| `~/.config/environment.d/99-workstation.conf` | PATH/editor/Podman environment for user services and desktop apps | Dotfiles; needs a new login |
| `~/.config/kitty/` | Terminal font, theme, tabs and keybindings | Dotfiles |
| `~/.config/starship.toml` | Prompt appearance and modules | Dotfiles |
| `~/.config/mise/` | Global runtime baseline | Dotfiles; project versions can override |
| `~/.config/pnpm/config.yaml` | Automatic package imports and offline-cache preference | Dotfiles; project lockfiles remain authoritative |
| `~/.config/systemd/user/ws-*.timer`, `ws-*.service` | Storage/backup schedules and execution limits | ws-setup maintenance module |
| `~/.local/state/ws-maintenance/` | Backup/check success markers and alert state | Private runtime state |
| `~/.config/Code/User/settings.json` | VS Code editing, terminal and container behavior | Dotfiles |
| `~/.gitconfig` | Portable Git behavior | Dotfiles |
| `~/.gitconfig.local` | Machine identity/credential overrides | Private, untracked |
| `~/.config/containers/` | Podman/Compose configuration | Dotfiles |
| `~/.claude/settings.json`, `~/.codex/config.toml` | Portable AI defaults | Dotfiles with private permissions; authentication remains separate |
| `~/.config/workstation/backup-targets.txt`, `backup-excludes.txt` in the same directory | Backup selection | Dotfiles |
| `~/.config/workstation/backup.conf` | External disk/repository/password-file settings | Private, untracked |
| `~/.ssh/` | Host configuration, known hosts and selected public/private keys | Private recovery data, not managed in Git |
| `~/.local/bin/` | User commands, pinned tools and helper scripts | Provisioning and dotfiles, depending on the command |
| `~/.local/share/fonts/JetBrainsMono/` | Nerd Font files | Provisioning |
| `/etc/apt/sources.list.d/`, `/etc/apt/keyrings/` | Signed vendor package sources and trust keys | Provisioning/system operations |

GNOME settings live in its settings database rather than a plain dotfile. Setup records changed values in the run's `gsettings-before.tsv`. Snap/Flatpak app data and vendor authentication stores are separate from portable settings. Never copy all of them across operating systems without checking compatibility.

## Where to change the setup source

| Repository path | Edit this to change |
|---|---|
| `setup.sh` | Public commands, options, preflight and reporting |
| `lib/catalog.sh` | Profiles, module ordering and dependencies |
| `lib/modules.sh` | Component installation logic |
| `lib/desktop.sh` | GNOME preferences, desktop integration and driver flow |
| `lib/doctor.sh` | Read-only installation checks |
| `packages/*.txt` | Explicit package/extension inventory |
| `config/versions.sh` | Runtime baseline versions and default dotfiles source |
| `config/assets.lock.json` | Exact standalone downloads, versions and checksums |
| `scripts/lock-assets.py` | Maintainer-only upstream version/checksum resolution |
| `tests/` | Regression and disposable-environment acceptance checks |

APT manifest comments identify standalone assets installed beside package-manager components. For example, DBeaver is explicitly in `packages/database-gui.txt`; GitKraken/Discord are pinned assets referenced from the apps inventory. [APPLICATIONS.md](../APPLICATIONS.md) is the installation-source catalog.

## Supporting packages: why they are installed

You generally do not configure these individually. They support commands and workflows described in earlier chapters.

| Package/tool | Purpose or useful command |
|---|---|
| `build-essential` | Compiler, make and native build prerequisites for project dependencies |
| `make` | Explicit GNU Make installation for project Makefiles; use `make` or `make TARGET` |
| `python3`, `python3-venv` | Ubuntu/provisioning Python and standard virtual-environment support; uv manages project Python |
| `ca-certificates` | Trusted certificate authorities for HTTPS connections |
| `curl`, `wget` | HTTP/download clients; installer downloads are checksum-verified |
| `file` | Identify an unknown file's format: `file PATH` |
| `fontconfig` | Font discovery/cache used by terminal/editor font installation |
| `gnupg` | Package signing-key processing and GPG workflows |
| `software-properties-common` | Ubuntu repository-management support |
| `shellcheck` | Analyze shell scripts: `shellcheck script.sh` |
| `shfmt` | Format shell scripts; `shfmt -d script.sh` previews differences |
| `tar` | Bundle/list/extract archives; `tar -tf archive.tar` lists contents |
| `gzip` via Ubuntu, `bzip2`, `xz-utils` | Common archive compression formats |
| `zip`, `unzip` | ZIP creation/extraction; `unzip -l archive.zip` lists contents |
| `util-linux` | Core Linux utilities, including mount inspection and the install lock (`flock`) |
| `procps`, `sysstat` | Process, memory, CPU and I/O diagnostics |
| `uidmap` | Rootless container UID/GID mapping helpers |
| `passt`, `slirp4netns` | Userspace network support for rootless containers |
| `fuse-overlayfs` | Filesystem support used by compatible rootless container storage configurations |
| `flatpak` | User-scoped Podman Desktop distribution and updates |
| `snapd` | Stable Snap distribution for selected everyday apps |
| `wl-clipboard` | Wayland clipboard commands: `wl-copy`, `wl-paste` |
| `xdg-utils` | Desktop/browser/file associations and opening URLs/files |
| `desktop-file-utils` | Desktop launcher registration/validation support |
| `libnotify-bin` | Desktop notifications for actionable maintenance conditions |
| `ubuntu-drivers-common`, `pciutils`, `vulkan-tools`, `mesa-utils` | Driver selection, device identification and graphics diagnostics |

The command-facing base tools are covered in [Terminal](02-terminal.md), [Development](03-development.md), [System/network](06-system-network.md) and [Maintenance](07-maintenance.md). Database packages are client-only: `postgresql-client`, `default-mysql-client`, `sqlite3`, `redis-tools`, plus locked MongoDB and SQL Server clients.

## Optional additions and deliberate boundaries

- **Syncthing:** consider for peer-to-peer file synchronization; synchronized deletions are not a backup strategy.
- **rclone:** consider for moving files to/from cloud storage; configure remotes and encryption deliberately.
- **Incoming SSH:** add a server only when this workstation needs remote logins.
- **Cockpit:** optional browser-based system management, mainly useful when administering machines remotely.
- **WARP:** optional Cloudflare device connectivity; it has a different role from cloudflared and Wrangler.
- **Additional SDKs/CUDA/GPU containers:** add for a specific project requirement and test against the installed driver/runtime.

These are documented possibilities, not installed defaults or hidden background services. Check the linked specialized guides and current vendor instructions before adding them. Keep one intentional installation source per application.

## Keep documentation current

When adding a package or module, update its manifest, source catalog and the relevant handbook chapter with its purpose, first-use action, configuration location and validation limits. When changing a default, describe the resulting behavior rather than leaving old instructions beside it. Record real test outcomes in [TESTING.md](../TESTING.md); do not upgrade a pending desktop/hardware check to passed based on a command-presence check.
