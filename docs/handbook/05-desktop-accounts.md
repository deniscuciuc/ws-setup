# 5. Desktop, accounts and SSH

[Index](README.md) · Previous: [Containers/databases](04-containers-databases.md) · Next: [System/network](06-system-network.md)

## Your desktop applications

| Application | Purpose | First action after setup |
|---|---|---|
| Brave | Default web browser | Verify the default, sign in to sync if used, restore bookmarks and extensions |
| VS Code | Main project editor | Open a repository, select its runtime/environment, verify extensions |
| GitKraken | Graphical Git work | Sign in if required and open an existing repository |
| Claude Desktop | Claude's graphical workspace | Sign in and check the Linux features you rely on |
| ChatGPT desktop with Codex | OpenAI's graphical coding/work interface | Sign in and verify local project access |
| Bitwarden | Password vault and optional SSH agent | Unlock your vault and verify recovery access |
| Todoist | Personal tasks | Sign in and verify existing projects/tasks sync |
| Telegram | Messaging | Complete account/device verification |
| Discord | Community/team voice and chat | Sign in, test microphone/output and screen sharing |
| Spotify | Music | Sign in and select the correct audio output |
| Steam | Games and controller integration | Sign in, restore saves and test selected games |
| ONLYOFFICE | Documents, spreadsheets and presentations | Open a representative file, save a copy, verify layout |
| Kitty | Additional terminal window | Confirm font, prompt and shared Bash behavior |
| Podman Desktop | Graphical container management | Verify it shows the same rootless containers as the CLI |
| DBeaver / Compass / RedisInsight | Database GUIs | Create local project connections as described in [chapter 4](04-containers-databases.md) |
| Bruno | API request collections | Open a project's collection and select a private local environment |
| GNOME Disks | Disk identity, mount and health information | Inspect the intended device before any disk action |
| Disk Usage Analyzer | Graphical disk-space inspection | Scan your home directory to identify large folders |

Package installation does not authenticate any of these apps. Restore settings selectively: copying all Windows AppData over Linux application data can introduce incompatible state. Keep your Windows recovery backup until the needed Linux workflows work.

Current limitations matter: GitKraken's container window check timed out, Discord encountered a container sandbox error, and full Snap/desktop validation remains open. Read [TESTING.md](../TESTING.md). Linux AI desktop features also have limitations documented in [APPLICATIONS.md](../APPLICATIONS.md).

## Desktop changes you will notice

Brave handles web links. GNOME prefers a dark appearance, reduces animations, and uses JetBrainsMono Nerd Font for monospace text. Useful launcher favorites are added while preserving unrelated existing favorites. Ubuntu's normal terminal shortcut remains available; Kitty is launched separately.

For file associations, select your preferred application through Files → Open With. ONLYOFFICE is installed instead of adding LibreOffice to the managed inventory; see [the transition procedure](../TOOLS.md) before removing an Ubuntu-preinstalled office suite.

## Passwords, CLI sessions and SSH are different things

Bitwarden Desktop holds the graphical vault session. `bw` is its separately authenticated Password Manager CLI. `bw sync` refreshes CLI vault data; it does not start an SSH agent or copy SSH configuration files.

The **Bitwarden SSH agent** signs authentication requests using keys in the unlocked desktop vault. This allows SSH and Git to authenticate without restoring private key files to the Ubuntu filesystem. The server still needs the matching public key in its authorized keys; migrating an unchanged key preserves its identity.

Use [SSH_MIGRATION.md](../SSH_MIGRATION.md) for the complete Windows-to-vault procedure. In this setup:

- `ws-ssh-vault inventory DIRECTORY` lists local pair names and public fingerprints without uploading.
- `ws-ssh-vault upload DIRECTORY` explicitly creates and verifies supported SSH items after you log in/unlock the CLI; reruns skip identical entries.
- `ws-ssh-vault restore-public NEW_DIRECTORY` restores public keys for selecting agent identities, without exporting private keys.
- `ws-ssh-agent` lists agent fingerprints; `ws-ssh-agent ssh HOST` scopes the Bitwarden socket to that command.

The helper supports unencrypted OpenSSH RSA/Ed25519 pairs. Use native Bitwarden import for passphrase-protected or legacy keys. Host aliases, known hosts and other `.ssh` files remain part of the separate encrypted backup. The detailed guide explains per-host `IdentityFile`, private environment overrides and recovery with disk-based keys.

## Remote access defaults

OpenSSH **client** tools are installed for outgoing SSH, Git, scp and SFTP. The workstation does not automatically accept incoming SSH connections. Enable a server only if you actually need remote access to this PC and document its users/network policy separately.

Keep remote agent forwarding deliberate and per connection. The Bitwarden wrapper leaves the parent terminal's agent unchanged, so a forwarded agent or another local agent is not silently replaced. Never commit `BW_SESSION`, SSH private keys, database passwords or cloud tokens into either repository.
