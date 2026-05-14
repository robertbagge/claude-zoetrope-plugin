#!/usr/bin/env bash
set -euo pipefail

if command -v zoetrope >/dev/null 2>&1; then
  exit 0
fi

cat >&2 <<'EOF'
zoetrope is not on PATH.

See https://github.com/robertbagge/zoetrope for installation instructions.
EOF
exit 127
