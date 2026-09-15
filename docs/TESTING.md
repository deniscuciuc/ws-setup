# Validation and release gate

**Candidate, 15 September 2026. Do not publish this as a migration-tested release yet.** The Windows host can run Ubuntu containers, including an isolated systemd user session. It does not provide a configured Ubuntu Desktop VM or `/dev/kvm` to this test environment. A container/Xvfb test is not an Ubuntu Desktop installation test.

## Evidence so far

| Check | Result |
|---|---|
| Bash syntax, ShellCheck, helper regressions | Includes optional-module selection/updates and SSH migration; run `tests/test.sh` for current counts |
| Ubuntu 26.04 package availability and core installation | Passed in Ubuntu 26.04 systemd container, normal user with sudo |
| Repeat installation and `update --profile core` | Passed for CLI modules; pinned assets reused; final core doctor reported zero failures and no managed drift |
| .NET 10 console build | Passed |
| uv Python environment, SQLite and TLS | Passed |
| Node 24.18.0, pnpm 11.17.0 and 11.21.0 | Passed with separate project `packageManager` fields |
| Claude, Codex, mongosh and Go sqlcmd execution | Passed; Codex sandbox also executed an offline command |
| Interactive Bash + ble.sh + fzf; standard commands | Passed under a PTY; noninteractive quietness covered separately |
| Chezmoi apply/rerun with ordinary Git file modes | Passed in a separate home: custom Bash content preserved, helpers executable, AI config private, docs/tests/retired Neovim excluded |
| Rootless Podman build/run, Docker bridge, Compose | Passed: PostgreSQL/Valkey health, DNS, localhost publishing, persistent volume across recreation and scoped cleanup |
| Actual project Compose stacks | Detector passed unchanged. Peerbridge passed with the explicit Quay MinIO override, including bucket initialization and Mailpit HTTP; unchanged Hub images remain blocked |
| Encrypted Restic backup, check, restore | Passed on an isolated mounted test filesystem, from an unrelated working directory; absent disk rejected |
| Required failure propagation, dirty source, corrupt download, missing desktop | Passed; failed dependencies block downstream modules and the run exits nonzero |
| Native desktop packages | Brave, VS Code, Claude Desktop, ChatGPT, Steam (including i386 libraries), DBeaver, Compass, Bruno and Kitty installed successfully |
| Snap | Blocked in nested container: Todoist/Mesa hooks cannot preserve mount namespaces. Installer returned failure. All five apps require real Desktop VM validation |
| Podman Desktop Flatpak | Installed successfully and created a matching main window; native-engine connection acceptance remains open |
| Xvfb native window smoke tests | App-specific main windows appeared for Brave, VS Code, Claude Desktop, ChatGPT, DBeaver, Compass, Bruno and Kitty. Steam did not create a matching window within 120 seconds; it remains pending. Sign-ins and rendered appearance are not certified |
| Desktop configuration and VS Code extensions | Passed in isolated Xvfb/D-Bus test session, including a repeat run; all 12 requested extensions installed |
| Full Ubuntu Desktop VM, desktop login, all app launches | **Pending** |
| Added CLI behavior | Passed on Ubuntu 26.04: local OpenTofu init/validate/plan, yq query, just task, SOPS/age round-trip, Ansible localhost ping; Cloudflare/Skopeo/Trivy/network-tool execution |
| Added module installation/repeatability | tools, devops and diagnostics installed; rerun and unqualified update reused pinned assets. Doctor passed with the normal Ubuntu PATH including `/usr/sbin`. iperf3 daemon option remained false; dumpcap received no capture capabilities |
| Added native applications | ONLYOFFICE 9.4.0-129, GitKraken 12.4.1, Discord 1.0.158, GNOME Disks and Baobab installed; focused rerun installed nothing new and reused asset receipts |
| Added GUI launches | ONLYOFFICE created a matching Xvfb window. GitKraken produced no matching window within 40 seconds (then 50 with D-Bus). Discord bootstrap completed but its downloaded client aborted with a sandbox-helper error in the container. Both remain unresolved Desktop VM checks; sandboxing was not disabled |
| Bitwarden CLI / SSH migration | Native bw 2026.8.0 installed and returned version/status on Ubuntu; Windows read-only inventory found 17 pairs. Synthetic SSH tests cover upload/read-back, reruns, collisions, encrypted/mismatched pairs, stdin handling and public restore. Real authenticated vault transfer and desktop agent use remain pending user sign-in |
| Physical NVIDIA, sound, displays, network, suspend, games | **Pending** |
| Actual Windows migration backup and database restore | **Pending user data/hardware acceptance** |

The Ubuntu image tested was `ubuntu:26.04`, digest `sha256:513c074113a871b51a8d16ab445c88779d6452d937a164fb5cc479f32668a41d`. Standalone application versions are recorded in `config/assets.lock.json`; run reports retain installed APT versions and asset receipts.

The measurement script also ran successfully. Its 73 ms non-TTY shell median and container-only boot/memory readings are test-harness observations, not a forecast for this PC's Ubuntu desktop performance.

### Issues caught during testing

