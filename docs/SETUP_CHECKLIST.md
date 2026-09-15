# Finish your Ubuntu workstation

The installer also writes a run-specific report to `~/.local/state/ws-setup/latest-report.md`. Resolve failures there before this checklist.

- [ ] Reboot after graphics/package updates. Complete Secure Boot enrollment if Ubuntu requests it.
- [ ] Start Ubuntu's terminal: Bash prompt, history search and navigation work. Open Kitty and VS Code's terminal too.
- [ ] Confirm Brave is default and restore browser sync/Bitwarden access.
- [ ] Import SSH/GPG material from the encrypted backup with appropriate permissions. Run `gh auth login` and `glab auth login`.
- [ ] Follow [Bitwarden SSH migration](SSH_MIGRATION.md), compare public fingerprints, enable the desktop agent and test a representative host before removing Windows.
- [ ] Sign in to Claude Code, Codex CLI, Claude Desktop and ChatGPT desktop. Check that each can open a local project.
- [ ] Sign in to Todoist, Telegram, Spotify, Bitwarden and Steam.
- [ ] Open GitKraken and Discord; verify Git provider access, audio and screen sharing.
- [ ] Open/save representative documents in ONLYOFFICE, set document associations, then remove preinstalled LibreOffice applications using [TOOLS.md](TOOLS.md).
- [ ] Verify Cloudflare access and project-local Wrangler where needed; tunnels are not started by setup.
- [ ] Open Podman Desktop and confirm that it sees the same native rootless containers as `podman ps`.
- [ ] Open DBeaver, Compass, RedisInsight and Bruno; restore connection profiles without copying secrets into Git.
- [ ] Restore projects and rebuild dependencies. Verify the required Node/pnpm/Python/.NET versions per project.
- [ ] Run `./setup.sh doctor`, `bash scripts/smoke-runtimes.sh` and `bash scripts/smoke-containers.sh`.
- [ ] Test actual project Compose stacks and database restores using [PODMAN.md](PODMAN.md).
- [ ] Check NVIDIA, audio, networking, displays, suspend/resume and selected Steam games.
- [ ] Configure the external backup; complete a backup, integrity check and test restore.
- [ ] Review `ws-storage system` and the maintenance timers; run `ws-maintenance backup` after configuring the external disk. Verify `ws-storage pnpm PROJECT --probe` for real agent worktree locations.

Firmware settings, disk encryption, credentials and account logins are the remaining manual steps. Keep the Windows backup until this checklist and the release tests pass.
