#!/usr/bin/env bash
# shellcheck disable=SC2034
# Shared configuration, consumed by the setup entry point and modules.
NODE_VERSION=24.18.0
COREPACK_VERSION=0.35.0
PNPM_VERSION=11.21.0
PYTHON_VERSION=3.13
DOTNET_VERSION=10.0
DOTFILES_URL=https://github.com/deniscuciuc/dotfiles.git
# Candidates use --dotfiles-source; merge the matching dotfiles change first.
DOTFILES_REF=main
