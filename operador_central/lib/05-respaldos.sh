#!/bin/bash
# Modulo: 4) RESPALDOS — respaldo manual de datos (completo y base de datos)
# Este modulo se carga via source desde operador_central.sh.
# Contenido identico al script original, sin modificar.

# ---------------------------------------------------------------------------
# 4) RESPALDOS
# ---------------------------------------------------------------------------
respaldar_completo() {
    necesita_root || { pausa; return; }
    local marca
    marca=$(date +%Y-%m-%d_%H-%M-%S)
    local destino="${BACKUP_ROOT}/completos/${marca}"
    mkdir -p "$destino"

    declare -A carpetas=(
        [aplicacion]="$APP_DIR"
        [configuracion]="${APP_DIR}/configuracion"
        [estudios]="${DATOS_ROOT}/estudios"
    )

    titulo "RESPALDO COMPLETO"
    echo "Creando respaldo: $marca"
    local ok=1
    for nombre in aplicacion configuracion estudios; do
        local origen="${carpetas[$nombre]}"
        if [[ -d "$origen" ]]; then
            echo -n "  - ${nombre} ... "
            if tar -czf "${destino}/${nombre}.tar.gz" -C "$(dirname "$origen")" "$(basename "$origen")"; then
                echo -e "${GREEN}ok${NC}"
            else
                echo -e "${RED}falló${NC}"
                ok=0
            fi
        else
            echo -e "  - ${nombre} ${YELLOW}omitido (no existe: $origen)${NC}"
        fi
    done

    echo
    if [[ $ok -eq 1 ]]; then
        echo -e "${GREEN}Respaldo completo creado en: $destino${NC}"
        log_accion "Respaldo completo creado: $destino"
    else
        echo -e "${YELLOW}El respaldo se creó con errores. Revisá: $destino${NC}"
        log_accion "Respaldo completo creado con errores: $destino"
    fi
    pausa
}

respaldar_base_datos() {
    necesita_root || { pausa; return; }
    echo "Motor de base de datos:"
    echo "  [1] MySQL"
    read -rp "Opción: " motor
    local destino="${BACKUP_ROOT}/base-datos"
    mkdir -p "$destino"
    local archivo
    local marca
    marca=$(date +%Y-%m-%d_%H-%M-%S)

    case "$motor" in
        1)
            read -rp "Nombre de la base de datos: " bd
            read -rp "Usuario administrador de MySQL [root]: " admin
            admin=${admin:-root}
            read -rsp "Contraseña de $admin: " clave; echo
            archivo="${destino}/${bd}_${marca}.sql.gz"
            if MYSQL_PWD="$clave" mysqldump -u "$admin" "$bd" 2>/dev/null | gzip > "$archivo"; then
                echo -e "${GREEN}Respaldo creado: $archivo${NC}"
                log_accion "Respaldo de base de datos MySQL: $bd"
            else
                echo -e "${RED}Falló el respaldo de la base de datos.${NC}"
                rm -f "$archivo"
            fi
            unset clave
            ;;
    esac
    pausa
}

construir_lista_respaldos() {
    RESPALDOS_RUTAS=()
    RESPALDOS_DESC=()
    local items=()

    if [[ -d "${BACKUP_ROOT}/completos" ]]; then
        while IFS= read -r -d '' dir; do
            items+=("$dir")
        done < <(find "${BACKUP_ROOT}/completos" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
    fi

    if [[ -d "${BACKUP_ROOT}/base-datos" ]]; then
        while IFS= read -r -d '' f; do
            items+=("$f")
        done < <(find "${BACKUP_ROOT}/base-datos" -maxdepth 1 -type f -name "*.sql.gz" -print0 2>/dev/null)
    fi

    if [[ ${#items[@]} -gt 0 ]]; then
        while IFS=' ' read -r _ ruta; do
            RESPALDOS_RUTAS+=("$ruta")
        done < <(for it in "${items[@]}"; do printf '%s %s\n' "$(stat -c %Y "$it" 2>/dev/null)" "$it"; done | sort -n)
    fi

    local ruta mtime fecha_legible tam tipo
    for ruta in "${RESPALDOS_RUTAS[@]}"; do
        mtime=$(stat -c %Y "$ruta" 2>/dev/null)
        fecha_legible=$(date -d "@${mtime}" '+%A %d/%m/%Y  %H:%M' 2>/dev/null)
        tam=$(du -sh "$ruta" 2>/dev/null | cut -f1)
        if [[ -d "$ruta" ]]; then
            tipo="Completo (aplicacion + configuracion + estudios)"
        else
            tipo="Base de datos: $(basename "$ruta")"
        fi
        RESPALDOS_DESC+=("${fecha_legible}   |   ${tam}   |   ${tipo}")
    done
}

listar_respaldos() {
    titulo "RESPALDOS EXISTENTES (de más antiguo a más reciente)"
    construir_lista_respaldos
    if [[ ${#RESPALDOS_RUTAS[@]} -eq 0 ]]; then
        echo "No hay respaldos todavía."
    else
        local i=1
        for desc in "${RESPALDOS_DESC[@]}"; do
            printf "  [%2d] %s\n" "$i" "$desc"
            ((i++))
        done
    fi
    pausa
}

eliminar_respaldo() {
    necesita_root || { pausa; return; }
    titulo "ELIMINAR UN RESPALDO (de más antiguo a más reciente)"
    construir_lista_respaldos
    if [[ ${#RESPALDOS_RUTAS[@]} -eq 0 ]]; then
        echo "No hay respaldos para eliminar."
        pausa
        return
    fi
    local i=1
    for desc in "${RESPALDOS_DESC[@]}"; do
        printf "  [%2d] %s\n" "$i" "$desc"
        ((i++))
    done
    echo "  [0] Cancelar"
    echo
    read -rp "Número del respaldo a eliminar: " num
    if [[ "$num" == "0" || -z "$num" ]]; then
        echo "Cancelado."
        pausa
        return
    fi
    if ! [[ "$num" =~ ^[0-9]+$ ]] || (( num < 1 || num > ${#RESPALDOS_RUTAS[@]} )); then
        echo -e "${RED}Opción inválida.${NC}"
        pausa
        return
    fi
    local ruta="${RESPALDOS_RUTAS[$((num-1))]}"
    echo
    echo -e "${YELLOW}Vas a eliminar:${NC} ${RESPALDOS_DESC[$((num-1))]}"
    if confirmar "¿Confirmás la eliminación definitiva?"; then
        rm -rf "$ruta" && log_accion "Respaldo eliminado: $ruta" && echo -e "${GREEN}Eliminado.${NC}"
    else
        echo "Cancelado."
    fi
    pausa
}

menu_respaldos() {
    while true; do
        titulo "RESPALDOS (BACKUPS)"
        echo "  [1] Respaldo completo (aplicacion + configuracion + estudios)"
        echo "  [2] Respaldar base de datos"
        echo "  [3] Listar respaldos existentes"
        echo "  [4] Eliminar un respaldo"
        echo "  [0] Volver al menú principal"
        echo
        read -rp "Opción: " op
        case "$op" in
            1) respaldar_completo ;;
            2) respaldar_base_datos ;;
            3) listar_respaldos ;;
            4) eliminar_respaldo ;;
            0) return ;;
            *) echo -e "${RED}Opción inválida.${NC}"; pausa ;;
        esac
    done
}
