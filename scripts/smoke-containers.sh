#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
export DOCKER_HOST="unix://${XDG_RUNTIME_DIR:?A systemd user login is required}/podman/podman.sock"
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
project="ws-smoke-$(id -u)-$$"
work=$(mktemp -d "${TMPDIR:-/tmp}/ws-container-smoke.XXXXXX")
compose=(docker compose --project-name "$project" --file "$root/tests/compose.yaml")
cleanup() {
  local code=$?
  trap - EXIT
  "${compose[@]}" down --volumes --remove-orphans || true
  podman image rm "$project-build" >/dev/null 2>&1 || true
  [[ $work == "${TMPDIR:-/tmp}"/ws-container-smoke.* ]] && rm -rf -- "$work"
  exit "$code"
}
trap cleanup EXIT
[[ $(podman info --format '{{.Host.Security.Rootless}}') == true ]]
curl --fail --silent --unix-socket "$XDG_RUNTIME_DIR/podman/podman.sock" http://localhost/_ping | grep -F OK
printf 'FROM docker.io/library/alpine:3.22\nRUN printf "build-ok\\n" > /proof\nCMD ["cat", "/proof"]\n' >"$work/Containerfile"
docker build --tag "$project-build" "$work"
docker run --rm "$project-build" | grep -Fx build-ok
"${compose[@]}" config --quiet
"${compose[@]}" up --detach --wait --wait-timeout 120
"${compose[@]}" exec -T postgres psql -U postgres -v ON_ERROR_STOP=1 -c 'CREATE TABLE proof(value text); INSERT INTO proof VALUES ($$persistent$$);'
"${compose[@]}" exec -T cache valkey-cli ping | grep -Fx PONG
# Verify service-name networking and a bind exposed only on localhost.
"${compose[@]}" exec -T postgres sh -c 'getent hosts cache'
port=$("${compose[@]}" port postgres 5432)
[[ $port == 127.0.0.1:* ]]
"${compose[@]}" down
"${compose[@]}" up --detach --wait --wait-timeout 120
"${compose[@]}" exec -T postgres psql -U postgres -At -c 'SELECT value FROM proof' | grep -Fx persistent
printf 'Rootless builds, Docker bridge, Compose, health, networking and persistence passed.\n'
