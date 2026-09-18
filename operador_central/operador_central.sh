#!/bin/bash
# -----------------------------------------------------------------------
# Panel de administración para el servidor Ubuntu Server que aloja la
# aplicación web "Clinica Imagen".
#
# Versión 2: Por Kevin González
#
# -----------------------------------------------------------------------
#
# Este archivo es el punto de entrada. Su única función es cargar (source)
# cada módulo de lib/ y luego arrancar el panel. Ninguna función ni lógica
# fue modificada respecto del script original: sólo se separó en archivos
# por sección, en el mismo orden en que aparecían.
#
# Estructura:
#   operador_central.sh          <- este archivo (punto de entrada)
#   lib/00-config.sh             <- rutas, colores, lista de servicios
#   lib/01-utilidades.sh         <- log_accion, pausa, confirmar, titulo, necesita_root, servicio_existe
#   lib/02-servicios.sh          <- 1) Servicios (systemd)
#   lib/03-red.sh                <- 2) Red y Firewall (ufw)
#   lib/04-procesos.sh           <- 3) Procesos
#   lib/05-respaldos.sh          <- 4) Respaldos
#   lib/06-usuarios.sh           <- 5) Usuarios
#   lib/07-origenes_datos.sh     <- 6) Orígenes de datos (MySQL)
#   lib/08-registros.sh          <- 7) Registros (logs)
#   lib/09-menu_principal.sh     <- Menú principal
#
# -----------------------------------------------------------------------

set -uo pipefail

# Directorio donde vive este script (para poder ejecutarlo desde cualquier
# lado y que igual encuentre la carpeta lib/), resolviendo symlinks.
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
while [[ -h "$SCRIPT_SOURCE" ]]; do
    SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_SOURCE")" >/dev/null 2>&1 && pwd)"
    SCRIPT_SOURCE="$(readlink "$SCRIPT_SOURCE")"
    [[ "$SCRIPT_SOURCE" != /* ]] && SCRIPT_SOURCE="${SCRIPT_DIR}/${SCRIPT_SOURCE}"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_SOURCE")" >/dev/null 2>&1 && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

if [[ ! -d "$LIB_DIR" ]]; then
    echo "Error: no se encontró la carpeta de módulos (${LIB_DIR})." >&2
    exit 1
fi

# Cargar todos los módulos en orden (el prefijo numérico de cada archivo
# fija el orden; 00-config.sh siempre primero porque el resto depende de
# sus variables).
for modulo in "${LIB_DIR}"/*.sh; do
    # shellcheck source=/dev/null
    source "$modulo"
done

# ---------------------------------------------------------------------------
# Punto de entrada ejecutando la función
# ---------------------------------------------------------------------------
log_accion "Sesión iniciada"
menu_principal
