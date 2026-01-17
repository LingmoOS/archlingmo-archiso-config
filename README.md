# archlingmo-archiso-config
Archiso config used by ArchLingmo (a branch of Lingmo OS based on Arch Linux).
> [!NOTE]
> This project is still WIP and not ready for production environment.

## Build
```console
# pacman -Syu archiso git grub
# pacman -Syu base-devel pacman-contrib   # necessário para `make pkgs`/`make build`
# pacman-key --lsign-key 'farseerfc@archlinux.org'
# cat >> /etc/pacman.conf << EOF
[archlinuxcn]
Server = https://repo.archlinuxcn.org/$arch
EOF
# pacman -Sy archlinuxcn-keyring
$ git clone --depth 1 https://github.com/LingmoOS/archlingmo-archiso-config
$ cd archlingmo-archiso-config

# ISO (normal)
$ make iso

# ISO via container (se não tiver `archiso`/`mkarchiso` no host)
$ make iso-container

# ISO via container usando pacotes buildados em `$(PKGBUILDER_DIR)/outputs` (recomendado durante dev)
$ make iso-container-local

# ISO offline com repositório local embutido (pacotes Lingmo buildados localmente)
# - ajusta/override via PKGBUILDER_DIR e LOCAL_REPO_DIR
$ make build
```
Find the ISO file in `out/` after building.
### See also
[Archiso page on ArchWiki](https://wiki.archlinux.org/title/Archiso)
