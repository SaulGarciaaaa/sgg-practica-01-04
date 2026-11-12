#!/bin/bash

set -e

# Comprobar que Apache esta instalado
if ! dpkg -s apache2 &> /dev/null; then
    echo "Apache no esta instalado."
    echo "Ejecuta primero install_apache.sh."
    exit 1
fi

# Obtener la ruta del repositorio
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Comprobar que existe el archivo .env
ENV_FILE="$SCRIPT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "No existe el archivo scripts/.env."
    echo "Crea el archivo a partir de .env.example."
    exit 1
fi

# Cargar las variables del archivo .env
source "$ENV_FILE"

# Comprobar variables obligatorias
if [ -z "$COUNTRY" ] || [ -z "$STATE" ] || \
   [ -z "$LOCALITY" ] || [ -z "$ORGANIZATION" ] || \
   [ -z "$ORGANIZATIONAL_UNIT" ] || [ -z "$COMMON_NAME" ] || \
   [ -z "$EMAIL" ] || [ -z "$DOMAIN" ] || \
   [ -z "$ELASTIC_IP" ] || [ -z "$DAYS" ] || \
   [ -z "$CERT_KEY" ] || [ -z "$CERT_FILE" ] || \
   [ -z "$HTTP_CONF" ] || [ -z "$HTTPS_CONF" ]; then

    echo "Error: faltan variables obligatorias en .env."
    exit 1
fi

# Comprobar que la IP elastica no es un valor de ejemplo
if [ "$ELASTIC_IP" = "TU_IP_ELASTICA" ]; then
    echo "Error: debes configurar tu IP elastica en .env."
    exit 1
fi

# Comprobar que los archivos de configuracion existen
if [ ! -f "$PROJECT_DIR/conf/$HTTP_CONF" ] || \
   [ ! -f "$PROJECT_DIR/conf/$HTTPS_CONF" ]; then

    echo "Error: no se encuentran las plantillas de Apache."
    exit 1
fi

# Crear los directorios necesarios
mkdir -p "$(dirname "$CERT_KEY")"
mkdir -p "$(dirname "$CERT_FILE")"

# Generar certificado autofirmado
echo "Generando certificado autofirmado..."

openssl req -x509 -nodes -days "$DAYS" \
-newkey rsa:2048 \
-keyout "$CERT_KEY" \
-out "$CERT_FILE" \
-subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT/CN=$COMMON_NAME/emailAddress=$EMAIL" \
-addext "subjectAltName=DNS:$DOMAIN,IP:$ELASTIC_IP"

# Proteger la clave privada
chmod 600 "$CERT_KEY"
chmod 644 "$CERT_FILE"

# Copiar las plantillas de Apache
echo "Configurando virtual hosts..."

cp "$PROJECT_DIR/conf/$HTTP_CONF" /etc/apache2/sites-available/
cp "$PROJECT_DIR/conf/$HTTPS_CONF" /etc/apache2/sites-available/

# Sustituir el dominio
sed -i "s|__DOMAIN__|$DOMAIN|g" \
"/etc/apache2/sites-available/$HTTP_CONF"

sed -i "s|__DOMAIN__|$DOMAIN|g" \
"/etc/apache2/sites-available/$HTTPS_CONF"

# Sustituir la ruta del certificado
sed -i "s|__CERT_FILE__|$CERT_FILE|g" \
"/etc/apache2/sites-available/$HTTPS_CONF"

# Sustituir la ruta de la clave privada
sed -i "s|__KEY_FILE__|$CERT_KEY|g" \
"/etc/apache2/sites-available/$HTTPS_CONF"
# Habilitar los modulos necesarios
echo "Habilitando modulos SSL y Rewrite..."
sudo a2enmod ssl rewrite

# Habilitar el sitio HTTPS
echo "Habilitando sitio HTTPS..."
sudo a2ensite "$HTTPS_CONF"

# Comprobar la configuracion antes de reiniciar
echo "Comprobando configuracion de Apache..."

sudo apache2ctl configtest

# Reiniciar Apache
echo "Reiniciando Apache..."
sudo systemctl restart apache2

echo "Certificado y configuracion HTTPS instalados correctamente."
