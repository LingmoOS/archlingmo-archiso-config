#!/bin/sh
set -eu

out_dir="${OUT_DIR:-./out}"
build_target="${BUILD_TARGET:-}"
pkgbuilder_dir="${PKGBUILDER_DIR:-}"
serial_log="${QEMU_SERIAL_LOG:-$out_dir/qemu-serial.log}"
disk="${QEMU_DISK:-$out_dir/archlingmo.qcow2}"
disk_size="${QEMU_DISK_SIZE:-30G}"

if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
  echo "qemu-system-x86_64 not found. Install qemu and try again." >&2
  exit 1
fi

if [ "$disk" != "none" ]; then
  if ! command -v qemu-img >/dev/null 2>&1; then
    echo "qemu-img not found. Install qemu and try again (needed to create a virtual disk for the installer)." >&2
    exit 1
  fi
  if [ ! -f "$disk" ]; then
    echo "Creating QEMU disk: $disk ($disk_size)..." >&2
    qemu-img create -f qcow2 "$disk" "$disk_size" >/dev/null
  fi
fi

iso="$(ls -1t "$out_dir"/archlingmo-*.iso 2>/dev/null | head -n 1 || true)"
if [ -z "$iso" ]; then
  if [ -z "$build_target" ]; then
    if [ -n "$pkgbuilder_dir" ] && [ -d "$pkgbuilder_dir" ]; then
      build_target="iso-local"
    else
      build_target="iso"
    fi
  fi
  if ! command -v mkarchiso >/dev/null 2>&1; then
    if command -v docker >/dev/null 2>&1 || command -v podman >/dev/null 2>&1; then
      if [ "$build_target" = "iso-local" ]; then
        if [ -n "$pkgbuilder_dir" ] && [ -d "$pkgbuilder_dir/outputs" ]; then
          echo "mkarchiso not found; falling back to 'iso-container-local' (uses $pkgbuilder_dir/outputs)." >&2
          build_target="iso-container-local"
        else
          echo "mkarchiso not found; falling back to 'iso-container' (no embedded local repo)." >&2
          build_target="iso-container"
        fi
      else
        echo "mkarchiso not found; using 'iso-container'." >&2
        build_target="iso-container"
      fi
    fi
  fi
  echo "No ISO found in $out_dir. Building with 'make $build_target'..." >&2
  make "$build_target"
  iso="$(ls -1t "$out_dir"/archlingmo-*.iso 2>/dev/null | head -n 1 || true)"
fi
if [ -z "$iso" ]; then
  echo "ISO build failed or no ISO found in $out_dir." >&2
  exit 1
fi

mem="${QEMU_MEM:-4096}"

mkdir -p "$(dirname "$serial_log")"
: >"$serial_log"
echo "QEMU serial log: $serial_log" >&2

args=""
if [ "$disk" != "none" ]; then
  args="$args -drive file=$disk,if=virtio,format=qcow2"
fi

exec qemu-system-x86_64 -enable-kvm -m "$mem" -cdrom "$iso" -boot d -vga virtio \
  -serial "file:$serial_log" $args
