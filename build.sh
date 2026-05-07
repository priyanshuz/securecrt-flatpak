#!/usr/bin/env bash
set -euo pipefail

DEB_FILE=$(ls scrt-*.deb 2>/dev/null | head -1)
[ -z "$DEB_FILE" ] && { echo "ERROR: No scrt-*.deb found in current directory"; exit 1; }

echo "Found: $DEB_FILE"

# Update manifest to reference the actual .deb filename
sed -i "s|scrt-[0-9].*\.deb|${DEB_FILE}|g" com.vandyke.SecureCRT.yml

# Run diagnostics first
echo "Running library dependency check..."
bash diagnostic.sh

# Build a host library bundle for non-bundled dependencies detected by ldd
echo "Preparing host compatibility library bundle..."
rm -rf host-libs host-libs.tar.gz
mkdir -p host-libs

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT
cp "$DEB_FILE" "$TMPDIR/"
(
  cd "$TMPDIR"
  ar x "$DEB_FILE"
  tar xf data.tar.*
)

BINARY="$TMPDIR/usr/bin/SecureCRT"
[ ! -f "$BINARY" ] && { echo "ERROR: Could not locate extracted SecureCRT binary"; exit 1; }

# Only bundle compatibility libraries that are commonly missing from
# freedesktop runtime but safe to ship without replacing core glibc pieces.
NEEDED_LIBS=(
  libicui18n.so.74
  libicuuc.so.74
  libicudata.so.74
  libgssapi_krb5.so.2
  libkrb5.so.3
  libk5crypto.so.3
  libcom_err.so.2
  libkrb5support.so.0
  libkeyutils.so.1
  libpcre2-16.so.0
  libxcb-cursor.so.0
  libjpeg.so.8
)

while read -r lib path; do
  [ -z "${lib:-}" ] && continue
  [ -z "${path:-}" ] && continue

  match=0
  for needed in "${NEEDED_LIBS[@]}"; do
    if [ "$lib" = "$needed" ]; then
      match=1
      break
    fi
  done
  [ "$match" -eq 1 ] || continue

  dir=$(dirname "$path")
  for candidate in "$dir/$lib" "$path"; do
    [ -e "$candidate" ] || continue
    cp -a "$candidate" host-libs/ 2>/dev/null || true

    resolved=$(readlink -f "$candidate" 2>/dev/null || true)
    if [ -n "${resolved:-}" ] && [ -e "$resolved" ]; then
      cp -a "$resolved" host-libs/ 2>/dev/null || true
    fi
  done
done < <(ldd "$BINARY" 2>/dev/null | awk '/=> \/[^ ]+/ {print $1, $3}')

# Handle libraries that may not resolve during ldd in this container.
for needed in "${NEEDED_LIBS[@]}"; do
  for candidate in /lib/x86_64-linux-gnu/${needed}* /usr/lib/x86_64-linux-gnu/${needed}*; do
    [ -e "$candidate" ] || continue
    cp -a "$candidate" host-libs/ 2>/dev/null || true
  done
done

tar czf host-libs.tar.gz host-libs
rm -rf host-libs
echo "Host compatibility bundle created: host-libs.tar.gz"

# Bundle org.gnome.desktop.interface GSettings schema so Qt6's libqgtk3.so
# can call g_settings_new("org.gnome.desktop.interface") inside the sandbox.
SCHEMA_SRC="/usr/share/glib-2.0/schemas/org.gnome.desktop.interface.gschema.xml"
if [ -f "$SCHEMA_SRC" ]; then
  cp "$SCHEMA_SRC" .
  echo "Copied GSettings schema: org.gnome.desktop.interface.gschema.xml"
else
  echo "WARNING: GSettings schema not found at $SCHEMA_SRC"
fi

echo "Building Flatpak..."
flatpak-builder \
  --force-clean \
  --disable-rofiles-fuse \
  --repo=repo \
  build-dir \
  com.vandyke.SecureCRT.yml

echo "Bundling..."
flatpak build-bundle repo \
  SecureCRT.flatpak \
  com.vandyke.SecureCRT

echo ""
echo "============================="
echo "Output: SecureCRT.flatpak"
echo "Install on host:"
echo "  flatpak install --user SecureCRT.flatpak"
echo "Run:"
echo "  flatpak run com.vandyke.SecureCRT"
echo "============================="
