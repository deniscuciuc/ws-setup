#!/usr/bin/env bash
add_repository() {
  local name=$1 uri=$2 suite=$3 components=$4 architectures=${5:-amd64} key_path=${6:-/etc/apt/keyrings/ws-$1.gpg}
  local entry sha url key converted
  entry=$(jq -ce --arg name "$name-key" '.assets[$name] // error("Missing repository key")' "$REPO_ROOT/config/assets.lock.json")
  sha=$(jq -r .sha256 <<<"$entry")
  url=$(jq -r .url <<<"$entry")
  key="$CACHE_DIR/downloads/$sha.key"
  download_verified "$url" "$sha" "$key"
  converted=$(mktemp "$CACHE_DIR/key.XXXXXX")
  gpg --batch --show-keys "$key" >/dev/null
  gpg --batch --yes --dearmor --output "$converted" "$key"
  write_system_file "$key_path" <"$converted"
  rm -f -- "$converted"
  printf 'deb [arch=%s signed-by=%s] %s %s %s\n' \
    "$architectures" "$key_path" "$uri" "$suite" "$components" | write_system_file "/etc/apt/sources.list.d/ws-$name.list"
}

steam_repository() {
  if [[ -r /etc/apt/sources.list.d/steam-stable.list && -r /usr/share/keyrings/steam.gpg ]] && grep -Fq 'https://repo.steampowered.com/steam/ stable steam' /etc/apt/sources.list.d/steam-stable.list; then
    printf '# Steam now manages steam-stable.list and its signing key.\n' | write_system_file /etc/apt/sources.list.d/ws-steam.list
  else
    # Use Valve's key path so a partially completed install cannot leave Signed-By conflicts.
    add_repository steam https://repo.steampowered.com/steam/ stable steam amd64,i386 /usr/share/keyrings/steam.gpg
  fi
}
