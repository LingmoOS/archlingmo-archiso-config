#!/usr/bin/env bash
set -e

# GTK icon cache
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  for theme in /usr/share/icons/*; do
    [ -d "$theme" ] || continue
    gtk-update-icon-cache -f -t "$theme" || true
  done
fi

# Desktop files (XDG)
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database /usr/share/applications || true
fi

# MIME database
if command -v update-mime-database >/dev/null 2>&1; then
  update-mime-database /usr/share/mime || true
fi

# GSettings schemas (alguns componentes leem schemas do Lingmo/GTK)
if command -v glib-compile-schemas >/dev/null 2>&1; then
  glib-compile-schemas /usr/share/glib-2.0/schemas || true
fi

# Fontconfig cache (evita tela preta em algumas VMs sem fontes pre-carregadas)
if command -v fc-cache >/dev/null 2>&1; then
  fc-cache -f >/dev/null 2>&1 || true
fi

# KDE service cache (ajuda icones/aplicativos do KF5 a aparecerem)
if command -v kbuildsycoca5 >/dev/null 2>&1; then
  kbuildsycoca5 --noincremental >/dev/null 2>&1 || true
fi

# Qt/QML caches (importante para o dock)
# Mantemos caches QML para evitar tela branca e recarregar QML no primeiro boot
