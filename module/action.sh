#!/system/bin/sh
MODDIR=${0%/*}
PIDF="$MODDIR/frida-inject.pid"
PROP="$MODDIR/module.prop"

DESC_KILL='Click "Action" to kill frida-inject process'
DESC_START='Click "Action" to start frida-inject process'

update() {
  sed -i "s/^description=.*/description=$1/" "$PROP" 2>/dev/null
}

if [ -f "$PIDF" ]; then
  PID="$(cat "$PIDF" 2>/dev/null)"
  [ -n "$PID" ] && kill -9 "$PID" 2>/dev/null
  rm -f "$PIDF"
  update "$DESC_START"
  echo "Killed frida-inject (pid: $PID)"
  exit 0
fi

"$MODDIR/frida-inject" -f "__PKG__" -s "$MODDIR/_.js" --runtime="__RUNTIME__" &
echo $! > "$PIDF"
update "$DESC_KILL"
echo "Starting frida-inject (pid: $!)"
