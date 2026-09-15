#!/usr/bin/env bash
install_asset() {
  local name=$1 entry kind sha url version archive work member output package current
  entry=$(jq -ce --arg name "$name" '.assets[$name] // error("Unknown asset")' "$REPO_ROOT/config/assets.lock.json")
  kind=$(jq -r .kind <<<"$entry")
  sha=$(jq -r .sha256 <<<"$entry")
  url=$(jq -r .url <<<"$entry")
  version=$(jq -r .version <<<"$entry")
  local receipt="$STATE_DIR/assets/$name.json"
  if [[ $ACTION == update && ! -f $receipt ]]; then
    log "$name is not managed; skipping"
    return
  fi
  if [[ -f $receipt ]] && [[ $(jq -r .sha256 "$receipt") == "$sha" ]]; then
    if python3 "$REPO_ROOT/scripts/asset-receipt.py" check "$receipt"; then
      log "$name $version is current"
      return
    fi
  fi
  archive="$CACHE_DIR/downloads/$sha-${url##*/}"
  download_verified "$url" "$sha" "$archive"
  mkdir -p "$HOME/.local/bin" "$STATE_DIR/assets"
  local installed_paths=()
  if [[ $kind == deb ]]; then
    package=$(dpkg-deb -f "$archive" Package)
    local deb_version
    deb_version=$(dpkg-deb -f "$archive" Version)
    current=$(dpkg-query -W -f='${Version}' "$package" 2>/dev/null || true)
    if [[ -z $current ]] || dpkg --compare-versions "$current" lt "$deb_version"; then
      sudo env DEBIAN_FRONTEND=noninteractive apt-get --yes --no-remove install "$archive"
    fi
    python3 "$REPO_ROOT/scripts/asset-receipt.py" deb "$receipt" "$sha" "$version" "$package" "$deb_version"
    return
  fi
  if [[ $kind == binary ]]; then
    output=$(jq -r '.binaries[""]' <<<"$entry")
    write_user_file "$HOME/.local/bin/$output" 755 <"$archive"
    installed_paths+=("$HOME/.local/bin/$output")
  else
    work=$(mktemp -d "$CACHE_DIR/extract.XXXXXX")
    # Python's data filter rejects absolute paths, escaping symlinks and devices.
    python3 - "$archive" "$work" <<'PY'
import sys, tarfile, zipfile
from pathlib import Path
if zipfile.is_zipfile(sys.argv[1]):
    with zipfile.ZipFile(sys.argv[1]) as archive:
        for member in archive.infolist():
            path = Path(member.filename)
            if path.is_absolute() or ".." in path.parts or "\\" in member.filename or (member.external_attr >> 16) & 0o170000 == 0o120000:
                raise ValueError("Unsafe ZIP member")
        archive.extractall(sys.argv[2])
else:
    with tarfile.open(sys.argv[1]) as archive:
        archive.extractall(sys.argv[2], filter="data")
PY
    case $kind in
      tar | zip)
        while IFS=$'\t' read -r member output; do
          [[ -f $work/$member ]] || die "Missing $member in $name archive"
          write_user_file "$HOME/.local/bin/$output" 755 <"$work/$member"
          installed_paths+=("$HOME/.local/bin/$output")
        done < <(jq -r '.binaries | to_entries[] | [.key,.value] | @tsv' <<<"$entry")
        ;;
      blesh)
        local ble_main ble_root relative path
        ble_main=$(find "$work" -name ble.sh -type f -print -quit)
        [[ -n $ble_main ]] || die 'ble.sh missing from archive'
        ble_root=$(dirname "$ble_main")
        while IFS= read -r -d '' path; do
          relative=${path#"$ble_root/"}
          write_user_file "$HOME/.local/share/blesh/$relative" 644 <"$path"
          installed_paths+=("$HOME/.local/share/blesh/$relative")
        done < <(find "$ble_root" -type f -print0)
        ;;
      font)
        local path
        while IFS= read -r -d '' path; do
          output="$HOME/.local/share/fonts/JetBrainsMono/${path##*/}"
          write_user_file "$output" 644 <"$path"
          installed_paths+=("$output")
        done < <(find "$work" -type f \( -name '*.ttf' -o -name 'LICENSE*' -o -name 'OFL*' \) -print0)
        fc-cache -f "$HOME/.local/share/fonts"
        ;;
      *) die "Unsupported asset kind: $kind" ;;
    esac
    # Only remove the temporary directory returned by mktemp inside our cache.
    [[ $work == "$CACHE_DIR"/extract.* ]] && rm -rf -- "$work"
  fi
  ((${#installed_paths[@]})) || die "$name installed no files"
  python3 "$REPO_ROOT/scripts/asset-receipt.py" files "$receipt" "$sha" "$version" "${installed_paths[@]}"
}
