#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT="$ROOT/agent"
TEMPLATE="$ROOT/module"
STAGE="$ROOT/.stage/module"
CACHE="$ROOT/.stage/cache"

FRIDA_VER="${FRIDA_VER:-}"
PKG_NAME="${PKG_NAME:-}"
RUNTIME="${RUNTIME:-v8}"

[ -n "$FRIDA_VER" ] || { echo "FRIDA_VER=17.x.y PKG_NAME=com.example.app $0"; exit 1; }
[ -n "$PKG_NAME" ] || { echo "FRIDA_VER=17.x.y PKG_NAME=com.example.app $0"; exit 1; }

command -v frida >/dev/null
command -v npm >/dev/null
command -v curl >/dev/null
command -v xz >/dev/null
command -v zip >/dev/null

rm -rf "$ROOT/.stage"
mkdir -p "$STAGE" "$CACHE"
cp -a "$TEMPLATE/." "$STAGE/"

( cd "$AGENT" && npm install && npm run build )
[ -f "$AGENT/_.js" ] || { echo "missing agent/_.js"; exit 1; }
cp -f "$AGENT/_.js" "$STAGE/_.js"

cat > "$STAGE/action.sh" <<EOF
#!/system/bin/sh
MODDIR=\${0%/*}
PIDFILE="\$MODDIR/frida-inject.pid"
PID=\$(cat "\$PIDFILE" 2>/dev/null)

if [ -n "\$PID" ] && kill -0 "\$PID" 2>/dev/null; then
  kill "\$PID" 2>/dev/null; sleep 0.2; kill -9 "\$PID" 2>/dev/null
  rm -f "\$PIDFILE"
  echo "stopped"
  exit 0
fi

"\$MODDIR/frida-inject" -f "$PKG_NAME" -s "\$MODDIR/_.js" --runtime="$RUNTIME" >/dev/null 2>&1 &
echo \$! > "\$PIDFILE"
echo "started"
EOF
chmod 0755 "$STAGE/action.sh"

BASE="https://github.com/frida/frida/releases/download/${FRIDA_VER}"

fetch() {
  local modarch="$1"
  local assetarch="$2"
  local name="frida-inject-${FRIDA_VER}-${assetarch}.xz"
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

ZIP="$ROOT/frida-inject-magisk-${FRIDA_VER}.zip"
rm -f "$ZIP"
( cd "$STAGE" && zip -qr "$ZIP" . )
echo "$ZIP"
