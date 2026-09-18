#!/bin/bash
# Modulo: 6) ORIGENES DE DATOS — bases de datos MySQL
# Este modulo se carga via source desde operador_central.sh.
# Contenido identico al script original, sin modificar.

# ---------------------------------------------------------------------------
# 6) ORÍGENES DE DATOS
# ---------------------------------------------------------------------------
crear_origen_mysql() {
    necesita_root || { pausa; return; }
    read -rp "Usuario administrador MySQL [root]: " admin; admin=${admin:-root}
    read -rsp "Contraseña de $admin: " clave; echo
    read -rp "Nombre de la nueva base de datos: " bd
    read -rp "Nombre del nuevo usuario de aplicación: " nuevo_usuario
    read -rsp "Contraseña para $nuevo_usuario: " nueva_clave; echo
    read -rp "Host permitido para conectarse [localhost]: " host_permitido
    host_permitido=${host_permitido:-localhost}

    if MYSQL_PWD="$clave" mysql -u "$admin" <<SQL
CREATE DATABASE IF NOT EXISTS \`${bd}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${nuevo_usuario}'@'${host_permitido}' IDENTIFIED BY '${nueva_clave}';
GRANT ALL PRIVILEGES ON \`${bd}\`.* TO '${nuevo_usuario}'@'${host_permitido}';
FLUSH PRIVILEGES;
SQL
    then
        echo -e "${GREEN}Base de datos '$bd' y usuario '$nuevo_usuario' creados.${NC}"
        log_accion "Origen de datos MySQL creado: BD=$bd usuario=$nuevo_usuario"
    else
        echo -e "${RED}Ocurrió un error al crear el origen de datos.${NC}"
    fi
    unset clave nueva_clave
    pausa
}

menu_origenes_datos() {
    while true; do
        titulo "ORÍGENES DE DATOS"
        echo "  [1] Listar bases de datos (MySQL)"
        echo "  [2] Crear base de datos y usuario (MySQL)"
        echo "  [0] Volver al menú principal"
        echo
        read -rp "Opción: " op
        case "$op" in
            1)
                read -rp "Usuario administrador MySQL [root]: " admin; admin=${admin:-root}
                read -rsp "Contraseña: " clave; echo
                MYSQL_PWD="$clave" mysql -u "$admin" -e "SHOW DATABASES;"
                unset clave
                pausa
                ;;
            2) crear_origen_mysql ;;
            0) return ;;
            *) echo -e "${RED}Opción inválida.${NC}"; pausa ;;
        esac
    done
}
