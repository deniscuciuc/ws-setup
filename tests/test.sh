#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# The Dockerfile already installs curl/git, but bootstrap.sh should also handle a clean system.
# Here we run setup.sh directly to test the provisioning logic.
# Desktop packages are skipped inside Docker because a full desktop environment
# is not available/needed in a container.
export PATH="$HOME/.local/bin:$PATH"
export WS_SETUP_SKIP_DESKTOP=1
bash setup.sh

# Validate
./scripts/validate.sh
