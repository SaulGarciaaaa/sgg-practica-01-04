# Comprobar si Apache ya esta instalado
if dpkg -s apache2 >/dev/null 2>&1; then
    echo "Apache ya está instalado."
    exit 0
fi

# Actualizar los paquetes
apt-get update

# Instalar Apache
DEBIAN_FRONTEND=noninteractive apt-get install -y apache2

# Habilitar y arrancar Apache
systemctl enable --now apache2

echo "Apache instalado correctamente."
