# Application and source catalog

Verified documentation date: 2026-09-15. A package being downloadable is not the same as a tested Ubuntu 26.04 GUI. Record launch results in [TESTING.md](TESTING.md).

| Module | Applications | Source/update method |
|---|---|---|
| base | Git/LFS, gh, glab, build tools, Nano, HTTPie, jq, delta, lazygit, bat/fd/rg/eza, fzf/zoxide, tmux, diagnostics, Restic/rsync | Ubuntu APT; manifest in `packages/base.txt` |
| base | chezmoi | Locked official GitHub release |
| base | Bitwarden Password Manager CLI (`bw`), `ws-ssh-vault` | Locked official native CLI release; repository migration helper. See [SSH migration](SSH_MIGRATION.md) |
| shell | Starship, ble.sh | Locked official releases; ble.sh is the upstream `0.4.0-devel3` release, tested separately |
| runtimes | mise, uv | Locked official releases |
| runtimes | Node 24.18.0, Corepack, pnpm baseline | mise + exact npm/Corepack versions; project `packageManager` overrides pnpm |
| runtimes | Python 3.13 | uv-managed Python; `.python-version`/project requirements select other versions |
| runtimes | .NET 10 SDK | Ubuntu's .NET feed; no mixed Microsoft .NET feed |
| ai | Claude Code, Codex CLI | Locked native binaries, independent of project Node versions |
| containers | Podman, podman-docker, rootless dependencies | Ubuntu APT |
| containers | Docker Compose executable | Locked upstream Compose release, used as Podman's provider; no Docker Engine |
| database | psql, mysql/MariaDB client, sqlite3, redis-cli | Ubuntu client packages only |
| database | mongosh, sqlcmd (Go) | Locked official MongoDB/Microsoft releases |
| apps | Brave, VS Code, Claude Desktop, Steam, ONLYOFFICE | Official signed vendor APT repositories; keys are checksum-pinned; `packages/apps.txt` |
| apps | GitKraken, Discord | Checksum-locked official vendor `.deb` downloads |
| apps | OpenAI ChatGPT desktop with Codex | Checksum-pinned official bootstrap `.deb`, then vendor's signed APT repository |
| apps | Todoist, Telegram, Spotify, Bitwarden, RedisInsight | Stable Snap packages linked/recommended by vendors |
| database-gui | DBeaver Community | Official signed DBeaver APT repository; `packages/database-gui.txt` |
| database-gui | MongoDB Compass, Bruno | Locked official GitHub `.deb` releases |
| desktop | Kitty, Flatpak, GNOME Disks, Disk Usage Analyzer | Ubuntu APT |
| tools | cloudflared | Official signed Cloudflare APT repository |
| tools | OpenTofu, Mike Farah yq, just | Locked official upstream releases |
| tools | Skopeo, NetHogs, Nmap, iperf3, duf | Ubuntu APT; `packages/tools.txt` |
| devops (optional) | age, Ansible; SOPS, Trivy | Ubuntu APT; locked upstream binaries respectively |
| diagnostics (optional) | Wireshark, TShark | Ubuntu APT, no automatic capture privilege grant |
| desktop | Podman Desktop | User Flatpak from Flathub, per upstream instructions |
| desktop | JetBrainsMono Nerd Font | Locked Nerd Fonts release |
| drivers | NVIDIA driver + matching 32-bit graphics library | Ubuntu recommended driver resolver; no hard-coded driver branch or CUDA |

## Compatibility details

See [TOOLS.md](TOOLS.md) for usage, official references, optional Cockpit/WARP, project-local Wrangler and the ONLYOFFICE/LibreOffice transition.

- Claude Desktop Linux is **beta**; OpenAI's Linux desktop is **preview**. Both provide the requested graphical coding experience, but Linux Computer Use is not available. Claude's Linux beta also lacks desktop dictation. CLI and desktop sign-ins are separate first-run steps.
- Claude Desktop's Cowork requires hardware virtualization, QEMU and KVM access. Its default package recommendations install QEMU; setup adds the user to `kvm` when available. Firmware changes and the next login remain manual.
- DBeaver Community covers SQL clients. MongoDB uses Compass/mongosh; Redis/Valkey uses RedisInsight/redis-cli.
- RedisInsight's published matrix currently lists Ubuntu through 24.04. Test its Snap on 26.04. Compass documents potential NVIDIA rendering issues; use `--disable-gpu` only to diagnose a demonstrated issue.
- Corepack follows each project's `packageManager`; do not globally replace all projects' pnpm versions. The inspected projects use Node 24 with pnpm 11.21.0 and 11.17.0.
- VS Code is the selected editor. C# Dev Kit has its own licensing terms. Windows-only .NET Framework/WPF/WinForms or specialized Visual Studio workloads need a separate compatibility decision before wiping Windows.
- Steam installs the native launcher, including 32-bit support. Validate the games you care about; installing Steam does not guarantee every Windows title/anti-cheat combination works.

## Primary references

- [Ubuntu 26.04](https://documentation.ubuntu.com/release-notes/26.04/)
- [Brave](https://brave.com/linux/) · [VS Code](https://code.visualstudio.com/docs/setup/linux)
- [Claude Desktop Linux](https://code.claude.com/docs/en/desktop-linux) · [Claude CLI](https://code.claude.com/docs/en/setup)
- [OpenAI Linux desktop](https://learn.chatgpt.com/docs/linux/linux-app) · [Codex CLI](https://learn.chatgpt.com/docs/codex/cli)
- [.NET on Ubuntu](https://learn.microsoft.com/en-us/dotnet/core/install/linux-ubuntu-install) · [mise Node](https://mise.jdx.dev/lang/node.html) · [uv Python](https://docs.astral.sh/uv/guides/install-python/)
- [Podman Desktop](https://podman-desktop.io/docs/installation/linux-install) · [Podman Compose](https://docs.podman.io/en/latest/markdown/podman-compose.1.html)
- [DBeaver](https://dbeaver.io/download/) · [Compass](https://www.mongodb.com/docs/compass/install/) · [RedisInsight](https://redis.io/docs/latest/operate/redisinsight/install/install-on-desktop/) · [sqlcmd](https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-download-install)
- [Todoist](https://www.todoist.com/downloads/linux) · [Telegram](https://desktop.telegram.org/) · [Spotify](https://www.spotify.com/download/linux/) · [Steam](https://repo.steampowered.com/steam/)
