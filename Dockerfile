FROM archlinux:latest

RUN pacman-key --init && \
    pacman-key --populate archlinux && \
    pacman -Syu --noconfirm archiso git grub && \
    pacman-key --lsign-key 'farseerfc@archlinux.org' && \
    echo '[archlinuxcn]' >> /etc/pacman.conf && \
    echo 'Server = https://repo.archlinuxcn.org/$arch' >> /etc/pacman.conf && \
    pacman --noconfirm -Sy archlinuxcn-keyring
RUN echo "Server"
COPY . /config
CMD ["sh", "-lc", "pacman --noconfirm -Syu && \
    mkarchiso -v /config/profile -o /out"]
