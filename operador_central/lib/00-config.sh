#!/bin/bash
# Modulo: Configuración general: rutas, colores, lista de servicios candidatos, chequeo de systemd
# Este modulo se carga via source desde operador_central.sh.
# Contenido identico al script original, sin modificar.

# ---------------------------------------------------------------------------
# Configuración general: Ajustar estas rutas si la estructura cambia. ¿OK?
# ---------------------------------------------------------------------------
APP_ROOT="/var/www/clinica_imagen"
APP_DIR="${APP_ROOT}/aplicacion"
BACKUP_ROOT="${APP_ROOT}/backups"
DATOS_ROOT="${APP_ROOT}/datos"
LOG_DIR="${APP_DIR}/logs"
OPERATOR_LOG="${LOG_DIR}/operador_central.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Variantes "crudas" (byte ESC real) para usar dentro de awk/sed, donde
# echo -e no interviene para interpretar el \033.
YELLOW_RAW=$(printf '\033[1;33m')
NC_RAW=$(printf '\033[0m')

# Servicios candidatos a detectar en este servidor (se ajusta solo a los
# que realmente existan). Editar esta lista si cambian las versiones.
SERVICIOS_CANDIDATOS=(apache2 mysql php8.1-fpm php8.2-fpm php8.3-fpm ssh cron ufw fail2ban)

mkdir -p "$LOG_DIR" 2>/dev/null

# Disponibilidad de systemd (necesario para la sección de Servicios)
if command -v systemctl &>/dev/null && [[ -d /run/systemd/system ]]; then
    SYSTEMD_OK=1
else
    SYSTEMD_OK=0
fi
