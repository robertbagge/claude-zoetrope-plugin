#!/usr/bin/env bash
set -euo pipefail

if command -v zoetrope >/dev/null 2>&1; then
  exit 0
fi

cat >&2 <<'EOF'
zoetrope is not on PATH.

Install options:
  - macOS (Homebrew):  brew install robertbagge/tap/zoetrope
  - From source:       cargo install --path crates/zoetrope-cli

Do not attempt to install it automatically.
EOF
exit 127
