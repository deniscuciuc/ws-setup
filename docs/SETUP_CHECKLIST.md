# New Laptop Setup Checklist

## Before provisioning
- [ ] Back up files not stored in cloud storage.
- [ ] Create an Ubuntu 26.04 bootable USB.
- [ ] Ensure your password manager (Bitwarden) is accessible from another device.
- [ ] Note down any license keys for paid software.

## During provisioning
- [ ] Connect the new laptop to the internet.
- [ ] Open a terminal and run:
      ```bash
      curl -fsSL -o /tmp/bootstrap.sh https://github.com/deniscuciuc/ws-setup/raw/main/bootstrap.sh
      bash /tmp/bootstrap.sh
      ```
- [ ] Enter your sudo password when prompted.
- [ ] Wait for the provisioning script to complete.

## After provisioning
- [ ] Import your SSH private key from your backup or password manager.
- [ ] Import your GPG key.
- [ ] Run `gh auth login` and authenticate with GitHub.
- [ ] Open Firefox/Chrome and sign in to sync bookmarks, passwords, and extensions.
- [ ] Sign into the Bitwarden browser extension.
- [ ] Configure Syncthing and pair it with your other devices.
- [ ] Sign into communication apps: Discord, Telegram, Thunderbird.
- [ ] Sign into productivity apps: Spotify, Figma, OnlyOffice.
- [ ] Install any paid/proprietary software not covered by apt/snap.
- [ ] Verify zsh is the default shell: `chsh -s $(which zsh)`.
- [ ] Run `chezmoi diff` to confirm dotfiles are applied.
- [ ] Reboot the machine.

## Optional / per machine
- [ ] Uncomment NVIDIA/CUDA packages in `packages/apt.txt` and re-run the script if the new laptop has an NVIDIA GPU.
- [ ] Adjust GNOME settings, themes, keyboard shortcuts, and touchpad preferences manually.
