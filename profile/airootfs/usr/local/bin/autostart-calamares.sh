#!/usr/bin/env bash
set -euo pipefail

LOCKFILE="/run/calamares-autostart.lock"
LOGFILE="/tmp/calamares-autostart.log"

{
  echo "----"
  echo "$(date -Is) starting autostart-calamares"
  echo "DISPLAY=${DISPLAY:-} XAUTHORITY=${XAUTHORITY:-}"
} >>"$LOGFILE"

if [ -e "$LOCKFILE" ]; then
  if pgrep -x calamares >/dev/null 2>&1; then
    echo "calamares already running; exiting" >>"$LOGFILE"
    exit 0
  fi
  echo "stale lock detected; removing" >>"$LOGFILE"
  rm -f "$LOCKFILE"
fi
touch "$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT

export QT_QUICK_BACKEND="${QT_QUICK_BACKEND:-software}"
export QT_OPENGL="${QT_OPENGL:-software}"
export QSG_RHI_BACKEND="${QSG_RHI_BACKEND:-software}"
export QSG_RENDER_LOOP="${QSG_RENDER_LOOP:-basic}"
export LIBGL_ALWAYS_SOFTWARE="${LIBGL_ALWAYS_SOFTWARE:-1}"
export QT_QUICK_CONTROLS_STYLE="${QT_QUICK_CONTROLS_STYLE:-lingmo-style}"

if command -v calamares_polkit >/dev/null 2>&1; then
  echo "launching calamares_polkit" >>"$LOGFILE"
  exec calamares_polkit >>"$LOGFILE" 2>&1
fi

echo "launching calamares" >>"$LOGFILE"
exec calamares >>"$LOGFILE" 2>&1
