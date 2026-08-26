#!/bin/bash

# Crear perfiles de colores para GNOME Terminal, manteniendo el perfil por defecto
#
# OJO: esto solo hace falta si usas GNOME Terminal. Con Ghostty los colores
# viajan como argumentos en el propio script "gcolor" y no hay nada que crear.
#
# Los nombres de perfil son los mismos que entiende gcolor.

# Detectar el ID del perfil predeterminado
DEFAULT_PROFILE_ID=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")

# Función para eliminar un perfil si existe (excepto el predeterminado)
delete_profile() {
    local profile_name="$1"
    local profile_id=""

    for id in $(gsettings get org.gnome.Terminal.ProfilesList list | tr -d "[],'"); do
        if [[ "$id" == "$DEFAULT_PROFILE_ID" ]]; then
            continue
        fi
        local name=$(gsettings get org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$id/ visible-name | tr -d "'")
        if [[ "$name" == "$profile_name" ]]; then
            profile_id="$id"
            break
        fi
    done

    if [[ -n "$profile_id" ]]; then
        echo "Eliminando perfil '$profile_name' ($profile_id)..."
        local current_list=$(gsettings get org.gnome.Terminal.ProfilesList list)
        local new_list=$(echo $current_list | sed "s/'$profile_id', //g" | sed "s/, '$profile_id'//g" | sed "s/'$profile_id'//g")
        gsettings set org.gnome.Terminal.ProfilesList list "$new_list"
    fi
}

# Función para crear un perfil
create_profile() {
    local profile_name="$1"
    local background_color="$2"
    local foreground_color="$3"

    local uuid=$(uuidgen)
    local list=$(gsettings get org.gnome.Terminal.ProfilesList list | sed "s/]$/, '$uuid']/")
    gsettings set org.gnome.Terminal.ProfilesList list "$list"

    local path="/org/gnome/terminal/legacy/profiles:/:$uuid/"
    gsettings set org.gnome.Terminal.Legacy.Profile:${path} visible-name "$profile_name"
    gsettings set org.gnome.Terminal.Legacy.Profile:${path} use-theme-colors false
    gsettings set org.gnome.Terminal.Legacy.Profile:${path} background-color "$background_color"
    gsettings set org.gnome.Terminal.Legacy.Profile:${path} foreground-color "$foreground_color"
}

echo "Limpiando perfiles antiguos..."

# nombre fondo texto  -- el mismo catalogo que lleva gcolor
COLORES=(
  "red    #3B1E1E #F8E9A1"
  "orange #3D2415 #F7E0CC"
  "yellow #3A3312 #F5F0C0"
  "green  #2D3E2F #DCE4C5"
  "teal   #12302E #CFEDE7"
  "blue   #1B263B #E0E1DD"
  "indigo #1E1B3D #DCD9F5"
  "purple #2A1B3D #E7DAF7"
  "pink   #3B1B2C #F7D9E7"
  "gray   #22262B #D6DBE0"
)

# Los nombres viejos, por si quedaron de una version anterior
for viejo in Rojo Azul Verde Morado Cian Ambar; do
    delete_profile "$viejo"
done

for c in "${COLORES[@]}"; do
    read -r nombre bg fg <<<"$c"
    delete_profile "$nombre"
done

echo "Creando los perfiles..."

for c in "${COLORES[@]}"; do
    read -r nombre bg fg <<<"$c"
    create_profile "$nombre" "$bg" "$fg"
    echo "  $nombre  $bg / $fg"
done

echo "Perfiles creados exitosamente, perfil predeterminado mantenido intacto."
