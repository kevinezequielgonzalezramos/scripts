#!/bin/bash
set -uo pipefail

# ============================================================
# CONFIGURACIÓN
# ============================================================

APP_ROOT="/var/www/clinica_imagen"
APP_DIR="${APP_ROOT}/aplicacion"
BACKUP_ROOT="${APP_ROOT}/backups"
DATOS_ROOT="${APP_ROOT}/datos"
LOG_DIR="${APP_DIR}/logs"
OPERATOR_LOG="${LOG_DIR}/operador_central.log"

# Base de datos
DB_NOMBRE="clinica_imagen"
DB_USUARIO=""

# --- Respaldo de backups en la carpeta compartida ---
REMOTE_ENABLED=true
REMOTE_MOUNT_PATH="/media/backups_clinica"

# ============================================================
# UTILIDADES
# ============================================================

VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
ROJO='\033[0;31m'
NC='\033[0m'

log() {
    local nivel="$1"; shift
    local mensaje="$*"
    local marca
    marca=$(date '+%Y-%m-%d %H:%M:%S')

    case "$nivel" in
        OK)    echo -e "  ${VERDE}✔${NC} ${mensaje}" ;;
        WARN)  echo -e "  ${AMARILLO}⚠${NC} ${mensaje}" ;;
        ERROR) echo -e "  ${ROJO}✘${NC} ${mensaje}" ;;
        *)     echo -e "  → ${mensaje}" ;;
    esac

    echo "[${marca}] [${nivel}] ${mensaje}" >> "$OPERATOR_LOG"
}

mostrar_ayuda() {
    cat <<EOF
Uso: backup [opción]

Opciones:
  full         Respalda solo archivos (aplicación, configuración, estudios)
  db           Respalda solo la base de datos
  remote       Copia a la carpeta compartida de Windows lo ya respaldado localmente
  all          Hace las tres cosas: archivos + base de datos + copia a Windows (por defecto)
  -h, --help   Muestra esta ayuda

Ejemplos:
  backup            Respaldo completo (archivos + BD + copia a Windows)
  backup full       Solo respalda archivos
  backup db         Solo respalda la base de datos
  backup remote     Reenvía a la carpeta compartida lo ya respaldado localmente
EOF
}

verificar_requisitos() {
    local faltantes=()

    for cmd in tar gzip mysqldump; do
        command -v "$cmd" >/dev/null 2>&1 || faltantes+=("$cmd")
    done

    if [[ "$REMOTE_ENABLED" == true ]]; then
        command -v rsync >/dev/null 2>&1 || faltantes+=("rsync")
    fi

    if [[ ${#faltantes[@]} -gt 0 ]]; then
        log ERROR "Faltan comandos necesarios: ${faltantes[*]}. Instalalos con: sudo apt install ${faltantes[*]}"
        exit 1
    fi
}

# ============================================================
# RESPALDO COMPLETO DE ARCHIVOS
# ============================================================

respaldar_completo() {
    local marca
    marca=$(date +%Y-%m-%d_%H-%M-%S)
    local destino="${BACKUP_ROOT}/completos/${marca}"

    mkdir -p "$destino"
    log INFO "Iniciando respaldo de archivos en ${destino}"

    declare -A carpetas=(
        [aplicacion]="$APP_DIR"
        [configuracion]="${APP_DIR}/configuracion"
        [estudios]="${DATOS_ROOT}/estudios"
    )

    local ok=1

    for nombre in aplicacion configuracion estudios; do
        local origen="${carpetas[$nombre]}"

        if [[ -d "$origen" ]]; then
            if tar -czf \
                "${destino}/${nombre}.tar.gz" \
                -C "$(dirname "$origen")" \
                "$(basename "$origen")"; then
                log OK "${nombre}: comprimido correctamente"
            else
                log ERROR "${nombre}: falló la compresión"
                ok=0
            fi
        else
            log WARN "${nombre}: la carpeta ${origen} no existe, se omite"
            ok=0
        fi
    done

    if [[ $ok -eq 1 ]]; then
        local tam
        tam=$(du -sh "$destino" 2>/dev/null | cut -f1)
        log OK "Respaldo completo creado: ${destino} (${tam})"
    else
        log WARN "El respaldo completo se creó con errores: ${destino}"
    fi
}

# ============================================================
# RESPALDO DE BASE DE DATOS
# ============================================================

respaldar_base_datos() {
    local destino="${BACKUP_ROOT}/base-datos"
    mkdir -p "$destino"

    local marca
    marca=$(date +%Y-%m-%d_%H-%M-%S)

    local bd="$1"
    local admin="${DB_USUARIO:-}"

    if [[ -z "$bd" ]]; then
        log ERROR "No se especificó la base de datos"
        exit 1
    fi

    local archivo="${destino}/${bd}_${marca}.sql.gz"
    log INFO "Respaldando base de datos '${bd}'"

    local cmd=(mysqldump)
    [[ -n "$admin" ]] && cmd+=(-u "$admin")
    cmd+=("$bd")

    if "${cmd[@]}" | gzip > "$archivo"; then
        local tam
        tam=$(du -sh "$archivo" 2>/dev/null | cut -f1)
        log OK "Respaldo de base de datos creado: ${archivo} (${tam})"
    else
        log ERROR "Error al crear el respaldo de la base de datos"
        rm -f "$archivo"
        exit 1
    fi
}

# ============================================================
# RESPALDO REMOTO (carpeta compartida de VirtualBox)
# ============================================================

respaldar_remoto() {
    if [[ "$REMOTE_ENABLED" != true ]]; then
        log WARN "El respaldo hacia Windows está desactivado (REMOTE_ENABLED=false)"
        return 0
    fi

    if [[ ! -d "$REMOTE_MOUNT_PATH" ]]; then
        log ERROR "No se encontró la carpeta compartida en ${REMOTE_MOUNT_PATH}. Revisá que esté montada"
        return 1
    fi

    log INFO "Copiando backups a ${REMOTE_MOUNT_PATH} (carpeta compartida de Windows)"

    if rsync -a "${BACKUP_ROOT}/" "${REMOTE_MOUNT_PATH}/"; then
        log OK "Backups copiados correctamente a la carpeta de Windows"
    else
        log ERROR "Falló la copia a la carpeta compartida"
        return 1
    fi
}

# ============================================================
# EJECUCIÓN
# ============================================================

if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ejecutarse como root."
    exit 1
fi

mkdir -p "$BACKUP_ROOT/completos" "$BACKUP_ROOT/base-datos" "$LOG_DIR"

verificar_requisitos

ACCION="${1:-all}"

case "$ACCION" in
    -h|--help)
        mostrar_ayuda
        exit 0
        ;;
    full)
        respaldar_completo
        ;;
    db)
        respaldar_base_datos "$DB_NOMBRE"
        ;;
    remote)
        respaldar_remoto
        ;;
    all)
        respaldar_completo
        respaldar_base_datos "$DB_NOMBRE"
        respaldar_remoto
        ;;
    *)
        echo "Opción no reconocida: ${ACCION}"
        mostrar_ayuda
        exit 1
        ;;
esac

log OK "Proceso de backup finalizado (modo: ${ACCION})"
