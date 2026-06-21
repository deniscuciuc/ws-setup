# `ws-setup` Design Specification

**Goal:** Provide an automated, idempotent provisioning system that can reproduce the current Ubuntu 26.04 developer workstation on a new laptop, with a fallback manual checklist for steps that cannot or should not be automated.

**Target repo:** `github.com/deniscuciuc/ws-setup`  
**Local path:** `/home/dcuciuc/Development/repos/deniscuciuc/ws-setup`

---

## 1. Context

- The current machine runs **Ubuntu 26.04 LTS (resolute)** with a GNOME desktop.
- Dotfiles are managed by **chezmoi** from `github.com/deniscuciuc/dotfiles.git`; the source state lives at `/home/dcuciuc/.local/share/chezmoi`.
- A separate `/home/dcuciuc/dotfiles` directory exists but is an uncommitted stale clone and is **not** the active dotfiles source.
- The user wants the new laptop to have the same packages, configs, and applications as the current machine.
- Secrets (SSH keys, GPG keys, passwords, API tokens) are **out of scope** for automation; they will be handled via a manual checklist.

## 2. Scope

### In scope
- Bootstrap script that prepares a fresh Ubuntu 26.04 machine and runs the Ansible playbook.
- Ansible playbook with roles for:
  - System prerequisites (`git`, `curl`, `python3`, `ansible` itself).
  - APT package installation from a curated YAML list.
  - Snap package installation from a curated YAML list.
  - Chezmoi installation and dotfiles application.
  - Developer tools that are not packaged via apt/snap (e.g., `nvm`, `pyenv`, .NET install script).
  - Generation of a post-provisioning manual checklist.
- Manual checklist markdown file covering secrets, logins, and non-automatable apps.
- VM-based testing using Vagrant + libvirt or VirtualBox to validate the playbook on a clean Ubuntu 26.04 image.

### Out of scope (for v1)
- GNOME settings, themes, keyboard shortcuts, and mouse/touchpad configuration.
- Backing up and restoring user data files.
- Automated handling of secrets, 2FA, or paid/proprietary software licenses.
- Multi-distro support; the playbook targets Ubuntu 26.04 only.
- CI/CD pipelines; testing is done locally via VM.

## 3. Architecture

The solution is a single Ansible playbook wrapped by a shell bootstrap script. The playbook is divided into small, single-purpose roles. All machine-specific data lives in `group_vars/all/*.yml`. The dotfiles remain in their existing chezmoi-managed repo; this repo only orchestrates installation and configuration.

```
ws-setup/
├── bootstrap.sh              # One-liner entry point for a fresh laptop
├── ansible.cfg               # Ansible configuration (inventory, roles path, etc.)
├── inventory/
│   └── localhost.yml         # Localhost target with python interpreter hint
├── playbook.yml              # Main entry point; lists roles in order
├── roles/
│   ├── bootstrap/            # Ensure ansible deps and sudo access
│   ├── packages_apt/         # Install apt packages from YAML list
│   ├── packages_snap/        # Install snap packages from YAML list
│   ├── dotfiles/             # Install chezmoi and apply deniscuciuc/dotfiles
│   ├── devtools/             # Install non-apt/snap developer tools
│   └── manual_checklist/     # Render and display SETUP_CHECKLIST.md
├── group_vars/
│   └── all/
│       ├── apt_packages.yml  # Curated apt package list
│       ├── snap_packages.yml # Curated snap package list
│       └── vars.yml          # URLs, versions, and other constants
└── docs/
    └── SETUP_CHECKLIST.md    # Human-readable post-provisioning checklist
```

## 4. Bootstrap Flow

1. User runs `bootstrap.sh` on a fresh Ubuntu 26.04 install.
2. `bootstrap.sh`:
   - Updates apt cache.
   - Installs `git`, `curl`, `software-properties-common`, `python3`, `python3-pip`, and `ansible` if missing.
   - Clones `github.com/deniscuciuc/ws-setup.git` into `~/.local/share/ws-setup` (or updates if already present).
   - Changes into the repo directory.
   - Runs `ansible-playbook playbook.yml --ask-become-pass`.
3. Ansible applies each role idempotently.
4. The `manual_checklist` role writes `~/Desktop/SETUP_CHECKLIST.md` and prints it to the terminal.

## 5. Roles

### `bootstrap`
- Ensure the playbook can run:
  - `python3` is installed.
  - `ansible` Python package is installed (via apt).
  - `sudo` access is available (Ansible will prompt for password).

### `packages_apt`
- Read `apt_packages` list from `group_vars/all/apt_packages.yml`.
- Use the `ansible.builtin.apt` module to install each package.
- Update apt cache once at the start of the role.
- Support grouping with YAML comments; the role itself iterates a flat list.

