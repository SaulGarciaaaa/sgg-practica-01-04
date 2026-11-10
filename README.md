# Práctica 1.4 — HTTPS con certificado autofirmado en Apache

## 1. Objetivo

El objetivo de esta práctica es desplegar un servidor web Apache en una instancia EC2 de AWS y configurar HTTPS mediante un certificado autofirmado. Todo el proceso se realiza mediante scripts Bash para automatizar la instalación y configuración.

## 2. Creación de la instancia EC2

Se crea una instancia EC2 utilizando Ubuntu Server LTS y el tipo de instancia indicado en la actividad.

Se configura un Security Group con las siguientes reglas de entrada:

| Servicio | Protocolo | Puerto |
|---|---|---|
| SSH | TCP | 22 |
| HTTP | TCP | 80 |
| HTTPS | TCP | 443 |

También se crea una IP elástica y se asocia a la instancia.

## 3. Clonación del repositorio

Se clona el repositorio de GitHub en la instancia EC2:

```bash
git clone https://github.com/SaulGarciaaaa/sgg-practica-01-04.git
cd sgg-practica-01-04
```

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

## 5. Script install_apache.sh

Este script automatiza la instalación de Apache.

Sus funciones son:

- Comprobar mediante `dpkg -s apache2` si Apache ya está instalado.
- Si ya está instalado, mostrar un mensaje y terminar.
- Si no está instalado, actualizar los paquetes e instalar Apache sin intervención del usuario.
- Habilitar el servicio y dejarlo en funcionamiento.

Ejecución:

```bash
sudo ./scripts/install_apache.sh
```

## 6. Script setup_selfsigned_certificate.sh

Este script automatiza la configuración HTTPS.

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

## 11. Finalización

Una vez realizadas las comprobaciones, se detiene la instancia EC2 y se libera la IP elástica si no se va a seguir utilizando.
