#!/bin/bash
# Modulo: 1) SERVICIOS — gestión de servicios systemd
# Este modulo se carga via source desde operador_central.sh.
# Contenido identico al script original, sin modificar.

# ---------------------------------------------------------------------------
# 1) SERVICIOS
# ---------------------------------------------------------------------------
menu_servicios() {
    while true; do
        titulo "GESTIÓN DE SERVICIOS"
        local detectados=()
        local no_instalados=()

        # 1) Detectar cuáles candidatos existen (sin tocar servicio_existe)
        for s in "${SERVICIOS_CANDIDATOS[@]}"; do
            if servicio_existe "$s"; then
                detectados+=("$s")
            else
                no_instalados+=("$s")
            fi
        done

        # 2) UNA sola llamada a systemctl para el estado de todos los detectados
        local estados=()
        if ((${#detectados[@]} > 0)); then
            mapfile -t estados < <(systemctl is-active "${detectados[@]}" 2>/dev/null)
        fi

        # 3) Mostrar el menú usando los estados ya obtenidos
        for idx in "${!detectados[@]}"; do
            local estado="${estados[$idx]:-desconocido}"
            if [[ "$estado" == "active" ]]; then
                echo -e "  [$((idx+1))] ${detectados[$idx]} ${GREEN}(activo)${NC}"
            else
                echo -e "  [$((idx+1))] ${detectados[$idx]} ${RED}(${estado})${NC}"
            fi
        done

        echo
        echo "  [T] Ver todos los servicios del sistema"
        echo "  [0] Volver al menú principal"
        echo
        read -rp "Seleccione un servicio a administrar (o T/0): " opcion

        case "$opcion" in
            0)
                return
                ;;
            [Tt])
                systemctl list-units --type=service --all | less
                continue
                ;;
            *)
                if ! [[ "$opcion" =~ ^[0-9]+$ ]] || (( opcion < 1 || opcion > ${#detectados[@]} )); then
                    echo -e "${RED}Opción inválida.${NC}"
                    pausa
                    continue
                fi
                submenu_accion_servicio "${detectados[$((opcion-1))]}"
                ;;
        esac
    done
}

submenu_accion_servicio() {
    local servicio="$1"
    while true; do
        titulo "SERVICIO: $servicio"
        systemctl status "$servicio" --no-pager -l 2>/dev/null | head -n 8
        echo
        echo "  [1] Iniciar"
        echo "  [2] Detener"
        echo "  [3] Reiniciar"
        echo "  [4] Habilitar en arranque"
        echo "  [5] Deshabilitar en arranque"
        echo "  [6] Ver estado detallado"
        echo "  [0] Volver"
        echo
        read -rp "Opción: " op
        case "$op" in
            1) necesita_root && systemctl start "$servicio" && log_accion "Inicio de servicio: $servicio"; pausa ;;
            2) necesita_root && confirmar "¿Detener $servicio?" && systemctl stop "$servicio" && log_accion "Detención de servicio: $servicio"; pausa ;;
            3) necesita_root && confirmar "¿Reiniciar $servicio?" && systemctl restart "$servicio" && log_accion "Reinicio de servicio: $servicio"; pausa ;;
            4) necesita_root && systemctl enable "$servicio" && log_accion "Habilitado en arranque: $servicio"; pausa ;;
            5) necesita_root && systemctl disable "$servicio" && log_accion "Deshabilitado en arranque: $servicio"; pausa ;;
            6) systemctl status "$servicio" --no-pager -l | less ;;
            0) return ;;
            *) echo -e "${RED}Opción inválida.${NC}"; pausa ;;
        esac
    done
}