### `packages_snap`
- Read `snap_packages` list from `group_vars/all/snap_packages.yml`.
- Each entry includes:
  - `name`: snap name.
  - `classic`: `true`/`false` (defaults to `false`).
  - `channel`: optional track/risk/branch (defaults to `stable`).
- Use `community.general.snap` when available, otherwise fall back to `ansible.builtin.command` with idempotency checks.

### `dotfiles`
- Download the official chezmoi install script to a temporary location.
- Run the install script if `chezmoi` is not already on `PATH`.
- Run `chezmoi init --apply deniscuciuc` to clone and apply the dotfiles repo.
- Use `become: false` so dotfiles are applied as the current user.

### `devtools`
- Install tools that are not available via apt/snap:
  - `nvm` (Node Version Manager) via official install script; install latest LTS Node.
  - `pyenv` via official installer if not present.
  - .NET SDK via the Microsoft install script.
- Each tool is implemented in its own task file under `roles/devtools/tasks/` so failures are isolated and easy to skip with tags.

### `manual_checklist`
- Copy `docs/SETUP_CHECKLIST.md` to `~/Desktop/SETUP_CHECKLIST.md`.
- Append dynamic sections based on what was installed (e.g., "Run `nvm install --lts` if it was not already done").
- Print a message telling the user to open the checklist.

## 6. Package Inventory Strategy

The initial package lists are generated by scanning the current machine:

- APT: `apt list --installed` filtered to explicit user-facing packages (excluding libraries and dependencies).
- Snap: `snap list` excluding base/runtime snaps (`core*`, `bare`, `gtk-common-themes`, `mesa-*`, etc.).

The generated lists are checked into `group_vars/all/`. The user is expected to review and trim them before the first run. Comments in the YAML file document why each package is needed.

## 7. Manual Checklist

`docs/SETUP_CHECKLIST.md` is a human-readable file with checkboxes grouped by phase:

- **Before provisioning**
  - [ ] Back up files not in cloud storage.
  - [ ] Create Ubuntu 26.04 boot USB.
  - [ ] Ensure Bitwarden / password manager is accessible.
- **During provisioning**
  - [ ] Connect to network.
  - [ ] Run `bootstrap.sh` and enter sudo password.
  - [ ] Wait for playbook to complete.
- **After provisioning**
  - [ ] Import SSH private key from backup/password manager.
  - [ ] Import GPG key.
  - [ ] Log into GitHub CLI (`gh auth login`).
  - [ ] Log into browser (Firefox/Chrome) and sync bookmarks/extensions.
  - [ ] Log into Bitwarden extension.
  - [ ] Configure Syncthing and pair with other devices.
  - [ ] Sign into communication apps (Discord, Telegram, Thunderbird).
  - [ ] Sign into productivity apps (Spotify, Figma, OnlyOffice).
  - [ ] Install any paid/proprietary software not covered by apt/snap.
  - [ ] Verify `zsh` is the default shell.
  - [ ] Run `chezmoi diff` to confirm dotfiles are applied.

## 8. Testing Strategy

Testing is mandatory before declaring the playbook ready for the new laptop.

- **Dry-run mode:** `ansible-playbook playbook.yml --check --diff` against the current machine to catch syntax and logic errors.
- **Smoke test:** Run the playbook on the current machine in normal mode. Idempotency check: run it twice and verify the second run makes zero changes.
- **VM test:** Use Vagrant with an Ubuntu 26.04 box (libvirt or VirtualBox provider) to run `bootstrap.sh` from a clean state. The VM test proves the one-liner works on a fresh install.
- **Validation script:** After VM provisioning, run a small script that checks:
  - `zsh --version` is available.
  - `chezmoi` is installed and `chezmoi diff` exits 0.
  - A sample of apt packages (e.g., `git`, `zsh`, `neovim`) are installed.
  - A sample of snaps (e.g., `code`, `firefox`) are installed.

## 9. Error Handling

- Each role uses `ignore_errors: false` by default. Snap installs that may fail on non-classic-confinement systems are flagged with tags so they can be skipped.
- The playbook uses `any_errors_fatal: false` at the play level so a single failed devtool does not abort the entire run; failed tasks are reported at the end.
- `ansible.cfg` enables actionable error messages and retry files are disabled to avoid stale state.

## 10. Future Extensibility

- Adding GNOME settings later means creating a new `gnome_settings` role that uses `gsettings` or `dconf` modules.
- Per-machine customization can be added via `host_vars/<hostname>.yml` without changing the playbook.
- Multi-distro support can be added later by moving package lists under `vars/` keyed by `ansible_distribution` and `ansible_distribution_version`.

## 11. Secrets Policy

No secrets are stored in this repository. The `dotfiles` role pulls public dotfiles from GitHub. SSH keys, GPG keys, API tokens, and passwords are imported manually after provisioning using the checklist.
