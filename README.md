<div align="center">
    
# Práctica 1.4 — HTTPS con certificado autofirmado en Apache

<img width="597" height="261" alt="imagen" src="https://github.com/user-attachments/assets/07bf2bce-c4fc-4f11-8a4a-b966ba15118a" />

</div>

# Indice



## 1. Objetivo

El objetivo de esta práctica es desplegar un servidor web Apache en una instancia EC2 de AWS y configurar HTTPS mediante un certificado autofirmado. Todo el proceso se  
realiza mediante scripts Bash para automatizar la instalación y configuración, además, de subir los archivos mediante git a el repositorio.

## 2. Creación de la instancia EC2

Se crea una instancia EC2 utilizando Ubuntu Server  y el tipo de instancia indicado en la actividad.

<img width="1088" height="36" alt="imagen" src="https://github.com/user-attachments/assets/86dfb3bc-244f-44e0-89cf-4df5198ff0b1" />


Se configura un Security Group con las siguientes reglas de entrada:

| Servicio | Protocolo | Puerto | Uso |
|---|---|---|---|
| SSH | TCP | 22 | Utilizado para administrar Apache y ejecutar comandos, ejecutar comandos de git mediante protocolo SSH. |
| HTTP | TCP | 80 | Utilizado para poder utilizar Apache y redirige el tráfico automáticamente hacia HTTPS. |
| HTTPS | TCP | 443 | Utilizado para emplear el certificado SSL/TLS y sincronizar el repositorio de git usando URL seguras. |

En Seguridad-> Grupos de Seguridad: 

<img width="1618" height="212" alt="imagen" src="https://github.com/user-attachments/assets/19e49c33-153a-45c9-875d-fbe0b730a2fc" />

Utilizo el puerto

También se crea una IP elástica y se asocia a la instancia.

<img width="173" height="43" alt="imagen" src="https://github.com/user-attachments/assets/50c2f908-392a-4c0c-87e7-a77a65089add" />

Esta es la ip elástica generada para esta práctica y que emplearé para la misma

La asocio a la instancia

<img width="610" height="325" alt="imagen" src="https://github.com/user-attachments/assets/3b5c8ed7-e4cf-4239-98a9-8258bdcf3093" />



## 3. Clonación del repositorio

Se clona el repositorio de GitHub en la instancia EC2:

```bash
git clone https://github.com/SaulGarciaaaa/sgg-practica-01-04.git
cd sgg-practica-01-04
```

<img width="592" height="109" alt="imagen" src="https://github.com/user-attachments/assets/d495f7b0-6c27-463c-8615-bb625f7f93e0" />


## 4. Estructura del proyecto

El repositorio contiene los siguientes archivos:

```text
.
├── README.md
├── .gitignore
├── conf
│   ├── 000-default.conf
│   └── practica-https-ssl.conf
└── scripts
    ├── .env.example
    ├── install_apache.sh
    └── setup_selfsigned_certificate.sh
```

Estructura actual de mi repositorio:

<img width="945" height="353" alt="imagen" src="https://github.com/user-attachments/assets/9a13a5db-6df5-4657-b986-cd2fabe84c22" />


## 5. Script install_apache.sh

Este script automatiza la instalación de Apache.

```bash

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

```

Sus funciones son:

- Comprobar mediante `dpkg -s apache2` si Apache ya está instalado.
- Si ya está instalado, mostrar un mensaje y terminar.
- Si no está instalado, actualizar los paquetes e instalar Apache sin intervención del usuario.
- Habilitar el servicio y dejarlo en funcionamiento.

Ejecución:

```bash
sudo ./scripts/install_apache.sh
```


#### 1. Validación y evidencia de la instación de apache

<img width="963" height="556" alt="imagen" src="https://github.com/user-attachments/assets/e5bf5cda-7a56-4ab2-ba1a-48b051a3a4ee" />
<img width="977" height="529" alt="imagen" src="https://github.com/user-attachments/assets/3087217c-7a02-4f4d-bdfd-c37b42eba7d2" />

Apache instalado correctamente sin ningun problema habiendo ejecutado el programa donde incluye la instalacion y los mensajes implementados en el script

#### 2. Comprobación de Apache

<img width="646" height="327" alt="imagen" src="https://github.com/user-attachments/assets/2f1931f3-6fd5-46ec-ac5b-a3818d3e6ee2" />

Apache se encuentra activo y en estado(running)

#### 3. Validación y evidencia del Script estando instalado apache

<img width="635" height="34" alt="imagen" src="https://github.com/user-attachments/assets/f58d4d1f-4669-4884-aac9-b45b49b709ed" />

Como se puede ver en la imagen la ejecución del script es correcta y muestra el mensaje de salida por defecto porque
en este ya se ha validado que esta instalado Apache.


