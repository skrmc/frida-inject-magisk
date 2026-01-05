case "$ARCH" in
  arm64) SRC="$MODPATH/bin/arm64/frida-inject" ;;
  arm)   SRC="$MODPATH/bin/arm/frida-inject" ;;
  x64)   SRC="$MODPATH/bin/x64/frida-inject" ;;
  x86)   SRC="$MODPATH/bin/x86/frida-inject" ;;
  *)     abort "unsupported arch: $ARCH" ;;
esac

cp -f "$SRC" "$MODPATH/frida-inject"
rm -rf "$MODPATH/bin"
set_perm "$MODPATH/frida-inject" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
