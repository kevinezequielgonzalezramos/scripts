#!/bin/bash
# Modulo: 3) PROCESOS — administración de procesos
# Este modulo se carga via source desde operador_central.sh.
# Contenido identico al script original, sin modificar.

# ---------------------------------------------------------------------------
# 3) PROCESOS
# ---------------------------------------------------------------------------
menu_procesos() {
    while true; do
        titulo "GESTIÓN DE PROCESOS"
        echo "  [1] Procesos que más CPU consumen"
        echo "  [2] Procesos que más memoria consumen"
        echo "  [3] Finalizar un proceso por PID"
        echo "  [4] Uso de memoria y disco"
        echo "  [0] Volver al menú principal"
        echo
        read -rp "Opción: " op
        case "$op" in
            1) titulo "Top CPU"; ps aux --sort=-%cpu | head -n 15; pausa ;;
            2) titulo "Top memoria"; ps aux --sort=-%mem | head -n 15; pausa ;;
            3)
                if necesita_root; then
                    read -rp "PID a finalizar: " pid
                    if [[ "$pid" =~ ^[0-9]+$ ]] && confirmar "¿Finalizar el proceso PID $pid?"; then
                        kill -15 "$pid" && log_accion "Proceso finalizado (PID $pid)" || echo -e "${RED}No se pudo finalizar el proceso.${NC}"
                    fi
                fi
                pausa
                ;;
            4) titulo "Memoria y disco"; free -h; echo; df -h; pausa ;;
            0) return ;;
            *) echo -e "${RED}Opción inválida.${NC}"; pausa ;;
        esac
    done
}