## 6. Script setup_selfsigned_certificate.sh

Este script automatiza la configuración HTTPS.

```bash

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

``

Sus funciones son:

- Comprobar que Apache está instalado.
- Leer las variables de configuración del archivo `.env`.
- Crear una clave privada y un certificado autofirmado mediante OpenSSL.
- Incluir el dominio y la IP elástica en la extensión `subjectAltName`.
- Copiar las plantillas de configuración a Apache y sustituir el dominio.
- Habilitar los módulos SSL y Rewrite.
- Habilitar el sitio HTTPS.
- Comprobar la configuración mediante `apache2ctl configtest`.
- Reiniciar Apache si la configuración es correcta.

Ejecución:

```bash
sudo ./scripts/setup_selfsigned_certificate.sh
```

<img width="979" height="494" alt="imagen" src="https://github.com/user-attachments/assets/638ac8f8-66ce-424d-b8b7-61554889b102" />

#### 1. Validación de expiración del dertificado SAN 
<img width="981" height="71" alt="imagen" src="https://github.com/user-attachments/assets/d16ea708-de3e-4f2d-88f6-d254c54c88ed" />
En la imagen se peude ver la fecha de inicio de creación y fin de este

#### 2. Validación de sintaxis de apache
<img width="618" height="37" alt="imagen" src="https://github.com/user-attachments/assets/c876aa3f-502d-4a52-998d-3a14c5308043" />
Todos los scripts estan bien estructurados y demas archivos estan bien y funcionan correctamente

## 7. Configuración del certificado

Se utiliza un certificado autofirmado para el dominio `practica-https.test`.

La clave privada se almacena en `/etc/ssl/private/` y el certificado en `/etc/ssl/certs/`.

El archivo `.env` contiene los datos de configuración y no se sube al repositorio.



## 8. Virtual hosts

Se utilizan dos archivos de configuración:

- `000-default.conf`: configura el acceso HTTP por el puerto 80 y redirige las peticiones a HTTPS.
- `practica-https-ssl.conf`: configura el acceso HTTPS por el puerto 443 y utiliza el certificado autofirmado.

## 9. Verificaciones

Añadir aquí las salidas reales o capturas de las siguientes comprobaciones:

1. Instalación de Apache y estado del servicio.
2. Segunda ejecución del script de instalación.
3. Datos del sujeto, fechas y SAN del certificado.
4. Sintaxis de Apache (`Syntax OK`).
5. Puertos 80 y 443 a la escucha.
6. Redirección HTTP a HTTPS.
7. Respuesta HTTPS.
8. Negociación TLS.
9. Acceso mediante Firefox y detalles del certificado.

## 10. Seguridad

El archivo `.env` real y las claves privadas no se suben a GitHub.

El archivo `.gitignore` evita incluir estos archivos en el repositorio. Se proporciona `.env.example` como plantilla de configuración.

## 11. Sujeto , validez y SAN del certificado

<img width="988" height="70" alt="imagen" src="https://github.com/user-attachments/assets/dd5b0569-3ca3-4b4a-ac7c-53bc3181a3fd" />




## 12. Puertos de escucha

<img width="989" height="88" alt="imagen" src="https://github.com/user-attachments/assets/e9449dc3-edba-4100-8aec-6aefb1a0652c" />

## 13. Redirección HTTP → HTTPS

<img width="489" height="105" alt="imagen" src="https://github.com/user-attachments/assets/5728f790-f3d9-41c6-9de4-917b8f3d73eb" />

## 14. Respuesta HTTPS

<img width="537" height="185" alt="imagen" src="https://github.com/user-attachments/assets/5adc7c0d-938e-4140-8029-c543a832aa01" />

## 15. Negociación TLS

<img width="643" height="574" alt="imagen" src="https://github.com/user-attachments/assets/746f57bc-f497-4036-a814-b764ee1b4e80" />
<img width="480" height="376" alt="imagen" src="https://github.com/user-attachments/assets/002fe179-1ae6-4c32-9abf-083613ebe196" />

## 16. Uso en el navegador
<img width="1363" height="574" alt="imagen" src="https://github.com/user-attachments/assets/1ef0929b-9ebb-4369-9cf1-5bfcf65aa97c" />

Le doy al candado-> Y mas información:
Datos->
<img width="741" height="551" alt="imagen" src="https://github.com/user-attachments/assets/32935003-d73e-43d5-af71-d142f34f4b72" />

Y veo el certificado->

<img width="246" height="424" alt="imagen" src="https://github.com/user-attachments/assets/7ea97a66-dfec-4485-9b34-6d479a2c9f1f" />


## 17. Finalización

Una vez realizadas las comprobaciones, se detiene la instancia EC2 y se libera la IP elástica si no se va a seguir utilizando.
