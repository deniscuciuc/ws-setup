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
- [ ] Authenticate the AI coding assistants (login/API keys cannot be automated):
      - `gh auth login` (if the Copilot `gh` extension wasn't installed automatically, also run `gh extension install github/gh-copilot --pin v1.2.0`)
      - `gh copilot explain "hello"` to verify the Copilot extension is signed in
      - `claude` and follow the browser login, or set `ANTHROPIC_API_KEY`
      - `codex` and follow the browser login, or set `OPENAI_API_KEY`
      - `kimi` then run `/login` in the TUI, or set a Moonshot API key
- [ ] Create `~/.config/copilot/deepseek.env` if you use the Copilot DeepSeek helper in `.zshrc`.
- [ ] Verify core developer runtimes:
      - `node -v` should print `v26.3.0`
      - `pnpm -v` should print `11.5.2`
      - `dotnet --version` should print `10.0.109`
- [ ] Open Firefox/Chrome and sign in to sync bookmarks, passwords, and extensions.
- [ ] Sign into the Bitwarden browser extension.
- [ ] Configure Syncthing and pair it with your other devices.
- [ ] Sign into communication apps: Discord, Telegram, Thunderbird.
- [ ] Sign into productivity apps: Spotify, Figma, OnlyOffice.
- [ ] Install any paid/proprietary software not covered by apt/snap.
- [ ] Log out and back in (or reboot) so zsh and kitty defaults take effect.
- [ ] Run `chezmoi diff` to confirm dotfiles are applied.
- [ ] Reboot the machine.

## Optional / per machine
- [ ] Uncomment NVIDIA/CUDA packages in `packages/apt.txt` and re-run the script if the new laptop has an NVIDIA GPU.
- [ ] Adjust GNOME settings, themes, keyboard shortcuts, and touchpad preferences manually.
