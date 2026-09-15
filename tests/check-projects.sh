#!/usr/bin/env bash
# Run only in a disposable Ubuntu VM/container: detector publishes fixed ports.
set -euo pipefail
[[ ${WS_DISPOSABLE_TEST:-} == 1 && $# == 2 ]] || {
  echo 'Usage in a disposable system: WS_DISPOSABLE_TEST=1 bash tests/check-projects.sh /path/to/peerbridge /path/to/imba-detector-poc-lm' >&2
  exit 2
}
export PATH="$HOME/.local/bin:$PATH"
export DOCKER_HOST="unix://${XDG_RUNTIME_DIR:?}/podman/podman.sock"
peer=$(realpath -e "$1/compose.local.yml")
detector=$(realpath -e "$2/docker-compose.yml")
project="ws-projects-$(id -u)-$$"
work=$(mktemp -d /tmp/ws-projects.XXXXXX)
cat >"$work/test.env" <<'EOF'
POSTGRES_DB=workstation_test
POSTGRES_USER=workstation_test
POSTGRES_PASSWORD=disposable-test-only
MINIO_ROOT_USER=workstation_test
MINIO_ROOT_PASSWORD=disposable-test-only
S3_PRIVATE_BUCKET=private-test
S3_PUBLIC_BUCKET=public-test
EOF
chmod 600 "$work/test.env"
p=(docker compose --project-name "$project-peer" --env-file "$work/test.env" --file "$peer")
if [[ ${WS_TEST_MINIO_QUAY:-} == 1 ]]; then
  p+=(--file "$(dirname -- "${BASH_SOURCE[0]}")/peerbridge-minio-quay.yaml")
fi
d=(docker compose --project-name "$project-detector" --env-file "$work/test.env" --file "$detector")
cleanup() {
  local status=$?
  trap - EXIT
  "${p[@]}" down --volumes --remove-orphans || true
  "${d[@]}" down --volumes --remove-orphans || true
  [[ $work == /tmp/ws-projects.* ]] && rm -rf -- "$work"
  exit "$status"
}
# Refuse shared/external storage before registering any destructive cleanup.
for file in "$peer" "$detector"; do
  docker compose --project-name "$project" --env-file "$work/test.env" --file "$file" config --format json >"$work/compose.json"
  python3 - "$work/compose.json" "$project" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assert all(not v.get('external') and v.get('name', '').startswith(sys.argv[2] + '_') for v in data.get('volumes', {}).values()), 'Shared/external volumes are not allowed'
assert all(not s.get('container_name') and all(v.get('type') == 'volume' for v in s.get('volumes', [])) for s in data['services'].values()), 'Only project-owned containers/volumes are allowed'
PY
done
trap cleanup EXIT
"${p[@]}" up --detach --wait --wait-timeout 180
"${p[@]}" exec -T postgres psql -U workstation_test -d workstation_test -At -c 'SELECT 1' | grep -Fx 1
"${p[@]}" exec -T valkey valkey-cli ping | grep -Fx PONG
curl --fail --silent http://127.0.0.1:43173/minio/health/ready
curl --fail --silent http://127.0.0.1:43176/api/v1/info >/dev/null
init_id=$("${p[@]}" ps --all --quiet minio-init)
[[ $(podman inspect --format '{{.State.ExitCode}}' "$init_id") == 0 ]]
"${d[@]}" up --detach --wait --wait-timeout 120
"${d[@]}" exec -T postgres psql -U detector -At -c 'SELECT 1' | grep -Fx 1
"${d[@]}" exec -T valkey valkey-cli ping | grep -Fx PONG
printf 'Existing project Compose workflows passed with isolated test data.\n'
