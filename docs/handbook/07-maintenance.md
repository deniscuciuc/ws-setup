# 7. Maintenance and recovery

[Index](README.md) · Previous: [System/network](06-system-network.md) · Next: [Reference](08-reference.md)

## A practical routine

| When | What to do |
|---|---|
| Before a large change | Commit or preserve project work; make and verify a backup |
| After updating the setup checkout | Review changes, run `./setup.sh update`, read the report |
| After environment/driver changes | Log out/in or reboot as indicated, then run `doctor` |
| When a project changes dependencies | Follow its lockfile/runtime updates inside that project |
| Regularly | Attach the backup drive, run a backup, inspect failures and periodically restore test files |
| When storage shrinks unexpectedly | Inspect with duf/ncdu; classify data before deleting anything |

`update` handles previously managed workstation components. It does not update every project's dependencies or replace every container image. APT, Snap and Flatpak apps use their configured sources. Standalone tools use the reviewed asset lock; updating the setup repository supplies new pins. Do not bypass a checksum failure to force a download through.

## Read installation results

Default state directory: `~/.local/state/ws-setup` (or beneath `XDG_STATE_HOME` if you set it).

| Path | Contents |
|---|---|
| `latest-report.md` | Most recent module results and pending actions |
| `reports/` | Per-run reports, module logs, package versions and desktop-setting snapshots |
| `backups/` | Previous configuration files saved before replacement |
| `modules/` | Successful installation receipts used to select updates |
| `assets/` | Standalone download/install receipts |
| `dotfiles-source` | Which chezmoi source this installer selected |

`~/.cache/ws-setup` holds verified downloads and temporary extraction work. These are different from project files or database volumes. Setup's configuration backups are useful for undoing a change, but are not a substitute for an external machine backup.

## Modify configuration safely

1. Decide whether the change is portable or specific to this machine.
2. Put machine overrides in the private paths listed in [chapter 8](08-reference.md).
3. For a portable change, edit the dotfiles source and inspect `ws-dotfiles diff`.
4. Apply intentionally with `ws-dotfiles apply`, then test the affected application/shell.

`ws-dotfiles` remembers the source chosen during setup. Bare `chezmoi` may use another configured source. Source changes and target changes are different: editing a file in your home can create drift from the repository. Review it before applying over your edit.

The installer refuses to discard dirty remote-managed Git checkouts. Commit, stash or reconcile your changes yourself, or test a separate local source with `--dotfiles-source`. See [CUSTOMIZATION.md](../CUSTOMIZATION.md).

## Backup and restore

**Restic** stores encrypted, deduplicated snapshots. **rsync** copies/synchronizes files and is useful for transfers, but a plain rsync copy is not automatically encrypted or a versioned recovery history. **GnuPG** supports signing/encryption and package-key handling; its key recovery is separate from SSH recovery.

Configure `~/.config/workstation/backup.conf` with the external mount, optional expected filesystem UUID, repository and private password file. Review the target and exclusion lists. Relative backup targets are resolved against your home, never against whichever project directory you happen to be in.

```bash
ws-backup backup
ws-backup snapshots
ws-backup check
ws-backup restore latest /tmp/new-restore-check
```

These commands require the configured external disk. `check` reads stored data and can take time. Restore requires a new absolute destination. Compare restored files and restore representative database dumps before trusting recovery.

Backup excludes rebuildable caches and raw live container/database storage; make consistent logical database exports and include their directory. Retention is separate: `ws-backup retention` explains the policy; `ws-backup retention --apply` deliberately expires snapshots and prunes unreferenced data. The workstation maintenance module schedules daily backup attempts and weekly integrity checks, with mount protection and low priority. Retention remains manual. See [storage and maintenance](../MAINTENANCE.md) for schedules, controls, alerts and pnpm/worktree diagnostics.

The full instructions are in [dotfiles backup documentation](https://github.com/deniscuciuc/dotfiles/blob/main/docs/BACKUP.md). Keep the backup password separately recoverable; a password stored only inside its own encrypted backup cannot unlock it.

## Troubleshooting order

| Symptom | First response |
|---|---|
| Setup reports a failed package | Read that module's log; check repository/network/package availability, then rerun `install --only MODULE` |
| A dependent module is blocked | Fix the earlier failed dependency first |
| Download checksum mismatch | Stop using that download; review upstream change and the asset lock |
| An app is installed but does not open | Launch it from a terminal, read its errors, compare known test limitations |
| Command missing after install | Start a fresh login session; inspect PATH and module report |
| `doctor` reports dotfile drift | Inspect `ws-dotfiles diff`; decide whether to keep the local edit or reapply source |
| Podman tools disagree | Compare user identity, socket and endpoint using [PODMAN.md](../PODMAN.md) |
| Backup refuses to run | Verify external mount/UUID/password path and target list; do not bypass mount protection |
| SSH worked on Windows only | Compare public fingerprints, restored host config and agent selection using [SSH migration](../SSH_MIGRATION.md) |
| NVIDIA fails after install | Reboot, complete Secure Boot enrollment if requested, inspect supported-driver state |

`doctor` is deliberately read-only. A successful result does not prove a database connection, account sign-in, GUI render, game or physical backup restore. Follow the [acceptance tests](../TESTING.md) for those.
