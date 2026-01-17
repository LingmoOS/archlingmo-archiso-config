#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="archlingmo"
iso_label="ARCHLINGMO_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="LingmoOS Team <https://lingmo.org>"
iso_application="ArchLingmo Live/Rescue DVD"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito'
           'uefi-ia32.grub.esp' 'uefi-x64.grub.esp'
           'uefi-ia32.grub.eltorito' 'uefi-x64.grub.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
#airootfs_image_tool_options=('-mem-percent' '75' '-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
airootfs_image_tool_options=('-comp' 'zstd')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/sudoers.d"]="0:0:750"
  ["/etc/sudoers.d/10-lingmo-nopasswd"]="0:0:440"
  ["/root/customize_airootfs.sh"]="0:0:755"
  ["/usr/local/bin/autostart-calamares.sh"]="0:0:755"
  ["/usr/local/bin/lingmo-session-wrapper"]="0:0:755"
  ["/usr/local/bin/lingmo-session-start"]="0:0:755"
)