- Valve's `steam-launcher` conflicts with Ubuntu's `steam-devices`, because it supplies its own rules. Setup now installs only the launcher and adopts its repository after bootstrap.
- The minimal Ubuntu container strips package documentation, including fzf's shell integration scripts. The test image preserves these files; provisioning explicitly checks them. Normal Desktop installations include them.
- Ubuntu's environment generator can reset PATH from `/etc/environment`. The workstation environment now loads afterward; actual login and systemd-generator checks passed, including an intentional remote Docker override.
- VS Code detects the Docker Desktop host's WSL kernel. The isolated test harness uses its documented `DONT_PROMPT_WSL_INSTALL=1` override. This is not set in workstation configuration.
- Xvfb launches can create an application window while still reporting GPU errors. No global GPU/sandbox workaround is configured to conceal this; visual acceleration and gaming must be checked in the real desktop session.
- Steam finished its initial client update, but the nested session then logged desktop-portal timeouts and DRI3 rendering warnings. A matching Steam window was not confirmed; keep its GUI/gaming acceptance open.
- Peerbridge's Docker Hub MinIO image requests were denied under **both Docker and Podman**. The same tags resolve in the vendor's Quay registry. `tests/peerbridge-minio-quay.yaml` provides an explicit, digest-pinned x86_64 test override. Original project repositories are unchanged. Review the project's MinIO maintenance and image source before migration; passing another registry does not make the unchanged Docker Hub workflow pass.

## Fast checks

On Ubuntu, with the repositories next to each other:

```bash
bash tests/test.sh
python3 ../dotfiles/tests/test_dotfiles.py
git diff --check
git -C ../dotfiles diff --check
```

The static suite also supports the provided disposable container. From the setup repository, use a current Docker engine or Podman:

```bash
docker build -f tests/Dockerfile -t ws-setup-tests:candidate .
docker run --rm \
  --mount type=bind,source="$PWD",target=/work,readonly \
  --mount type=bind,source="$(realpath ../dotfiles)",target=/dotfiles,readonly \
  ws-setup-tests:candidate
```

Windows PowerShell uses absolute Windows paths for bind sources. Running this test with an existing Docker installation does not change the target Ubuntu choice of Podman.

## Ubuntu Desktop VM acceptance

For the added tools, run `bash tests/check-tools.sh` after the workstation install. After opting into DevOps, use `bash tests/check-tools.sh --devops`. Test packet capture, Cloudflare authentication and actual infrastructure projects separately. `tests/install-extra-gui.sh` is a disposable-test helper for the new native GUI packages; it does not replace the complete workstation installation.

Create a disposable Ubuntu **26.04 Desktop x86_64** VM with at least 8 GB RAM, 4 CPUs and an 80 GB virtual disk. Enable 3D graphics where supported. Sign in through its desktop and transfer both candidate repositories. Use copies if shared-folder permissions or executable bits differ.

1. Snapshot the clean VM. Run `bash setup.sh plan --dotfiles-source ../dotfiles`, then the same command with `install`. Capture the full report and logs.
2. Reboot and run `bash setup.sh doctor --dotfiles-source ../dotfiles`. Confirm no managed-file drift. Run `install` again: no duplicate repositories/settings or repeated standalone downloads. Test `update` separately.
3. Run `bash scripts/smoke-runtimes.sh` and `bash scripts/smoke-containers.sh`. These create temporary development workloads, use unique Compose project names and remove only their own test data.
4. Run `python3 tests/check-shell-pty.py`, `python3 tests/check-shell-sessions.py`, `DOTFILES_SOURCE=../dotfiles python3 tests/check-chezmoi.py` and `bash tests/check-backup.sh`. The last command uses sudo for a temporary mounted filesystem and tests real encrypted Restic recovery. It is not a backup of personal data.
5. Test Ubuntu's terminal, Kitty, VS Code Bash login terminal, `bash -c`, `bash -lc`, and an SSH terminal. Check Ctrl+R, suggestions, completions, local overrides and normal command behavior. An incoming SSH server may be installed **in the test VM only** to exercise SSH; the workstation default remains client-only.
6. Launch every app in [APPLICATIONS.md](APPLICATIONS.md). Confirm visible windows, sign-ins, URL handlers, terminal integration and the Podman Desktop native connection. Connect DBeaver, Compass and RedisInsight to disposable databases. Test VS Code Dev Containers against native Podman. In a disposable X11/XWayland session with `xwininfo` installed, `WS_DISPOSABLE_TEST=1 python3 tests/check-gui.py` provides an initial window-creation check and per-app logs; this does not replace visual/workflow checks.
7. Run each actual project's tests/builds and Compose workflows using restored test data. For the two inspected projects in a disposable environment:

   ```bash
   WS_DISPOSABLE_TEST=1 bash tests/check-projects.sh /path/to/peerbridge /path/to/imba-detector-poc-lm
   # Explicit compatibility experiment for the currently denied MinIO Hub images:
   WS_DISPOSABLE_TEST=1 WS_TEST_MINIO_QUAY=1 bash tests/check-projects.sh /path/to/peerbridge /path/to/imba-detector-poc-lm
   ```

   These tests publish the projects' configured ports, use disposable credentials and unique volume names, and delete their own volumes. Use an isolated VM/container. They do not read your real `.env` files.
8. Inject failures in the disposable VM: unavailable required package, interrupted download, dirty remote-managed dotfiles, removed desktop session, and existing Docker package conflict. Verify an actionable error and nonzero status. Restore the VM snapshot between cases where necessary.
9. Record measured shell startup, idle resources and representative build times using `scripts/measure.sh`. Establish comparable baselines; container timings do not predict physical desktop performance.

## Physical PC and publication gate

Use [MIGRATION.md](MIGRATION.md) and [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md). Verify the external Windows backup and restore before erasing the Samsung SSD. Test graphics, firmware/Secure Boot, audio, network, displays, suspend/resume and selected games on the actual PC.

Only publish the simplified installation path as tested after the clean VM, repeatability, development, GUI and recovery checks pass. Record exact Ubuntu image, repository commits, module results and any accepted limitations. Physical hardware certification remains a separate checklist; never infer it from a VM or container.
