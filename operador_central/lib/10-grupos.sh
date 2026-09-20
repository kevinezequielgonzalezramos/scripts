#!/bin/bash
# Modulo: 8) GRUPOS — ABML de grupos del sistema
# Este modulo se carga via source desde operador_central.sh.
# Modulo NUEVO agregado a pedido del usuario (no existía en el script
# original). Sigue las mismas convenciones que el resto de los módulos:
# necesita_root, confirmar, log_accion, titulo, pausa y los colores
# definidos en 00-config.sh.

# ---------------------------------------------------------------------------
# 8) GRUPOS
# ---------------------------------------------------------------------------
listar_grupos() {
    titulo "GRUPOS DEL SISTEMA"
    printf "%-25s %-8s %s\n" "GRUPO" "GID" "MIEMBROS"
    printf "%-25s %-8s %s\n" "-------------------------" "--------" "---------------------------"
    while IFS=: read -r nombre _ gid miembros; do
        printf "%-25s %-8s %s\n" "$nombre" "$gid" "$miembros"
    done < <(getent group | sort -t: -k3 -n)
    pausa
}

ver_miembros_grupo() {
    read -rp "Grupo a consultar: " g
    if ! getent group "$g" &>/dev/null; then
        echo -e "${RED}El grupo '$g' no existe.${NC}"
        pausa
        return
    fi
    titulo "MIEMBROS DEL GRUPO: $g"
    local linea gid miembros
    linea=$(getent group "$g")
    gid=$(echo "$linea" | cut -d: -f3)
    miembros=$(echo "$linea" | cut -d: -f4)

    echo "GID: $gid"
    echo
    echo "Miembros secundarios (según /etc/group):"
    if [[ -n "$miembros" ]]; then
        echo "$miembros" | tr ',' '\n' | sed 's/^/  - /'
    else
        echo "  (ninguno)"
    fi
    echo
    echo "Usuarios que tienen a '$g' como grupo primario:"
    local primarios
    primarios=$(awk -F: -v gid="$gid" '$4 == gid {print "  - "$1}' /etc/passwd)
    if [[ -n "$primarios" ]]; then
        echo "$primarios"
    else
        echo "  (ninguno)"
    fi
    pausa
}

crear_grupo() {
    necesita_root || { pausa; return; }
    read -rp "Nombre del nuevo grupo: " g
    if getent group "$g" &>/dev/null; then
        echo -e "${RED}El grupo '$g' ya existe.${NC}"
        pausa
        return
    fi
    groupadd "$g" && log_accion "Grupo creado: $g" && echo -e "${GREEN}Grupo '$g' creado.${NC}"
    pausa
}

renombrar_grupo() {
    necesita_root || { pausa; return; }
    read -rp "Grupo a renombrar: " g
    if ! getent group "$g" &>/dev/null; then
        echo -e "${RED}El grupo '$g' no existe.${NC}"
        pausa
        return
    fi
    read -rp "Nuevo nombre para '$g': " nuevo
    if [[ -z "$nuevo" ]]; then
        echo "Cancelado."
        pausa
        return
    fi
    if getent group "$nuevo" &>/dev/null; then
        echo -e "${RED}Ya existe un grupo llamado '$nuevo'.${NC}"
        pausa
        return
    fi
    if confirmar "¿Renombrar el grupo '$g' a '$nuevo'?"; then
        groupmod -n "$nuevo" "$g" && log_accion "Grupo renombrado: $g -> $nuevo" && echo -e "${GREEN}Grupo renombrado a '$nuevo'.${NC}"
    else
        echo "Cancelado."
    fi
    pausa
}

agregar_usuario_a_grupo() {
    necesita_root || { pausa; return; }
    read -rp "Grupo: " g
    if ! getent group "$g" &>/dev/null; then
        echo -e "${RED}El grupo '$g' no existe.${NC}"
        pausa
        return
    fi
    read -rp "Usuario a agregar: " u
    if ! id "$u" &>/dev/null; then
        echo -e "${RED}El usuario '$u' no existe.${NC}"
        pausa
        return
    fi
    confirmar "¿Agregar '$u' al grupo '$g'?" && usermod -aG "$g" "$u" && log_accion "Usuario $u agregado al grupo $g"
    pausa
}

quitar_usuario_de_grupo() {
    necesita_root || { pausa; return; }
    read -rp "Grupo: " g
    if ! getent group "$g" &>/dev/null; then
        echo -e "${RED}El grupo '$g' no existe.${NC}"
        pausa
        return
    fi
    read -rp "Usuario a quitar del grupo: " u
    if ! id "$u" &>/dev/null; then
        echo -e "${RED}El usuario '$u' no existe.${NC}"
        pausa
        return
    fi
    if confirmar "¿Quitar a '$u' del grupo '$g'?"; then
        gpasswd -d "$u" "$g" &>/dev/null && log_accion "Usuario $u quitado del grupo $g" && echo -e "${GREEN}Listo.${NC}" || echo -e "${RED}No se pudo quitar (¿'$u' no pertenecía a '$g'?).${NC}"
    else
        echo "Cancelado."
    fi
    pausa
}

eliminar_grupo() {
    necesita_root || { pausa; return; }
    read -rp "Grupo a eliminar: " g
    if ! getent group "$g" &>/dev/null; then
        echo -e "${RED}El grupo '$g' no existe.${NC}"
        pausa
        return
    fi
    local gid primarios
    gid=$(getent group "$g" | cut -d: -f3)
    primarios=$(awk -F: -v gid="$gid" '$4 == gid {print "  - "$1}' /etc/passwd)
    if [[ -n "$primarios" ]]; then
        echo -e "${YELLOW}Atención: este grupo es el grupo primario de los siguientes usuarios:${NC}"
        echo "$primarios"
        echo -e "${YELLOW}No se podrá eliminar hasta que dejen de tenerlo como grupo primario.${NC}"
    fi
    if confirmar "¿Eliminar el grupo '$g'? Esta acción no se puede deshacer"; then
        groupdel "$g" && log_accion "Grupo eliminado: $g" && echo -e "${GREEN}Grupo eliminado.${NC}"
    else
        echo "Cancelado."
    fi
    pausa
}

menu_grupos() {
    while true; do
        titulo "GESTIÓN DE GRUPOS"
        echo "  [1] Listar grupos del sistema"
        echo "  [2] Ver miembros de un grupo"
        echo "  [3] Crear grupo nuevo"
        echo "  [4] Renombrar un grupo"
        echo "  [5] Agregar un usuario a un grupo"
        echo "  [6] Quitar un usuario de un grupo"
        echo "  [7] Eliminar grupo"
        echo "  [0] Volver al menú principal"
        echo
        read -rp "Opción: " op
        case "$op" in
            1) listar_grupos ;;
            2) ver_miembros_grupo ;;
            3) crear_grupo ;;
            4) renombrar_grupo ;;
            5) agregar_usuario_a_grupo ;;
            6) quitar_usuario_de_grupo ;;
            7) eliminar_grupo ;;
            0) return ;;
            *) echo -e "${RED}Opción inválida.${NC}"; pausa ;;
        esac
    done
}
