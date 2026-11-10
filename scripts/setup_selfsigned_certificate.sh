#!/bin/bash

# Comprobar si Apache esta instalado
if ! dpkg -s apache2 >/dev/null 2>&1; then
    echo "Error: debes ejecutar antes install_apache.sh"
    exit 1
fi

# Comprobar que se ejecuta como administrador
if [ "$EUID" -ne 0 ]; then
    echo "Ejecuta el script con sudo."
    exit 1
fi

# Obtener la ruta del script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Comprobar que existe el archivo .env
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo "Error: no existe scripts/.env"
    exit 1
fi

# Cargar las variables
source "$SCRIPT_DIR/.env"

# Crear directorios necesarios
mkdir -p "$(dirname "$CERT_FILE")"
mkdir -p "$(dirname "$KEY_FILE")"

# Generar certificado autofirmado
openssl req -x509 -nodes -days "$DAYS" -newkey rsa:2048 \
-keyout "$KEY_FILE" \
-out "$CERT_FILE" \
-subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT/CN=$COMMON_NAME/emailAddress=$EMAIL" \
-addext "subjectAltName=DNS:$DOMAIN,IP:$ELASTIC_IP"

if [ $? -ne 0 ]; then
    echo "Error al generar el certificado."
    exit 1
fi

# Proteger la clave privada
chmod 600 "$KEY_FILE"

# Copiar plantilla HTTPS sustituyendo las variables
sed -e "s|__DOMAIN__|$DOMAIN|g" \
    -e "s|__CERT_FILE__|$CERT_FILE|g" \
    -e "s|__KEY_FILE__|$KEY_FILE|g" \
    "$SCRIPT_DIR/../conf/practica-https-ssl.conf" \
    > "$HTTPS_CONF"

# Copiar plantilla HTTP sustituyendo el dominio
sed "s|__DOMAIN__|$DOMAIN|g" \
    "$SCRIPT_DIR/../conf/000-default.conf" \
    > "$HTTP_CONF"

# Habilitar los modulos necesarios
a2enmod ssl rewrite

# Habilitar el sitio HTTPS
a2ensite practica-https-ssl.conf

# Comprobar la configuracion
apache2ctl configtest

if [ $? -ne 0 ]; then
    echo "Error: configuracion de Apache incorrecta."
    exit 1
fi

# Reiniciar Apache
systemctl restart apache2

echo "Configuracion HTTPS completada correctamente."
