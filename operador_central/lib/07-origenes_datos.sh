#!/bin/bash
# Modulo: 6) ORIGENES DE DATOS — bases de datos MySQL
# Este modulo se carga via source desde operador_central.sh.

# ---------------------------------------------------------------------------
# 6) ORÍGENES DE DATOS
# ---------------------------------------------------------------------------


_pedir_admin_mysql() {
    read -rp "Usuario administrador MySQL [root]: " admin; admin=${admin:-root}
    read -rsp "Contraseña de $admin: " clave; echo
}

_confirmar() {
    read -rp "$1 [s/N]: " _resp
    [[ "$_resp" =~ ^[sS]$ ]]
}

# --- Listado --------------------------------------------------------------
listar_bases_datos_mysql() {
    necesita_root || { pausa; return; }
    _pedir_admin_mysql
    MYSQL_PWD="$clave" mysql -u "$admin" -e "SHOW DATABASES;"
    unset clave
    pausa
}

listar_usuarios_mysql() {
    necesita_root || { pausa; return; }
    _pedir_admin_mysql
    MYSQL_PWD="$clave" mysql -u "$admin" -e "SELECT User, Host FROM mysql.user ORDER BY User;"
    unset clave
    pausa
}

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

modificar_usuario_mysql() {
    necesita_root || { pausa; return; }
    _pedir_admin_mysql
    read -rp "Usuario a modificar: " usuario
    read -rp "Host asociado [localhost]: " host_usuario; host_usuario=${host_usuario:-localhost}

    echo "  [1] Cambiar contraseña"
    echo "  [2] Otorgar privilegios sobre una base de datos"
    echo "  [3] Revocar privilegios sobre una base de datos"
    read -rp "Opción: " sub_op

    case "$sub_op" in
        1)
            read -rsp "Nueva contraseña: " nueva_clave; echo
            if MYSQL_PWD="$clave" mysql -u "$admin" -e "ALTER USER '${usuario}'@'${host_usuario}' IDENTIFIED BY '${nueva_clave}'; FLUSH PRIVILEGES;"; then
                echo -e "${GREEN}Contraseña actualizada para '$usuario'@'$host_usuario'.${NC}"
                log_accion "Contraseña modificada: $usuario@$host_usuario"
            else
                echo -e "${RED}Ocurrió un error al cambiar la contraseña.${NC}"
            fi
            unset nueva_clave
            ;;
        2)
            read -rp "Base de datos: " bd
            if MYSQL_PWD="$clave" mysql -u "$admin" -e "GRANT ALL PRIVILEGES ON \`${bd}\`.* TO '${usuario}'@'${host_usuario}'; FLUSH PRIVILEGES;"; then
                echo -e "${GREEN}Privilegios otorgados sobre '$bd' a '$usuario'@'$host_usuario'.${NC}"
                log_accion "Privilegios otorgados: $usuario@$host_usuario sobre $bd"
            else
                echo -e "${RED}Ocurrió un error al otorgar privilegios.${NC}"
            fi
            ;;
        3)
            read -rp "Base de datos: " bd
            if MYSQL_PWD="$clave" mysql -u "$admin" -e "REVOKE ALL PRIVILEGES ON \`${bd}\`.* FROM '${usuario}'@'${host_usuario}'; FLUSH PRIVILEGES;"; then
                echo -e "${GREEN}Privilegios revocados sobre '$bd' para '$usuario'@'$host_usuario'.${NC}"
                log_accion "Privilegios revocados: $usuario@$host_usuario sobre $bd"
            else
                echo -e "${RED}Ocurrió un error al revocar privilegios.${NC}"
            fi
            ;;
        *)
            echo -e "${RED}Opción inválida.${NC}"
            ;;
    esac
    unset clave
    pausa
}

# --- Eliminación ------------------------------------------------------------
eliminar_base_datos() {
    necesita_root || { pausa; return; }
    _pedir_admin_mysql
    read -rp "Base de datos a eliminar: " bd

    if ! _confirmar "¿Confirma que desea eliminar la base de datos '$bd'? Esta acción no se puede deshacer"; then
        echo "Operación cancelada."
        unset clave
        pausa
        return
    fi

    if MYSQL_PWD="$clave" mysql -u "$admin" -e "DROP DATABASE \`${bd}\`;"; then
        echo -e "${GREEN}Base de datos '$bd' eliminada.${NC}"
        log_accion "Base de datos eliminada: $bd"
    else
        echo -e "${RED}Ocurrió un error al eliminar la base de datos.${NC}"
    fi
    unset clave
    pausa
}

