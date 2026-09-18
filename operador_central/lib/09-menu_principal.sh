#!/bin/bash
# Modulo: MENU PRINCIPAL
# Este modulo se carga via source desde operador_central.sh.
# Contenido identico al script original, sin modificar.

# ---------------------------------------------------------------------------
# MENÚ PRINCIPAL
# ---------------------------------------------------------------------------
menu_principal() {
    while true; do
        titulo "OPERADOR CENTRAL — CLINICA IMAGEN"
        echo "  Servidor: $(hostname)    Fecha: $(date '+%Y-%m-%d %H:%M')"
        if [[ $EUID -ne 0 ]]; then
            echo -e "  ${YELLOW}Modo lectura: ejecute con sudo para habilitar todas las acciones.${NC}"
        fi
        echo
        echo "  [1] Servicios"
        echo "  [2] Red"
        echo "  [3] Procesos"
        echo "  [4] Respaldos"
        echo "  [5] Usuarios"
        echo "  [6] Orígenes de datos"
        echo "  [7] Registros (logs)"
        echo "  [8] Grupos"
        echo "  [0] Salir"
        echo
        read -rp "Seleccione una opción: " op
        case "$op" in
            1) menu_servicios ;;
            2) menu_red ;;
            3) menu_procesos ;;
            4) menu_respaldos ;;
            5) menu_usuarios ;;
            6) menu_origenes_datos ;;
            7) menu_registros ;;
            8) menu_grupos ;;
            0) echo "Saliendo..."; log_accion "Sesión finalizada"; exit 0 ;;
            *) echo -e "${RED}Opción inválida.${NC}"; pausa ;;
        esac
    done
}
