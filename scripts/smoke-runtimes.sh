#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1 COREPACK_ENABLE_DOWNLOAD_PROMPT=0
work=$(mktemp -d "${TMPDIR:-/tmp}/ws-runtime-smoke.XXXXXX")
cleanup() { [[ $work == "${TMPDIR:-/tmp}"/ws-runtime-smoke.* ]] && rm -rf -- "$work"; }
trap cleanup EXIT
cd "$work"
dotnet new console --framework net10.0 --no-restore -o dotnet-smoke
dotnet run --project dotnet-smoke | grep -F 'Hello, World!'
uv run --python 3.13 python -c 'import sqlite3, ssl; print("Python, SQLite and TLS OK")'
node -e 'if (process.versions.node.split(".")[0] !== "24") process.exit(1); console.log(process.version)'
for version in 11.17.0 11.21.0; do
  mkdir "pnpm-$version"
  printf '{"private":true,"packageManager":"pnpm@%s"}\n' "$version" >"pnpm-$version/package.json"
  (
    cd "pnpm-$version"
    pnpm --version | grep -Fx "$version"
  )
done
claude --version
codex --version
mongosh --version
sqlcmd --version
printf 'Runtime smoke checks passed.\n'
