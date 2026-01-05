#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT="$ROOT/agent"
TEMPLATE="$ROOT/module"
STAGE="$ROOT/.stage/module"
CACHE="$ROOT/.stage/cache"

FRIDA_VERSION="${FRIDA_VERSION:-17.5.2}"
RUNTIME="${RUNTIME:-v8}"
PKG="${PKG:-}"

[ -n "$PKG" ] || { echo "PKG=com.example.app $0"; exit 1; }

command -v frida > /dev/null
command -v npm > /dev/null
command -v curl > /dev/null
command -v xz > /dev/null
command -v zip > /dev/null
command -v sed > /dev/null

rm -rf "$ROOT/.stage"
mkdir -p "$STAGE" "$CACHE"
cp -a "$TEMPLATE/." "$STAGE/"

( cd "$AGENT" && npm install && npm run build )
cp -f "$AGENT/_.js" "$STAGE/_.js"

escape() { printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'; }
PKG_ESC="$(escape "$PKG")"
RUN_ESC="$(escape "$RUNTIME")"

sed -i \
  -e "s/__PKG__/${PKG_ESC}/g" \
  -e "s/__RUNTIME__/${RUN_ESC}/g" \
  "$STAGE/action.sh"

BASE="https://github.com/frida/frida/releases/download/${FRIDA_VERSION}"

fetch() {
  local modarch="$1"
  local assetarch="$2"
  local name="frida-inject-${FRIDA_VERSION}-${assetarch}.xz"
  local url="${BASE}/${name}"
  local xzpath="${CACHE}/${name}"
  local outpath="${STAGE}/bin/${modarch}/frida-inject"
  mkdir -p "$(dirname "$outpath")"
  [ -f "$xzpath" ] || curl -fL --retry 3 --retry-delay 1 -o "$xzpath" "$url"
  xz -dc "$xzpath" > "$outpath"
  chmod 0755 "$outpath"
}

fetch arm64 android-arm64
fetch arm   android-arm
fetch x64   android-x86_64
fetch x86   android-x86

ZIP="$ROOT/frida-inject-magisk-${FRIDA_VERSION}.zip"
rm -f "$ZIP"
( cd "$STAGE" && zip -qr "$ZIP" . )
echo "$ZIP"
