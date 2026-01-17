#!/bin/sh
set -eu

force_rebuild="${FORCE_REBUILD:-0}"
host_uid="${HOST_UID:-0}"
host_gid="${HOST_GID:-0}"

if [ "$force_rebuild" = "1" ]; then
  rm -rf /work/x86_64 /work/iso /work/*._* /work/iso.pacman.conf /work/profile-tmp || true
fi

rm -rf /work/profile-tmp
mkdir -p /work/profile-tmp
cp -a /config/profile/. /work/profile-tmp/

mkdir -p /work/profile-tmp/airootfs/opt/lingmo-localrepo
cp -a /localrepo/. /work/profile-tmp/airootfs/opt/lingmo-localrepo/
if [ -f /work/profile-tmp/airootfs/opt/lingmo-localrepo/lingmo-local.db.tar.gz ]; then
  ln -sf lingmo-local.db.tar.gz /work/profile-tmp/airootfs/opt/lingmo-localrepo/lingmo-local.db
  ln -sf lingmo-local.files.tar.gz /work/profile-tmp/airootfs/opt/lingmo-localrepo/lingmo-local.files
fi

pac=/work/profile-tmp/airootfs/etc/pacman.conf
if [ ! -f "$pac" ]; then
  echo "Missing pacman.conf at $pac" >&2
  find /work/profile-tmp -maxdepth 3 -type f | sed -n '1,200p' >&2
  exit 1
fi

if ! grep -q '^\[lingmo-local\]$' "$pac"; then
  tmp="$(mktemp)"
  printf "%s\n\n" \
    "[lingmo-local]" \
    "SigLevel = Optional TrustAll" \
    "Server = file:///opt/lingmo-localrepo" >"$tmp"
  cat "$pac" >>"$tmp"
  mv "$tmp" "$pac"
fi

# Use a build-time pacman.conf that points the local repo to the host-mounted
# directory (so pacstrap can install from it), while keeping the runtime config
# pointing to /opt/lingmo-localrepo inside the ISO.
#
# Do NOT write this to /work/iso.pacman.conf: mkarchiso itself copies the
# custom pacman.conf into that path and will overwrite it.
pac_build=/work/pacman.local.conf
sed 's#^Server = file:///opt/lingmo-localrepo$#Server = file:///localrepo#' "$pac" >"$pac_build"

# Prefer locally-built package naming when using the embedded repo.
pkgs=/work/profile-tmp/packages.x86_64
if [ -f "$pkgs" ]; then
  sed -i 's/^lingmoui$/LingmoUI/' "$pkgs" || true
  grep -qx 'lingmo-kwin-plugins' "$pkgs" || printf "\n%s\n" "lingmo-kwin-plugins" >>"$pkgs"
fi

mkarchiso -v -w /work -o /out -C "$pac_build" /work/profile-tmp
chown -R "$host_uid:$host_gid" /out /work
