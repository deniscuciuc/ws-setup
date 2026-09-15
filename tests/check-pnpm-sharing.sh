#!/usr/bin/env bash
set -euo pipefail
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
cd "$work"
[[ $(pnpm config get preferOffline) == true ]]
git init -q primary
cd primary
git config user.name 'Workstation test'
git config user.email 'test@example.invalid'
printf '{"private":true,"packageManager":"pnpm@%s","dependencies":{"is-number":"7.0.0"}}\n' "${PNPM_TEST_VERSION:-11.21.0}" >package.json
pnpm install
git add package.json pnpm-lock.yaml
git commit -qm fixture
git worktree add -q -b sharing-test ../second
cd ../second
# An offline install proves that the second worktree can reuse downloaded data.
pnpm install --offline --frozen-lockfile
python3 - "$work" <<'PY'
import os, pathlib, sys
root=pathlib.Path(sys.argv[1])
relative='node_modules/.pnpm/is-number@7.0.0/node_modules/is-number/index.js'
a, b = root/'primary'/relative, root/'second'/relative
assert a.is_file() and b.is_file()
assert os.path.samefile(a,b), 'Packages are copies/clones rather than shared hardlinks; inspect filesystem/import method'
print('Two Git worktrees share the actual package inode; second install succeeded offline.')
PY
ws-storage pnpm . --probe
