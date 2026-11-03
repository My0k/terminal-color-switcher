# gris_aleatorio.sh - se carga desde ~/.bashrc (lo agrega install.sh) y hace dos
#                     cosas en cada terminal:
#
# 1. La pinta con un tono de gris al azar, desde casi negro hasta un gris oscuro
#    parecido al fondo por defecto (secuencias OSC 10/11/12: texto, fondo,
#    cursor; vale para Ghostty, GNOME Terminal y otras).
#    No pinta cuando:
#      - la shell no es interactiva o no hay terminal (scripts, Claude Code);
#      - la ventana la abrio gcolor con un color (exporta GCOLOR);
#      - es una bash anidada dentro de la misma terminal (ya se pinto esa tty);
#      - corre dentro de tmux/screen;
#      - GCOLOR_GRIS=0 (para apagarlo sin tocar el ~/.bashrc).
#    Rango: ajustable con GCOLOR_GRIS_MIN / GCOLOR_GRIS_MAX (0-255).
#
# 2. Pone el titulo de la ventana en cada prompt: la etiqueta que le haya dado
#    "gcolor -a/-t <color> <etiqueta>", o la carpeta actual si no tiene.
#    Para que Ghostty no lo pise, install.sh pone en su config
#    "shell-integration-features = no-title".

_gcolor_inicio() {
  [[ $- == *i* ]] || return 0
  [[ -t 1 ]] || return 0
  [[ -n "${TMUX:-}${STY:-}" ]] && return 0

  local tty
  tty=$(tty 2>/dev/null) || return 0
  _GCOLOR_TITULO_ARCHIVO="${XDG_RUNTIME_DIR:-/tmp/gcolor-$UID}/gcolor/titulo-${tty//\//_}"

  # Titulo en cada prompt (tambien en bash anidadas)
  _gcolor_titulo() {
    local t
    if [[ -r "$_GCOLOR_TITULO_ARCHIVO" ]]; then t=$(<"$_GCOLOR_TITULO_ARCHIVO")
    else t=${PWD/#$HOME/\~}; fi
    printf '\033]2;%s\033\\' "$t"
  }
  [[ "${PROMPT_COMMAND:-}" == *_gcolor_titulo* ]] ||
    PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;}_gcolor_titulo"

  # Lo que sigue solo en la primera shell de cada terminal
  [[ "${_GCOLOR_GRIS_TTY:-}" == "$tty" ]] && return 0
  export _GCOLOR_GRIS_TTY="$tty"
  # la tty puede ser reciclada de una ventana ya cerrada: su etiqueta no vale
  rm -f "$_GCOLOR_TITULO_ARCHIVO"

  [[ "${GCOLOR_GRIS:-1}" == 0 ]] && return 0
  [[ -n "${GCOLOR:-}" ]] && return 0

  local min=${GCOLOR_GRIS_MIN:-8} max=${GCOLOR_GRIS_MAX:-64}
  local v=$(( min + RANDOM % (max - min + 1) ))
  local bg fg
  printf -v bg '#%02x%02x%02x' "$v" "$v" "$v"
  # texto oscuro sobre gris claro, texto claro sobre gris oscuro
  if (( v >= 128 )); then fg='#161616'; else fg='#ececec'; fi

  printf '\033]11;%s\033\\\033]10;%s\033\\\033]12;%s\033\\' "$bg" "$fg" "$fg"
  export GCOLOR_GRIS_ACTUAL="$bg"
}
_gcolor_inicio
unset -f _gcolor_inicio
