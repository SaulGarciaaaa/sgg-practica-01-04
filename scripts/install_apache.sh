#!/bin/bash
set -e

# Comprobar si Apache ya esta instalado
if dpkg -s apache2 &> /dev/null; then
    echo "Apache ya está instalado."
    exit 0
fi

# Actualizar los repositorios
echo "Actualizando paquetes..."
apt-get update

# Instalar Apache sin intervencion del usuario
echo "Instalando Apache..."
DEBIAN_FRONTEND=noninteractive apt-get install -y apache2

# Habilitar e iniciar el servicio
echo "Habilitando e iniciando Apache..."
systemctl enable --now apache2

echo "Apache instalado y arrancado correctamente."

