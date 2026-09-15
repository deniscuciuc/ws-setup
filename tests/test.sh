#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
mapfile -d '' scripts < <(find . -name '*.sh' -not -path './.git/*' -print0)
for script in "${scripts[@]}"; do bash -n "$script"; done
shellcheck -x -S warning "${scripts[@]}"
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p 'test_*.py' -v
if [[ -d ${DOTFILES_SOURCE:-/dotfiles} ]]; then
  PYTHONDONTWRITEBYTECODE=1 python3 "${DOTFILES_SOURCE:-/dotfiles}/tests/test_dotfiles.py"
fi
printf 'Static and regression checks passed. See docs/TESTING.md for integration/desktop tests.\n'
