#!/bin/bash
# Modulo: Utilidades comunes: log_accion, pausa, confirmar, titulo, necesita_root, servicio_existe
# Este modulo se carga via source desde operador_central.sh.
# Contenido identico al script original, sin modificar.

# ---------------------------------------------------------------------------
# Utilidades comunes
# ---------------------------------------------------------------------------
log_accion() {
    local mensaje="$1"
    local usuario
    usuario=$(logname 2>/dev/null || whoami)
    echo "$(date '+%Y-%m-%d %H:%M:%S') | usuario:${usuario} | ${mensaje}" >> "$OPERATOR_LOG" 2>/dev/null
}

pausa() {
    echo
    read -rp "Presione ENTER para continuar..." _
}

confirmar() {
    local pregunta="$1"
    local resp
    read -rp "$(echo -e "${YELLOW}${pregunta} [s/N]: ${NC}")" resp
    [[ "$resp" =~ ^[sS]$ ]]
}

titulo() {
    clear
    echo -e "${CYAN}${BOLD}=============================================================${NC}"
    echo -e "${CYAN}${BOLD} $1${NC}"
    echo -e "${CYAN}${BOLD}=============================================================${NC}"
    echo
}

necesita_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Esta acción requiere privilegios de root. Ejecute el script con sudo.${NC}"
        return 1
    fi
    return 0
}

servicio_existe() {
    systemctl list-unit-files --type=service --no-legend 2>/dev/null | awk '{print $1}' | grep -qx "${1}.service"
}