eliminar_usuario_mysql() {
    necesita_root || { pausa; return; }
    _pedir_admin_mysql
    read -rp "Usuario a eliminar: " usuario
    read -rp "Host asociado [localhost]: " host_usuario; host_usuario=${host_usuario:-localhost}

    if ! _confirmar "¿Confirma que desea eliminar el usuario '$usuario'@'$host_usuario'?"; then
        echo "Operación cancelada."
        unset clave
        pausa
        return
    fi

    if MYSQL_PWD="$clave" mysql -u "$admin" -e "DROP USER IF EXISTS '${usuario}'@'${host_usuario}';"; then
        echo -e "${GREEN}Usuario '$usuario'@'$host_usuario' eliminado.${NC}"
        log_accion "Usuario MySQL eliminado: $usuario@$host_usuario"
    else
        echo -e "${RED}Ocurrió un error al eliminar el usuario.${NC}"
    fi
    unset clave
    pausa
}

eliminar_origen_completo() {
    # Elimina una base de datos y, opcionalmente, cada usuario que tenía
    # privilegios sobre ella.
    necesita_root || { pausa; return; }
    _pedir_admin_mysql
    read -rp "Base de datos a eliminar: " bd

    echo "Usuarios con privilegios sobre '$bd':"
    MYSQL_PWD="$clave" mysql -u "$admin" -e \
        "SELECT DISTINCT User, Host FROM mysql.db WHERE Db='${bd}';"

    if ! _confirmar "¿Confirma que desea eliminar la base de datos '$bd'?"; then
        echo "Operación cancelada."
        unset clave
        pausa
        return
    fi

    mapfile -t usuarios_asociados < <(MYSQL_PWD="$clave" mysql -u "$admin" -N -e \
        "SELECT CONCAT(User,'@',Host) FROM mysql.db WHERE Db='${bd}';")

    if MYSQL_PWD="$clave" mysql -u "$admin" -e "DROP DATABASE \`${bd}\`;"; then
        echo -e "${GREEN}Base de datos '$bd' eliminada.${NC}"
        log_accion "Base de datos eliminada (con revisión de usuarios): $bd"
    else
        echo -e "${RED}Ocurrió un error al eliminar la base de datos.${NC}"
        unset clave
        pausa
        return
    fi

    for cuenta in "${usuarios_asociados[@]}"; do
        [ -z "$cuenta" ] && continue
        usuario="${cuenta%@*}"
        host_usuario="${cuenta#*@}"
        if _confirmar "¿Eliminar también el usuario '$usuario'@'$host_usuario'?"; then
            if MYSQL_PWD="$clave" mysql -u "$admin" -e "DROP USER IF EXISTS '${usuario}'@'${host_usuario}';"; then
                echo -e "${GREEN}Usuario '$usuario'@'$host_usuario' eliminado.${NC}"
                log_accion "Usuario MySQL eliminado: $usuario@$host_usuario"
            else
                echo -e "${RED}No se pudo eliminar el usuario '$usuario'@'$host_usuario'.${NC}"
            fi
        fi
    done

    unset clave
    pausa
}

# --- Menú --------------------------------------------------------------
menu_origenes_datos() {
    while true; do
        titulo "ORÍGENES DE DATOS"
        echo "  [1] Listar bases de datos"
        echo "  [2] Listar usuarios MySQL"
        echo "  [3] Crear base de datos y usuario"
        echo "  [4] Modificar usuario (contraseña / privilegios)"
        echo "  [5] Eliminar base de datos"
        echo "  [6] Eliminar usuario"
        echo "  [7] Eliminar base de datos y sus usuarios asociados"
        echo "  [0] Volver al menú principal"
        echo
        read -rp "Opción: " op
        case "$op" in
            1) listar_bases_datos_mysql ;;
            2) listar_usuarios_mysql ;;
            3) crear_origen_mysql ;;
            4) modificar_usuario_mysql ;;
            5) eliminar_base_datos ;;
            6) eliminar_usuario_mysql ;;
            7) eliminar_origen_completo ;;
            0) return ;;
            *) echo -e "${RED}Opción inválida.${NC}"; pausa ;;
        esac
    done
}
