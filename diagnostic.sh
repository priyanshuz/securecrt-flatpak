#!/usr/bin/env bash
# diagnostic.sh — run inside Docker container
# Audits ldd dependencies for the SecureCRT binary and reports missing libraries.

set -euo pipefail

DEB=$(ls scrt-*.deb | head -1)
echo "Analyzing: $DEB"

mkdir -p /tmp/scrt-inspect
ar x "$DEB"
tar xf data.tar.* -C /tmp/scrt-inspect/

BINARY=$(find /tmp/scrt-inspect -name "SecureCRT" -type f | head -1)
echo "Binary: $BINARY"
echo ""
echo "=== ldd output ==="
ldd "$BINARY" 2>&1

echo ""
echo "=== MISSING libraries (=> not found) ==="
ldd "$BINARY" 2>&1 | grep "not found" | awk '{print $1}'

echo ""
echo "=== All required .so files ==="
ldd "$BINARY" 2>&1 | grep "=>" | awk '{print $1, $3}'
