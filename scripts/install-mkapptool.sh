#!/usr/bin/env bash
# Helper for Gatekeeper-blocked MKAppTool.pkg installs (see mkBox issue #1).
set -euo pipefail

PKG="${1:-$HOME/Downloads/MKAppTool.pkg}"

if [[ ! -f "$PKG" ]]; then
  echo "PKG not found: $PKG"
  echo "Usage: $0 [/path/to/MKAppTool.pkg]"
  exit 1
fi

xattr -cr "$PKG"
open "$PKG"
