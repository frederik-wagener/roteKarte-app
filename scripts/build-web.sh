#!/usr/bin/env bash
# Baut die eigenständige Web-App (PWA) aus preview/index.html nach _site/ (oder $1).
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
out="${1:-$root/_site}"
version="$(git -C "$root" rev-parse --short HEAD 2>/dev/null || date +%s)"

rm -rf "$out"
mkdir -p "$out/icons"

{
  cat "$root/web/head.html"
  cat "$root/preview/index.html"
  printf '\n</body>\n</html>\n'
} > "$out/index.html"

cp "$root/web/manifest.webmanifest" "$out/"
cp "$root/web/icons/"*.png "$out/icons/"
sed "s/__VERSION__/$version/" "$root/web/sw.js" > "$out/sw.js"

echo "Web-App gebaut: $out (Version $version)"
