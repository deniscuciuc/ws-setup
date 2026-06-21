# ws-setup

Shell-based provisioning to reproduce my Ubuntu 26.04 developer workstation on a new laptop.

## Quick start on a fresh machine

```bash
curl -fsSL -o /tmp/bootstrap.sh https://github.com/deniscuciuc/ws-setup/raw/main/bootstrap.sh
bash /tmp/bootstrap.sh
```

## Manual run

```bash
git clone https://github.com/deniscuciuc/ws-setup.git ~/.local/share/ws-setup
cd ~/.local/share/ws-setup
./setup.sh
```

## What it does

1. Installs `git`, `curl`, and `software-properties-common`.
2. Installs curated apt packages (including Docker repo setup).
3. Installs curated snap packages.
4. Installs chezmoi and applies `deniscuciuc/dotfiles`.
5. Installs developer tools (nvm, pyenv, .NET SDK).
6. Writes `~/Desktop/SETUP_CHECKLIST.md` with manual post-install steps.

## File layout

```
ws-setup/
├── bootstrap.sh          # Entry point for fresh machines
├── setup.sh              # Main provisioning script
├── lib/                  # Modular setup steps
│   ├── apt.sh
│   ├── snap.sh
│   ├── dotfiles.sh
│   ├── devtools.sh
│   └── checklist.sh
├── packages/             # Package lists
│   ├── apt.txt
│   └── snap.txt
├── scripts/validate.sh   # Post-provisioning validation
├── tests/                # Docker smoke test
│   ├── Dockerfile
│   └── test.sh
└── docs/
    └── SETUP_CHECKLIST.md
```

## Testing

```bash
# Docker smoke test
docker build -t ws-setup-test -f tests/Dockerfile .
docker run --rm ws-setup-test
```

## Customization

- Edit `packages/apt.txt` to change apt packages.
- Edit `packages/snap.txt` to change snaps.
- Uncomment NVIDIA/CUDA lines in `packages/apt.txt` for NVIDIA GPUs.
