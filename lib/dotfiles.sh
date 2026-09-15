#!/usr/bin/env bash
remove_legacy_shell_switch() {
  [[ -f $HOME/.bashrc ]] || return 0
  local cleaned
  cleaned=$(mktemp "$CACHE_DIR/bashrc.XXXXXX")
  python3 "$REPO_ROOT/scripts/migrate-bashrc.py" "$HOME/.bashrc" >"$cleaned"
  write_user_file "$HOME/.bashrc" 644 <"$cleaned"
  rm -f -- "$cleaned"
}

install_dotfiles() {
  local source_dir=$DOTFILES_SOURCE path
  if [[ -z $source_dir ]]; then
    source_dir="$HOME/.local/share/chezmoi"
    if [[ -d $source_dir/.git ]]; then
      [[ -z $(git -C "$source_dir" status --porcelain) ]] || die 'Dotfiles source is dirty. Commit/review it, or use --dotfiles-source to apply it without fetching.'
      [[ $(git -C "$source_dir" remote get-url origin) == "$DOTFILES_URL" ]] || die 'Unexpected dotfiles origin; use --dotfiles-source for an intentional local source.'
      [[ $(git -C "$source_dir" branch --show-current) == "$DOTFILES_REF" ]] || die "Dotfiles are on another branch. Follow docs/CUSTOMIZATION.md or use --dotfiles-source."
      git -C "$source_dir" pull --ff-only origin "$DOTFILES_REF"
    elif [[ -e $source_dir ]]; then
      die "Dotfiles destination already exists: $source_dir"
    else git clone --branch "$DOTFILES_REF" "$DOTFILES_URL" "$source_dir"; fi
  fi
  [[ -f $source_dir/.workstation-dotfiles-version ]] || die 'Dotfiles source is not the Bash workstation configuration. Use the matching candidate branch.'
  [[ $(cat "$source_dir/.workstation-dotfiles-version") == 1 ]] || die 'Unsupported dotfiles schema'
  local -a chez=(chezmoi --source "$source_dir" --destination "$HOME")
  # Render first. Invalid templates fail before touching the home directory.
  (
    umask 022
    "${chez[@]}" diff
  ) >"$STATE_DIR/reports/$RUN_ID.dotfiles.diff"
  while IFS= read -r path; do
    [[ $path == "$HOME/"* ]] || die "Unexpected chezmoi target: $path"
    if [[ -f $path || -L $path ]]; then backup_file "$path"; fi
  done < <("${chez[@]}" managed --path-style absolute)
  remove_legacy_shell_switch
  # The source manages a small Bash include using a chezmoi modify script,
  # preserving the user's existing .bashrc. Other managed files are backed up.
  (
    umask 022
    "${chez[@]}" apply --force
  )
  printf '%s\n' "$source_dir" >"$STATE_DIR/dotfiles-source"
  local current_shell
  current_shell=$(getent passwd "$(id -un)" | cut -d: -f7)
  if [[ $current_shell != /bin/bash ]]; then sudo chsh -s /bin/bash "$(id -un)"; fi
  # Retire only the exact former default-terminal entries owned by ws-setup.
  for path in "$HOME/.config/ubuntu-xdg-terminals.list" "$HOME/.config/gnome-xdg-terminals.list" "$HOME/.config/xdg-terminals.list"; do
    if [[ -f $path && $(cat "$path") == kitty.desktop ]]; then
      backup_file "$path"
      rm -f -- "$path"
    fi
  done
  pending 'Restart your login session. Existing Zsh/Neovim files are left on disk but are no longer installed or managed by this setup.'
}
