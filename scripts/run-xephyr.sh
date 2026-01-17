#!/bin/sh
set -eu

display_num="${DISPLAY_NUM:-2}"
screen="${SCREEN:-1280x720}"

if ! command -v Xephyr >/dev/null 2>&1; then
  echo "Xephyr not found. Install xorg-server-xephyr and try again." >&2
  exit 1
fi

if [ ! -d /usr/share/xsessions ]; then
  echo "/usr/share/xsessions not found. Install the Lingmo session on the host." >&2
  exit 1
fi

find_session_file() {
  for f in /usr/share/xsessions/*.desktop; do
    case "$f" in
      *lingmo*|*Lingmo*)
        printf "%s" "$f"
        return 0
        ;;
    esac
  done

  for f in /usr/share/xsessions/*.desktop; do
    if grep -qi "lingmo" "$f"; then
      printf "%s" "$f"
      return 0
    fi
  done

  return 1
}

session_file="$(find_session_file || true)"
if [ -z "$session_file" ]; then
  echo "Lingmo session not found in /usr/share/xsessions. Install Lingmo packages on the host." >&2
  exit 1
fi

exec_line="$(sed -n 's/^Exec=//p' "$session_file" | head -n 1)"
if [ -z "$exec_line" ]; then
  echo "Exec= not found in $session_file" >&2
  exit 1
fi

# Remove desktop field codes (like %f, %u) from Exec=.
exec_line="$(printf "%s" "$exec_line" | sed 's/ *%[a-zA-Z]//g')"

Xephyr ":${display_num}" -screen "${screen}" -ac -resizeable &
xephyr_pid=$!

cleanup() {
  kill "$xephyr_pid" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

DISPLAY=":${display_num}" dbus-run-session sh -lc "$exec_line"
