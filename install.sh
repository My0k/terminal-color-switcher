#!/bin/bash
#
# install.sh - instala "gcolor" en /usr/local/bin.
#
# Antes de nada comprueba que Ghostty este instalado: es el backend para el que
# esta pensada la herramienta. Si no lo encuentra, no instala nada y muestra
# como conseguirlo.

set -euo pipefail

DESTINO="${DESTINO:-/usr/local/bin}"
ORIGEN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

rojo() { printf '\033[1;31m%s\033[0m\n' "$*"; }
verde() { printf '\033[1;32m%s\033[0m\n' "$*"; }
gris() { printf '\033[2m%s\033[0m\n' "$*"; }

# ------------------------------------------------------------ requisito: ghostty
if ! command -v ghostty >/dev/null 2>&1; then
  echo ""
  rojo "  No encuentro Ghostty."
  echo ""
  echo "  gcolor abre ventanas nuevas de Ghostty, asi que hace falta tenerlo"
  echo "  instalado antes de continuar."
  echo ""
  printf '  \033[1mComo instalarlo\033[0m\n'
  echo "    Debian / Ubuntu   descarga el .deb de https://ghostty.org/download"
  echo "                      y luego:  sudo apt install ./ghostty_*.deb"
  echo "    Arch              sudo pacman -S ghostty"
  echo "    Fedora            sudo dnf install ghostty"
  echo "    macOS             brew install --cask ghostty"
  echo ""
  gris "  Cuando lo tengas, vuelve a ejecutar:  ./install.sh"
  echo ""
  exit 1
fi

verde "  Ghostty encontrado: $(command -v ghostty)"

# -------------------------------------------------------------- instalar gcolor
if [[ ! -f "$ORIGEN/gcolor" ]]; then
  rojo "  No encuentro el archivo 'gcolor' junto a este instalador ($ORIGEN)."
  exit 1
fi

echo "  Instalando gcolor en $DESTINO ..."

if [[ -w "$DESTINO" ]]; then
  install -m 755 "$ORIGEN/gcolor" "$DESTINO/gcolor"
else
  sudo install -m 755 "$ORIGEN/gcolor" "$DESTINO/gcolor"
fi

verde "  Listo: $DESTINO/gcolor"

# ------------------------------------------- gris al azar en cada terminal nueva
GRIS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gcolor"
mkdir -p "$GRIS_DIR"
install -m 644 "$ORIGEN/gris_aleatorio.sh" "$GRIS_DIR/gris_aleatorio.sh"
LINEA="[ -f \"$GRIS_DIR/gris_aleatorio.sh\" ] && . \"$GRIS_DIR/gris_aleatorio.sh\""
if ! grep -qF "gcolor/gris_aleatorio.sh" "$HOME/.bashrc" 2>/dev/null; then
  printf '\n# gcolor: cada terminal nueva con un gris al azar\n%s\n' "$LINEA" >>"$HOME/.bashrc"
  verde "  Gris al azar activado en ~/.bashrc"
else
  verde "  Gris al azar actualizado: $GRIS_DIR/gris_aleatorio.sh"
fi

# Ghostty pone de titulo la carpeta en cada prompt; se lo apagamos para que
# gris_aleatorio.sh pueda mostrar la etiqueta de gcolor en la barra de arriba.
GHOSTTY_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config.ghostty"
[[ -f "$GHOSTTY_CONF" ]] || GHOSTTY_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config"
mkdir -p "$(dirname "$GHOSTTY_CONF")"
if ! grep -q '^[[:space:]]*shell-integration-features' "$GHOSTTY_CONF" 2>/dev/null; then
  printf '\n# gcolor: el titulo lo pone gris_aleatorio.sh (etiqueta o carpeta)\nshell-integration-features = no-title\n' >>"$GHOSTTY_CONF"
  verde "  Ghostty: titulo de ventana a cargo de gcolor ($GHOSTTY_CONF)"
elif ! grep -q 'no-title' "$GHOSTTY_CONF"; then
  gris "  Aviso: tu config de Ghostty ya define shell-integration-features;"
  gris "  agregale no-title para que la etiqueta se vea en la barra de arriba."
fi
echo ""
echo "  Pruebalo con:"
echo "    gcolor              -> la lista de colores"
echo "    gcolor red terminal1"
echo ""

if ! command -v gcolor >/dev/null 2>&1; then
  gris "  Aviso: $DESTINO no esta en tu PATH; agregalo para poder llamar a gcolor."
fi
