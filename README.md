# ws-setup

Ansible playbook to reproduce my Ubuntu 26.04 developer workstation on a new laptop.

## Quick start on a fresh machine

Save the bootstrap script and run it from a terminal (so it can read your sudo password if needed):

```bash
curl -fsSL -o /tmp/bootstrap.sh https://github.com/deniscuciuc/ws-setup/raw/main/bootstrap.sh
bash /tmp/bootstrap.sh
```

If you prefer to cache sudo first, run `sudo -v` before the script.

## Manual run

```bash
git clone https://github.com/deniscuciuc/ws-setup.git ~/.local/share/ws-setup
cd ~/.local/share/ws-setup
./bootstrap.sh
```

## What it does

1. Installs Ansible and prerequisites.
2. Installs curated apt and snap packages.
3. Installs chezmoi and applies `deniscuciuc/dotfiles`.
4. Installs developer tools (nvm, pyenv, .NET SDK).
5. Writes `~/Desktop/SETUP_CHECKLIST.md` with manual post-install steps.

## Testing

```bash
# Syntax check
ansible-playbook --syntax-check -i inventory/localhost.yml playbook.yml

# Dry run
ansible-playbook -i inventory/localhost.yml playbook.yml --check --diff

# Docker smoke test
docker build -t ws-setup-test -f tests/Dockerfile .
docker run --rm ws-setup-test
```

## Customization

- Edit `group_vars/all/apt_packages.yml` to change apt packages.
- Edit `group_vars/all/snap_packages.yml` to change snaps.
- Edit `group_vars/all/vars.yml` to toggle devtools or change versions.
- Per-machine overrides can go in `host_vars/<hostname>.yml`.
