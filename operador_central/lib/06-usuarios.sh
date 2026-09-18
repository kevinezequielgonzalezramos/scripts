#!/bin/bash
# Modulo: 5) USUARIOS — ABML de usuarios del sistema
# Este modulo se carga via source desde operador_central.sh.
# Contenido identico al script original, sin modificar.

# ---------------------------------------------------------------------------
# 5) USUARIOS
# ---------------------------------------------------------------------------
auditar_usuario() {
    read -rp "Usuario a auditar: " u
    if ! id "$u" &>/dev/null; then
        echo -e "${RED}El usuario '$u' no existe.${NC}"
        pausa
        return
    fi
    titulo "AUDITORÍA: $u"
    echo "Identidad:"; id "$u"
    echo
    echo "Grupos y privilegios sudo:"
    sudo -l -U "$u" 2>/dev/null || echo "  (requiere root para consultar sudo -l)"
    echo
    echo "Último acceso:"; lastlog -u "$u" 2>/dev/null
    echo
    echo "Procesos actuales del usuario:"
    ps -u "$u" -o pid,etime,cmd 2>/dev/null || echo "  (sin procesos activos)"
    echo
    echo "Tareas programadas (crontab):"
    crontab -u "$u" -l 2>/dev/null || echo "  (sin tareas programadas o sin permiso para verlas)"
    pausa
}

crear_usuario() {
    necesita_root || { pausa; return; }
    read -rp "Nombre del nuevo usuario: " u
    if id "$u" &>/dev/null; then
        echo -e "${RED}El usuario '$u' ya existe.${NC}"
        pausa
        return
    fi
    read -rp "¿Otorgar privilegios sudo? [s/N]: " sudo_resp
    adduser --gecos "" "$u"
    if [[ "$sudo_resp" =~ ^[sS]$ ]]; then
        usermod -aG sudo "$u"
    fi
    log_accion "Usuario creado: $u (sudo: ${sudo_resp:-N})"
    echo -e "${GREEN}Usuario '$u' creado.${NC}"
    pausa
}

eliminar_usuario() {
    necesita_root || { pausa; return; }
    read -rp "Usuario a eliminar: " u
    if ! id "$u" &>/dev/null; then
        echo -e "${RED}El usuario '$u' no existe.${NC}"
        pausa
        return
    fi
    echo -e "${YELLOW}Procesos activos de $u:${NC}"
    ps -u "$u" -o pid,cmd 2>/dev/null
    if confirmar "¿Eliminar el usuario '$u' y su carpeta personal? Esta acción no se puede deshacer"; then
        userdel -r "$u" && log_accion "Usuario eliminado: $u" && echo -e "${GREEN}Usuario eliminado.${NC}"
    else
        echo "Cancelado."
    fi
    pausa
}

menu_usuarios() {
    while true; do
        titulo "GESTIÓN DE USUARIOS"
        echo "  [1] Listar usuarios con acceso a shell"
        echo "  [2] Auditar un usuario (sudo, procesos, últimos accesos)"
        echo "  [3] Crear usuario nuevo"
        echo "  [4] Bloquear usuario"
        echo "  [5] Desbloquear usuario"
        echo "  [6] Eliminar usuario"
        echo "  [7] Cambiar contraseña de un usuario"
        echo "  [8] Agregar usuario a un grupo (ej: sudo)"
        echo "  [9] Ver usuarios conectados ahora"
        echo "  [10] Ver últimos accesos (last)"
        echo "  [0] Volver al menú principal"
        echo
        read -rp "Opción: " op
        case "$op" in
            1) titulo "Usuarios con acceso a shell"; awk -F: '$7 ~ /(bash|sh)$/ {print $1" (UID:"$3")"}' /etc/passwd; pausa ;;
            2) auditar_usuario ;;
            3) crear_usuario ;;
            4)
                if necesita_root; then
                    read -rp "Usuario a bloquear: " u
                    confirmar "¿Bloquear el acceso de '$u'?" && usermod -L "$u" && log_accion "Usuario bloqueado: $u"
                fi
                pausa
                ;;
            5)
                if necesita_root; then
                    read -rp "Usuario a desbloquear: " u
                    usermod -U "$u" && log_accion "Usuario desbloqueado: $u"
                fi
                pausa
                ;;
            6) eliminar_usuario ;;
            7)
                if necesita_root; then
                    read -rp "Usuario: " u
                    passwd "$u" && log_accion "Contraseña modificada: $u"
                fi
                pausa
                ;;
            8)
                if necesita_root; then
                    read -rp "Usuario: " u
                    read -rp "Grupo (ej: sudo): " g
                    confirmar "¿Agregar '$u' al grupo '$g'?" && usermod -aG "$g" "$u" && log_accion "Usuario $u agregado al grupo $g"
                fi
                pausa
                ;;
            9) titulo "Usuarios conectados"; w; pausa ;;
            10) titulo "Últimos accesos"; last -n 20; pausa ;;
            0) return ;;
            *) echo -e "${RED}Opción inválida.${NC}"; pausa ;;
        esac
    done
}
