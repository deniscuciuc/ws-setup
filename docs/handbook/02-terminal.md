# 2. Terminal and navigation

[Index](README.md) · Previous: [Overview](01-overview.md) · Next: [Development](03-development.md)

## Terminal versus shell

The terminal is the window: Ubuntu's default terminal, Kitty, or VS Code's integrated terminal. **Bash** is the program inside it that interprets commands. These three windows share the managed Bash configuration. Kitty is an additional option; you can keep using Ubuntu's terminal every day.

**Starship** draws a prompt with useful directory/project context. **ble.sh** adds interactive editing, suggestions and highlighting. **bash-completion** provides command-aware Tab completion. These are conveniences around Bash; scripts retain normal shell behavior. Interactive features load only for an interactive terminal, keeping automation and noninteractive commands quiet.

## Everyday tool choices

| Tool | Purpose | Try |
|---|---|---|
| `eza` | Readable file listings and short directory trees | `ll`, `treeview` |
| `bat` | Display a file with syntax coloring | `bat package.json` |
| `fd` | Find filenames | `fd '\.cs$'` |
| `rg` / ripgrep | Search file contents | `rg 'TODO' src` |
| `fzf` | Interactively choose from a list | Ctrl+R for history; Ctrl+T for files |
| `zoxide` | Remember frequently visited directories | `z my-project`, `zi` |
| `jq` | Query JSON | `jq '.scripts' package.json` |
| `yq` | Query YAML; installed by `tools` | `yq '.services' compose.yaml` |
| Nano | Simple terminal text editor | `nano notes.txt` |
| VS Code | Graphical editor | `code .`, `code --wait notes.txt` |
| `tmux` | Multiple terminal sessions that survive closing the client | `tmux new -s work` |

Inside tmux, Ctrl+B then D detaches from the session; `tmux attach -t work` returns to it. Detaching does not stop commands inside it. This helps with long local sessions, but it is not a substitute for a managed background service.

`ls`, `cat`, `find` and `grep` keep their standard meanings. The alternatives above are explicit. Ubuntu package names differ for two tools: `bat` supplies `batcat`, and `fd-find` supplies `fdfind`; setup exposes the familiar `bat` and `fd` commands.

## Shortcuts and aliases

| Action | Shortcut |
|---|---|
| Find a command in local history | Ctrl+R |
| Select a directory | Alt+C |
| Accept an editing suggestion | Right/End |
| Walk matching history | Type a prefix, then Up/Down |
| Parent / grandparent directory | `..` / `...` |
| Make a directory and enter it | `mkcd new-directory` |
| Git status / diff / graph | `gs` / `gd` / `gl` |
| Stage / commit / switch branch | `ga` / `gc` / `gsw` plus their Git arguments |
| Initialize/update project submodules | `gsm` |
| Open lazygit | `lg` |
| Compose wrapper / start / down / follow logs | `dc` / `dcu` / `dcd` / `dcl` |
| Running Podman containers | `dps` |
| Dotfiles diff / apply / status / edit | `czd` / `cza` / `czs` / `cze` |
| Backup / snapshots / integrity check | `backup` / `backups` / `backupcheck` |

Aliases are interactive Bash conveniences. Use full commands in scripts so they work without your interactive shell configuration. `dcu` starts the current project's services; `dcd` stops/removes its containers and networks. Volume handling is explained in [chapter 4](04-containers-databases.md).

## Kitty and editing defaults

Kitty uses the existing managed theme, JetBrainsMono Nerd Font, an opaque background and a 10,000-line scrollback. Ctrl+Shift+Enter opens a window/split in the current directory; Ctrl+Shift+T opens a tab there. Its configuration is deliberately short enough to read.

The terminal editor variable `EDITOR` is Nano. `VISUAL` is `code --wait`, so tools requesting a graphical editor wait until you finish editing. Nerd Font supplies prompt symbols; missing boxes in the prompt usually mean the terminal is using a different font.

## Customize or troubleshoot

Put personal aliases in `~/.config/bash/local.bash` and login environment overrides in `~/.config/shell/local.sh`. They are private and not versioned here. Never put tokens in a shared alias file or command history.

For a clean diagnostic shell, run `bash --noprofile --norc`. If that works and your normal terminal does not, inspect local overrides and run `ws-dotfiles diff`. Restart the login session after environment changes. A custom `.bash_profile` must source `.profile` to receive the managed login environment.

The configuration owner's detailed shortcut guide lives in [dotfiles/docs/TERMINAL.md](https://github.com/deniscuciuc/dotfiles/blob/main/docs/TERMINAL.md).
