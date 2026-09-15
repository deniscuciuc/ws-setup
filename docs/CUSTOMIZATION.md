# Customize, update and recover

## Profiles and modules

`workstation` is the default. `core` includes CLI tools, Bash, dotfiles, runtimes, AI CLIs, native Podman and database clients. Both target Ubuntu 26.04 x86_64. `--only a,b` selects those modules plus their prerequisites; run `plan` to see the expanded list.

`tools` adds Cloudflare/OpenTofu and system diagnostics and is included in workstation. `devops` (SOPS, age, Ansible, Trivy) and `diagnostics` (Wireshark/TShark) are opt-in: `./setup.sh --only devops,diagnostics`. See [the tool guide](TOOLS.md). Unqualified `update` follows every installed module receipt, including opt-ins; use `--only` to restrict updates.

APT manifests live in `packages/`; Node/Corepack/Python/.NET defaults live in `config/versions.sh`. Keep the Node baseline in the dotfiles mise config in sync with the workstation baseline. Project-local versions take precedence: use a trusted `mise.toml` or `.node-version`, and keep each project's `packageManager` field.

Private overrides:

- `~/.config/shell/local.sh`: login environment, project roots and intentional remote Docker endpoints.
- `~/.config/bash/local.bash`: interactive aliases and shortcuts.
- `~/.gitconfig.local`: identity and credential-helper overrides. GitHub already uses `gh auth git-credential`; `gh auth login` stores its token outside Git. Do not track credentials.
- `~/.config/workstation/backup.conf`: external disk/repository/password-file locations.

## Two-repository development

```bash
bash /path/to/ws-setup/setup.sh --dotfiles-source /path/to/dotfiles
```

The local source may contain candidate changes; setup does not fetch, commit or push it. `ws-dotfiles` remembers this source. Without that argument, setup uses the configured GitHub URL/ref and refuses dirty checkouts, unexpected origins or branch switches. Merge/publish the matching dotfiles version before enabling the new setup on `main`.

Plain `chezmoi` uses its own configured source; use `ws-dotfiles` for the source selected by this installer. To migrate an existing clone onto a reviewed branch, commit/stash its work yourself, switch it explicitly, or use a separate clone. The installer will not discard your work.

## Updates

1. Review and fast-forward your setup checkout, preserving local changes.
2. Run `./setup.sh update` (add `--dotfiles-source` for a local source).
3. Inspect the report and run `doctor` after the next login/reboot.

APT/Snap/Flatpak apps follow their configured stable channels. Update runs only successful, previously managed modules and only installed packages within their manifests. Missing components are repaired with `install`. VS Code updates installed extensions. Project dependencies and database images remain under each project's control.

Standalone downloads are pinned in `config/assets.lock.json`. Normal setup verifies their SHA-256 and never discovers arbitrary latest versions. Maintainers can produce a candidate lock with:

```bash
python3 scripts/lock-assets.py                 # Print a candidate
python3 scripts/lock-assets.py --write         # Save after reviewing the sources
python3 scripts/lock-assets.py --only uv --write
```

Review the lock diff and rerun tests before distribution. GitHub release digests and Claude's manifest are used where published. Older ble.sh assets, repository keys and the OpenAI bootstrap package are labelled `maintainer-hashed-https`; their pinned hashes detect subsequent changes but are not independent vendor signatures.

OpenAI's initial `.deb` uses the versioned pool URL discovered from its official APT index, with the downloaded bytes checked against that index before locking. After installation, OpenAI's signed APT repository handles updates. If a vendor removes a pinned release, refresh its lock entry and retest.

## Recovery

The last report points to each module's log. Fix the cause and rerun; receipts verify actual files/package versions, not just marker files. For a checksum mismatch, inspect the upstream release before refreshing the lock. For a missing package, check the Ubuntu release and official source; do not substitute a repository for another Ubuntu version.

Configuration backups are kept under `~/.local/state/ws-setup/backups/<run>/`. Preview `ws-dotfiles diff` before applying your source. Restore specific backed-up files deliberately; system repository files may require sudo. Reapplying dotfiles intentionally restores managed settings, so move lasting personal changes into the documented local override files or your source repository.

## Optional additions

- **Additional .NET SDKs:** add the [Ubuntu .NET backports PPA](https://learn.microsoft.com/en-us/dotnet/core/install/linux-ubuntu-install), then install the SDK required by `global.json`. Keep .NET 10 from Ubuntu's built-in feed.
- **Incoming SSH:** install `openssh-server` only when needed, add authorized public keys, test a second login before disabling password authentication, and allow only the intended network in your firewall. Outgoing SSH already works.
- **Syncthing:** useful for selected working folders; sync does not replace versioned backups. Enable its user service only after selecting folders/devices.
- **rclone:** useful for encrypted cloud/network copies; credentials belong in private configuration. Start transfers deliberately.
- **GPU containers/CUDA:** follow NVIDIA's current Container Toolkit CDI instructions for Podman. Add this only for an actual GPU project; desktop/gaming setup does not install a CUDA toolkit.
- **Office apps, Discord, extra games and Kubernetes tooling:** install individually when needed. They are no longer part of the default workstation image.
