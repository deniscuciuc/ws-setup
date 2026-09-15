# SSH keys: Windows → Bitwarden → Ubuntu

`bw` (Bitwarden Password Manager CLI) and `ws-ssh-vault` are installed by `base`, including the core profile. This is the password vault CLI, not the separate Secrets Manager CLI. Bitwarden Desktop provides the SSH agent; the CLI alone does not provide an agent.

## 1. Preserve Windows recovery first

Include the whole `%USERPROFILE%\.ssh` folder in the **encrypted external Restic backup** in [MIGRATION.md](MIGRATION.md). This preserves private keys, public keys, host aliases, known hosts and any extra files. Bitwarden SSH items store key material, not your SSH host configuration. Test restoring that folder to a separate location before wiping Windows.

The current Windows folder contains multiple named key pairs. The helper discovers files ending in `.pub` with a matching private-key filename; it ignores agent directories and backup suffixes. It never deletes, renames or decrypts your original files in place.

## 2. Upload current keys once, from Windows

Install the official Windows native [Bitwarden CLI](https://bitwarden.com/help/cli/#native-executable) and put `bw.exe` on PATH. Python 3 and Windows OpenSSH must also be available. Run these in your own PowerShell terminal; never paste the unlock token into chat, a file or a Git repository:

```powershell
python .\scripts\ssh-vault.py inventory "$env:USERPROFILE\.ssh"
bw login
$env:BW_SESSION = bw unlock --raw
python .\scripts\ssh-vault.py upload "$env:USERPROFILE\.ssh"
bw lock
Remove-Item Env:BW_SESSION
```

If using the EU service or self-hosting, set `bw config server https://vault.bitwarden.eu` (or your server) **before login**. Confirm that it is your intended vault. Keep your master password and two-step recovery code separately recoverable.

`inventory` is local and prints only names and public fingerprints. `upload` explicitly writes SSH items named `workstation-ssh/KEY_NAME` to your personal vault. It validates every pair first, synchronizes, detects name collisions, skips identical items, and reads back each new item. Keys travel through the CLI's stdin rather than command-line arguments or plaintext staging files. A failed batch can be rerun; no existing vault item is overwritten. Avoid simultaneous uploads from multiple terminals.

The helper supports unencrypted OpenSSH Ed25519/RSA pairs. For a passphrase-protected or legacy key, use Bitwarden Desktop's native **Import SSH key** flow and enter its passphrase there; keep the original intact. Such a key blocks a batch before uploads begin: use a separate directory containing only the selected supported pairs, or import all keys through the desktop. Name manually imported items with the same `workstation-ssh/` prefix to use public-key restore. Hardware-backed keys require their physical device and are outside this file migration flow.

## 3. Use the vault on Ubuntu

After workstation provisioning, sign in to Bitwarden Desktop, sync, unlock it, and enable **Settings → SSH Agent**. Its Snap socket is `~/snap/bitwarden/current/.bitwarden-ssh-agent.sock`.

```bash
bw login
export BW_SESSION="$(bw unlock --raw)"
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ws-ssh-vault restore-public ~/.ssh/bitwarden-keys
bw lock
unset BW_SESSION
ws-ssh-agent                 # List agent fingerprints
```

Restore goes into a **new directory**, contains only `.pub` files, and refuses overwrite. Compare these fingerprints with the Windows inventory and confirm a representative host login. The desktop vault must remain unlocked for agent use; locking the CLI does not lock the separate desktop session.

Restore your SSH `config` from the encrypted backup, review it and set mode 600. Replace Windows paths in `IdentityFile`, `Include`, `IdentityAgent` and any Windows-specific `ProxyCommand`. For each host, select its corresponding public key:

```sshconfig
Host my-server
    HostName server.example.com
    User deploy
    IdentityFile ~/.ssh/bitwarden-keys/my_key.pub
    IdentitiesOnly yes
```

Then use `ws-ssh-agent ssh my-server` or `ws-ssh-agent git fetch`. The wrapper changes the agent socket only for that command and leaves forwarded agents alone. Check the server host fingerprint against your trusted backup before accepting a changed host key.

For normal terminal commands without the wrapper, add this to your private `~/.config/shell/local.sh` after agent setup:

```bash
export SSH_AUTH_SOCK="$HOME/snap/bitwarden/current/.bitwarden-ssh-agent.sock"
```

For desktop applications, put the same assignment (using `${HOME}`) in private `~/.config/environment.d/90-bitwarden-ssh.conf`, then log out and in. Existing SSH `IdentityAgent` directives can override this socket; review them. These opt-ins may replace another agent, so setup does not enable them automatically. Keep machine-specific hostnames and these private overrides outside dotfiles Git.

If you need disk-based private keys instead of the agent, restore them from the encrypted backup: `~/.ssh` mode 700, private keys/config mode 600, public keys mode 644. Preserve existing files and verify fingerprints before use. Do not delete the Windows backup after merely seeing keys in the vault.

## Validation scope

Synthetic keys test pair validation, encrypted-key rejection, collision handling, repeated upload, private-data redaction and public restore. Native `bw` installation and offline execution are tested separately. Real vault upload and desktop-agent authentication require your sign-in and remain a migration acceptance step. Setup never logs in or uploads keys automatically.

References: [Bitwarden CLI](https://bitwarden.com/help/cli/), [Bitwarden SSH agent/import](https://bitwarden.com/help/ssh-agent/).
