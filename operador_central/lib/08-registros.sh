#!/bin/bash
# Modulo: 7) REGISTROS (LOGS)
# Este modulo se carga via source desde operador_central.sh.
# Contenido identico al script original, sin modificar.

# ---------------------------------------------------------------------------
# 7) REGISTROS (LOGS)
# ---------------------------------------------------------------------------
menu_registros() {
    while true; do
        titulo "REGISTROS (LOGS)"
        echo "  [1] Ver logs de la aplicación (${LOG_DIR})"
        echo "  [2] Ver log del sistema (syslog)"
        echo "  [3] Ver log de autenticación (auth.log)"
        echo "  [4] Ver logs de Apache"
        echo "  [5] Buscar texto en un archivo de log"
        echo "  [6] Ver historial de acciones de este panel"
        echo "  [7] Seguir un log en tiempo real (tail -f)"
        echo "  [0] Volver al menú principal"
        echo
        read -rp "Opción: " op
        case "$op" in
            1)
                titulo "Logs de la aplicación"
                ls -lh "$LOG_DIR" 2>/dev/null
                read -rp "Nombre de archivo a ver (vacío para cancelar): " f
                [[ -n "$f" && -f "${LOG_DIR}/${f}" ]] && less "${LOG_DIR}/${f}"
                ;;
            2) sudo tail -n 200 /var/log/syslog 2>/dev/null | less ;;
            3) sudo tail -n 200 /var/log/auth.log 2>/dev/null | less ;;
            4)
                titulo "Logs de Apache"
                for f in /var/log/apache2/access.log /var/log/apache2/error.log /var/log/apache2/clinica_imagen_access.log /var/log/apache2/clinica_imagen_error.log; do
                    [[ -f "$f" ]] && echo "  $f"
                done
                read -rp "Ruta completa del archivo a ver: " ruta
                [[ -f "$ruta" ]] && sudo tail -n 200 "$ruta" | less
                ;;
            5)
                read -rp "Archivo de log (ruta completa): " ruta
                read -rp "Texto a buscar: " texto
                [[ -f "$ruta" ]] && grep -i --color=always "$texto" "$ruta" | less -R
                ;;
            6) titulo "Historial de acciones de operador_central"; tail -n 100 "$OPERATOR_LOG" 2>/dev/null | less ;;
            7)
                read -rp "Ruta completa del archivo a seguir: " ruta
                if [[ -f "$ruta" ]]; then
                    echo "Presione Ctrl+C para salir."
                    tail -f "$ruta"
                fi
                ;;
            0) return ;;
            *) echo -e "${RED}Opción inválida.${NC}"; pausa ;;
        esac
    done
}
