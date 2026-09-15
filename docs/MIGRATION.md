# Windows 11 → Ubuntu 26.04

This guide prepares the migration; **setup scripts never erase or repartition disks**. Complete the [test gate](TESTING.md) before relying on this setup for your only workstation.

## 1. Make an external backup

The audited PC has an i5-10400, 64 GB RAM, RTX 2060 SUPER, a Samsung SSD 980 1 TB and a separate ST1000VM002 1 TB Archive HDD. At audit time C:, D: and G: were partitions on the Samsung SSD. D: was ReFS and nearly full. **Erasing the Samsung disk affects all three volumes.** Windows disk numbers and Linux device names can change: identify disks by model, capacity and serial at installation time.

Use an external disk with enough space for the selected data and a separate recovery copy of the backup password. Do not use the source SSD as its own backup. The internal Archive HDD is to be preserved, but is not the selected migration backup destination.

Back up from Windows while Windows can read ReFS and unlock any BitLocker volumes:

- All repositories, uncommitted/untracked work, local branches, Git submodules and worktree metadata. Include both G:\Repositories and any projects on D:.
- Documents, Desktop, downloads you need, pictures, videos and application-specific working files. Download cloud-only OneDrive files before backing them up.
- SSH keys/config, GPG exports, private `.env` files, development certificates, NuGet/npm registry configuration and license information. Store them only in encrypted backup storage.
- Codex/Claude settings, skills and histories; VS Code settings/extensions. Keep a raw backup for recovery, but do not overwrite Linux app data with entire Windows AppData folders.
- Browser bookmarks and sync/recovery information. Verify Bitwarden access on another device; avoid plaintext password exports.
- Local database **logical dumps** and uploads/object-storage files. Export container volumes and record images/Compose files. A Docker image export alone does not contain volume data.
- Steam saves, screenshots and non-cloud saves; installed games can usually be downloaded again.

For Restic on Windows, use the [official Windows release](https://github.com/restic/restic/releases), a private password file and an external repository. Example paths below must be replaced with your actual external drive and source paths:

```powershell
$env:RESTIC_REPOSITORY = 'E:\Backups\windows-migration'
$env:RESTIC_PASSWORD_FILE = 'C:\Users\perso\restic-password.txt'
restic init
restic backup 'G:\Repositories' 'D:\' 'C:\Users\perso' --exclude '**/node_modules' --exclude '**/.venv' --exclude '**/AppData/Local/Temp'
restic snapshots
restic check --read-data
```

Close applications writing the files, stop databases after producing dumps, and inspect every Restic warning. The user profile may contain locked files or large caches; resolve skipped important files explicitly. The password file must be readable only by your Windows account; keep its recovery copy outside the encrypted repository it unlocks. Never put it in Git.

## 2. Prove that recovery works

Use the [SSH migration guide](SSH_MIGRATION.md) for the existing key pairs: encrypted external backup first, explicit Bitwarden upload after login, then public-key restore and agent verification on Ubuntu. The CLI and migration helper are included in provisioning; private keys and host configuration are never committed to either repository.

- Restore representative projects, credentials/configuration files and personal documents to a separate empty folder.
- Confirm restored repositories include uncommitted work and local branches; open files and compare hashes for important data.
- Restore a database dump into an isolated test database and query it. Do not test against production.
- Verify the backup can be opened from Ubuntu live media. Keep recovery keys available separately.
- Keep the external disk disconnected during OS installation. Preserve this Windows backup until the Ubuntu migration and a second backup cycle are proven.

## 3. Install Ubuntu

1. Download Ubuntu 26.04 LTS from [Ubuntu](https://ubuntu.com/download/desktop) and verify the published image checksum before creating the USB.
2. Boot the live session in UEFI mode. Check displays, networking, audio, keyboard/mouse and access to the backup disk. Test work and games in a VM/live-test environment before replacing the only working system.
3. Identify the **Samsung SSD 980** as the install target. Preserve/disconnect the internal Archive HDD if practical; do not select it for erasure.
4. Select **Encrypt with a passphrase** (LVM encryption). Use the installer's ext4 defaults and save the passphrase securely. See [Ubuntu's disk setup options](https://ubuntu.com/desktop/docs/en/26.04/reference/advanced-disk-setup-features/).
5. Install Ubuntu and sign in. Let Ubuntu's supported driver flow handle NVIDIA/Secure Boot; do not use NVIDIA `.run` installers or random PPAs.

Keep source code and Podman storage on the Linux filesystem under your home directory, for example `~/Development`. ReFS is a migration source, not the Linux working filesystem. Do not copy Windows `node_modules`, virtual environments, NuGet caches or container storage directories directly into Linux.

## 4. Provision and restore

Follow the three-step [README](../README.md). For an unpublished candidate, transfer both repositories and pass `--dotfiles-source /path/to/dotfiles`.

Restore projects/data into an empty staging directory first, then move selected files into their intended home locations. Preserve permissions on SSH/GPG material; authenticate apps again instead of transplanting opaque Windows credentials. Recreate Node/Python dependencies and containers from each project's manifests, then import logical database dumps.

Configure the external disk and Restic using the dotfiles repository's `docs/BACKUP.md`. Keep its encryption password and your Ubuntu disk passphrase separately recoverable.
