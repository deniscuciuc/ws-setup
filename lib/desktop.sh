#!/usr/bin/env bash
gsetting() {
  local schema=$1 key=$2 value=$3
  if ! gsettings list-schemas | grep -qx "$schema"; then
    pending "Desktop setting unavailable: $schema $key"
    return
  fi
  if ! gsettings list-keys "$schema" | grep -qx "$key"; then
    pending "Desktop setting unavailable: $schema $key"
    return
  fi
  if [[ $(gsettings get "$schema" "$key") != "$value" ]]; then
    printf '%s\t%s\t%s\n' "$schema" "$key" "$(gsettings get "$schema" "$key")" >>"$STATE_DIR/reports/$RUN_ID.gsettings-before.tsv"
    gsettings set "$schema" "$key" "$value"
  fi
}

install_desktop() {
  apt_manifest desktop
  install_asset font
  flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo
  if flatpak info --user io.podman_desktop.PodmanDesktop >/dev/null 2>&1; then
    if [[ $ACTION == update ]]; then flatpak update --user --noninteractive io.podman_desktop.PodmanDesktop; fi
  elif [[ $ACTION == install ]]; then flatpak install --user --noninteractive flathub io.podman_desktop.PodmanDesktop; fi
  local extension existing
  existing=$(code --list-extensions)
  while IFS= read -r extension; do
    if ! grep -Fqx "$extension" <<<"$existing"; then
      if [[ $ACTION == install ]]; then code --install-extension "$extension"; fi
    fi
  done < <(lines "$REPO_ROOT/packages/vscode.txt")
  if [[ $ACTION == update ]]; then code --update-extensions; fi
  xdg-settings set default-web-browser brave-browser.desktop
  xdg-mime default brave-browser.desktop x-scheme-handler/http x-scheme-handler/https text/html
  gsetting org.gnome.desktop.interface color-scheme "'prefer-dark'"
  gsetting org.gnome.desktop.interface enable-animations false
  gsetting org.gnome.desktop.interface monospace-font-name "'JetBrainsMono Nerd Font 11'"
  # Add useful favorites without removing the user's existing favorites.
  local favorites merged
  favorites=$(gsettings get org.gnome.shell favorite-apps)
  merged=$(
    python3 - "$favorites" <<'PY'
import ast, pathlib, sys
current = [app for app in ast.literal_eval(sys.argv[1].removeprefix('@as ')) if app not in ['firefox.desktop', 'firefox_firefox.desktop']]
roots = [pathlib.Path('/usr/share/applications'), pathlib.Path.home()/'.local/share/applications', pathlib.Path.home()/'.local/share/flatpak/exports/share/applications']
for app in ['brave-browser.desktop', 'org.gnome.Ptyxis.desktop', 'code.desktop', 'io.podman_desktop.PodmanDesktop.desktop']:
    if app not in current and any((root/app).exists() for root in roots):
        current.append(app)
print(repr(current))
PY
  )
  gsetting org.gnome.shell favorite-apps "$merged"
  pending 'Ubuntu keeps its default terminal shortcut. Kitty is available in the launcher; both use the same Bash configuration.'
}

install_drivers() {
  apt_packages ubuntu-drivers-common pciutils vulkan-tools mesa-utils
  if lspci -nn | grep -Ei '(VGA|3D|Display)' | grep -qi nvidia; then
    sudo ubuntu-drivers install
    # Ubuntu's driver resolver chooses the matching branch, not a hard-coded GPU version.
    local driver
    driver=$(dpkg-query -W -f='${binary:Package}\n' 'nvidia-driver-*' 2>/dev/null | grep -E '^nvidia-driver-[0-9]+(-open)?$' | sort -V | tail -1)
    if [[ -n $driver ]]; then
      local branch=${driver#nvidia-driver-}
      branch=${branch%-open}
      apt_packages "libnvidia-gl-$branch:i386"
    fi
    pending 'Reboot, complete any Secure Boot key enrollment, then verify nvidia-smi, Vulkan, displays, suspend/resume and Steam.'
  else log 'No NVIDIA display adapter detected; keeping the Ubuntu graphics stack.'; fi
}
