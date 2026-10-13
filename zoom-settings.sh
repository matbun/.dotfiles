#!/bin/sh
# zoom-settings.sh — force Zoom settings that have no toggle in the Linux UI.
# Patched, not symlinked: Zoom rewrites zoomus.conf on exit and it holds host
# state. Quit Zoom first.

set -eu

CONF="${ZOOMUS_CONF:-$HOME/.config/zoomus.conf}"
KEY=enableMiniWindow
VAL=false

[ -f "$CONF" ] || { printf 'no %s\n' "$CONF" >&2; exit 1; }
! pgrep -x zoom >/dev/null 2>&1 || { printf 'quit Zoom first\n' >&2; exit 1; }

if grep -q "^$KEY=" "$CONF"; then
    sed -i "s/^$KEY=.*/$KEY=$VAL/" "$CONF"
else
    sed -i "/^\[General\]/a $KEY=$VAL" "$CONF"
fi
printf '  %s=%s\n' "$KEY" "$VAL"
