# Audit summary and implemented changes

Audited both repositories for the Windows 11 → Ubuntu 26.04 workstation migration. `ws-setup` continues to provision software; `dotfiles` owns portable user configuration through chezmoi.

| Previous problem | Candidate implementation |
|---|---|
| Docker, Firefox, Neovim/Zsh and unrelated defaults | Rootless Podman, Brave, enhanced Bash; concise application manifests and optional additions |
| Required install errors hidden behind success | Separate module processes, nonzero exit status, blocked dependencies, logs and per-run checklist |
| Bash forced into Zsh | Exact legacy launcher removal, preserved custom Bash content, Bash login shell |
| Node 26 incompatible with inspected projects | Node 24.18.0 baseline; project-selected pnpm through Corepack; native AI CLIs independent of Node |
| Hard-coded home paths and command replacements | Portable HOME/chezmoi paths, explicit shortcuts, standard command behavior retained |
| Large generated Kitty config | Small configuration, existing theme and a pinned Nerd Font |
| Missing Restic and cwd-dependent backup paths | Installed Restic, absolute target resolution, mount/UUID checks, full integrity check and explicit staged restore |
| No current dotfiles guide; obsolete setup design | Linked migration/application/customization/terminal/backup guides; old designs marked superseded |
| Command-presence-only validation | Real runtime builds, PTY shell, desktop environment, container persistence, actual project services and encrypted restore tests |
| Mutable/unverified standalone installation | Central locked artifacts, checksum verification, cached downloads and installed-file receipts |

## Migration findings that remain relevant

- The audited development volume had about **419 MiB free**. All Samsung SSD partitions, including ReFS development data, need verified external backup before whole-disk Ubuntu installation. Preserve the separate Archive HDD. See [MIGRATION.md](MIGRATION.md).
- Changing the OS does not prove that every performance problem is solved. Compare actual builds, terminal startup and idle/boot measurements. See [PERFORMANCE.md](PERFORMANCE.md).
- Peerbridge's original MinIO Docker Hub images currently fail to pull under both engines. The isolated compatibility test passed with the documented vendor Quay override. Review the project's image source and maintenance before migration. See [PODMAN.md](PODMAN.md).
- Full Desktop VM, account sign-ins, actual data recovery and physical NVIDIA/gaming acceptance remain open. See the evidence and explicit release gate in [TESTING.md](TESTING.md).

Candidate changes are local until reviewed and published. No disk formatting, personal-data restore, account sign-in, Git push or project Compose rewrite is part of provisioning.
