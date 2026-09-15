# Storage reuse and scheduled maintenance

The workstation profile includes `maintenance`; core users can opt in with `./setup.sh --only maintenance`. On an existing workstation run `install` for this new module: `update` intentionally skips modules not previously installed. For local candidate repositories, add `--dotfiles-source ../dotfiles`.

## pnpm and AI worktrees

The managed `~/.config/pnpm/config.yaml` sets `packageImportMethod: auto` and `preferOffline: true` for the pinned pnpm 11 runtimes. pnpm uses downloaded data where possible and still fetches missing dependencies. Project lockfiles and `packageManager` remain authoritative. Registry credentials stay in private auth configuration.

The store path is deliberately not forced globally. pnpm normally chooses a shared store suitable for the filesystem. Putting one forced home store on a different partition from projects can turn links into full copies. Keep agent worktrees and repositories on the same Linux filesystem as their store; for the planned Ubuntu install this means using the SSD's home filesystem for development.

```bash
cd ~/Development/my-project
pnpm store path
ws-storage pnpm .
ws-storage pnpm . --probe
```

The regular check compares filesystem IDs and prints the effective import method. It disables Corepack network downloads; install the project's required pnpm version normally first. The probe creates and removes tiny temporary files in the existing store and project, verifying that a hardlink can actually be made. It does not edit package contents. Installed-package sharing is checked by `tests/check-pnpm-sharing.sh` using two disposable Git worktrees and an offline second install.

On ext4, successful hardlink imports let multiple paths refer to the same stored file. Do not modify dependencies directly inside `node_modules`; a hard-linked edit can affect shared contents. Use the project's dependency/patch workflow. Filesystems supporting cloning may behave differently, so check actual behavior before changing `auto` to another method.

Global **virtual-store** sharing is not enabled. It shares additional dependency layout, but changes link locations and needs project/tooling compatibility tests. Ordinary content-store sharing already avoids repeated package-file copies on the same filesystem. `preferOffline` is not a replacement for a frozen lockfile: use `pnpm install --frozen-lockfile` when the lock should remain unchanged.

## Where space goes

```bash
ws-storage usage
ws-storage usage ~/Development /path/to/agent-worktrees ~/.local/share/pnpm
ws-storage worktrees ~/Development/my-project
```

Usage reporting runs `du` once across supplied paths, counting hardlinks once. Summing separate folder-size measurements can overstate actual shared storage. Argument order affects which directory gets credited for shared files. `df` reports filesystem capacity. The default report checks conventional paths only; supply your real agent-worktree location explicitly.

Build outputs (`.next`, `dist`, coverage), downloaded browsers, logs, native build products and container volumes can grow independently of pnpm's store. Worktree reporting lists Git's registered worktrees and explains how to inspect them; it never removes any. Preserve commits/untracked files and stop the associated agent before removing a worktree through Git. Avoid `git clean -fdx` as a generic cleanup command.

After retiring projects/worktrees, `pnpm store prune` is an occasional **manual** cleanup. Frequent pruning removes packages future worktrees may reuse and can increase downloads. No timer prunes pnpm, Podman volumes or build directories.

Backups exclude standard pnpm store paths, project `.pnpm-store` directories, `node_modules`, `.next`, `.nuxt` and `.turbo`. Custom `storeDir`/XDG paths must be added explicitly to the exclusion list. Keep lockfiles and source; exclude only rebuildable data. `dist` is not globally excluded because some projects keep meaningful deliverables there.

## Timer policy

| Timer | Schedule in local time | Behavior |
|---|---|---|
| `ws-health.timer` | Daily and about 15 minutes after the user manager starts, with up to 15 minutes jitter | Reports less than 20 GiB free or at least 90% used on `/` or home; reports unconfigured backup or no recorded success for 7 days |
| `ws-backup.timer` | Daily around 02:30, with up to 30 minutes jitter | Runs encrypted backup only when configured disk is mounted |
| `ws-backup-check.timer` | Sunday around 05:00, with up to 30 minutes jitter | Runs Restic full read-data verification when disk is mounted |

Timers are persistent: a missed calendar run may execute after the next user login. They do not wake the PC or enable user lingering. Backup/check services require AC power where the system reports a battery, run at reduced CPU/I/O priority, and time out after 6/12 hours respectively. A run skipped on battery or absent disk waits for another scheduled or manual attempt; plugging the disk in does not itself trigger a job.

Backup and check share a nonblocking lock so they do not run concurrently. A busy job or absent disk is logged as skipped, with no success timestamp. Real backup failures return nonzero. The existing backup helper still verifies mount UUID, canonical destination and password-file access. No repository is initialized automatically and no retention is applied automatically.

Configure the disk using [dotfiles backup instructions](https://github.com/deniscuciuc/dotfiles/blob/main/docs/BACKUP.md), then initialize a new repository once with `ws-backup init`. For a manual run tracked by freshness checks, use:

```bash
ws-maintenance backup
ws-maintenance check
ws-maintenance health
```

Successful maintenance runs record timestamps in `~/.local/state/ws-maintenance`. Direct `ws-backup` or raw Restic runs do not update these markers. A successful backup is separate from a successful integrity check and from testing a restore.

Notifications occur only when an actionable condition changes; healthy runs are quiet apart from journal entries. If no desktop notification service exists, messages remain in the journal and delivery is retried on later checks. Stale backup alerts remain relevant even if the last attempt skipped an absent disk.

## Inspect, adjust or stop

```bash
systemctl --user list-timers 'ws-*'
journalctl --user -u ws-health -u ws-backup -u ws-backup-check
ws-storage system
./setup.sh doctor --only maintenance
```

Use `systemctl --user edit ws-backup.timer` for a private schedule override. Clear the old `OnCalendar=` before specifying a replacement, then run `systemctl --user daemon-reload` and restart that timer. To stop a job permanently, run `systemctl --user disable --now ws-backup.timer` (and the other timers as needed). Reinstalling/updating the maintenance module enables its managed timers again, so exclude that module from updates if intentionally disabled.

`ws-storage system` reports existing Ubuntu security-update and TRIM timers, APT policy and discard capabilities. It does not duplicate those jobs, enable unattended reboots, or alter encrypted-volume discard settings. Review whether TRIM works through the actual encrypted mapping during hardware acceptance. An enabled timer alone does not establish that discards reach the SSD.

Sources: [pnpm store behavior](https://pnpm.io/settings/store), [pnpm import/virtual-store settings](https://pnpm.io/settings/node-modules), [store pruning](https://pnpm.io/cli/store), [Ubuntu automatic updates](https://ubuntu.com/server/docs/how-to/software/automatic-updates/).
