#!/bin/bash
# Modulo: 2) RED — interfaces, puertos, conexiones y Firewall (ufw)
# Este modulo se carga via source desde operador_central.sh.
# Contenido identico al script original, sin modificar.

# ---------------------------------------------------------------------------
# 2) RED (con Firewall)
# ---------------------------------------------------------------------------
menu_firewall() {
    while true; do
        titulo "FIREWALL (UFW)"
        if ! command -v ufw &>/dev/null; then
            echo -e "${RED}ufw no está instalado en este servidor.${NC}"
            pausa
            return
        fi
        local estado_ufw
        estado_ufw=$(ufw status | head -n 1)
        echo -e "Estado actual: ${BOLD}${estado_ufw}${NC}"
        echo
        echo "  [1] Ver estado y reglas detalladas"
        echo "  [2] Activar firewall"
        echo "  [3] Desactivar firewall"
        echo "  [4] Abrir un puerto"
        echo "  [5] Cerrar un puerto (eliminar una regla)"
        echo "  [6] Restablecer a valores de fábrica"
        echo "  [0] Volver al menú de Red"
        echo
        read -rp "Opción: " op
        case "$op" in
            1) titulo "Reglas de ufw"; ufw status numbered verbose; pausa ;;
            2)
                if necesita_root; then
                    if ! ufw status | grep -qiE "22/tcp|OpenSSH"; then
                        echo -e "${YELLOW}Atención: no se detectó una regla que permita SSH (puerto 22).${NC}"
                        echo -e "${YELLOW}Si activás el firewall sin permitirlo, podrías perder el acceso remoto.${NC}"
                        if confirmar "¿Agregar automáticamente una regla para permitir SSH antes de activar?"; then
                            ufw allow OpenSSH 2>/dev/null || ufw allow 22/tcp
                        fi
                    fi
                    confirmar "¿Activar ufw ahora?" && ufw --force enable && log_accion "Firewall (ufw) activado"
                fi
                pausa
                ;;
            3)
                if necesita_root; then
                    confirmar "¿Desactivar ufw? El servidor quedará sin firewall" && ufw disable && log_accion "Firewall (ufw) desactivado"
                fi
                pausa
                ;;
            4)
                if necesita_root; then
                    read -rp "Puerto a abrir (ej: 443/tcp): " puerto
                    confirmar "¿Abrir el puerto $puerto?" && ufw allow "$puerto" && log_accion "Puerto abierto en ufw: $puerto"
                fi
                pausa
                ;;
            5)
                if necesita_root; then
                    titulo "Reglas actuales"
                    ufw status numbered
                    echo
                    read -rp "Número de regla a eliminar (según la lista de arriba): " num
                    if [[ "$num" =~ ^[0-9]+$ ]] && confirmar "¿Eliminar la regla número $num?"; then
                        ufw --force delete "$num" && log_accion "Regla de ufw eliminada: #$num"
                    fi
                fi
                pausa
                ;;
            6)
                if necesita_root; then
                    confirmar "¿Restablecer ufw a valores de fábrica? Se perderán todas las reglas actuales" && ufw --force reset && log_accion "Firewall (ufw) restablecido a valores de fábrica"
                fi
                pausa
                ;;
            0) return ;;
            *) echo -e "${RED}Opción inválida.${NC}"; pausa ;;
        esac
    done
}

menu_red() {
    while true; do
        titulo "GESTIÓN DE RED"
        echo "  [1] Ver interfaces y direcciones IP"
        echo "  [2] Ver puertos en escucha"
        echo "  [3] Ver conexiones activas"
        echo "  [4] Probar conectividad (ping)"
        echo "  [5] Firewall (ufw)"
        echo "  [0] Volver al menú principal"
        echo
        read -rp "Opción: " op
        case "$op" in
            1) titulo "Interfaces de red"; ip -brief addr show; pausa ;;
            2)
                titulo "Puertos en escucha"
                (ss -tulpn 2>/dev/null || netstat -tulpn 2>/dev/null) | awk -v c="$YELLOW_RAW" -v n="$NC_RAW" '{ gsub(/:[0-9]+/, c "&" n); print }'
                pausa
                ;;
            3)
                titulo "Conexiones activas (ESC o Q para salir, flechas para desplazarse)"
                (ss -tunap 2>/dev/null || netstat -tunap 2>/dev/null) | less -R
                ;;
            4)
                read -rp "Host o IP a probar: " host
                [[ -n "$host" ]] && ping -c 4 "$host"
                pausa
                ;;
            5) menu_firewall ;;
            0) return ;;
            *) echo -e "${RED}Opción inválida.${NC}"; pausa ;;
        esac
    done
}
