#!/usr/bin/env bash
set -euo pipefail

cd "$PROJECT_DIR"
if [[ -f package.json ]]; then
  npm install
fi
