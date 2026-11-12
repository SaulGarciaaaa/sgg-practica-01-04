
<div align="center">

# Práctica 1.4 — HTTPS con certificado autofirmado en Apache

<img width="597" height="261" alt="Imagen principal de la práctica" src="https://github.com/user-attachments/assets/07bf2bce-c4fc-4f11-8a4a-b966ba15118a" />

*Práctica de instalación de Apache y configuración de HTTPS mediante un certificado autofirmado en AWS.*

</div>

# Índice

- [1. Objetivo](#1-objetivo)
- [2. Creación de la instancia EC2](#2-creación-de-la-instancia-ec2)
- [3. Clonación del repositorio](#3-clonación-del-repositorio)
- [4. Estructura del proyecto](#4-estructura-del-proyecto)
- [5. Script install_apache.sh](#5-script-install_apachesh)
  - [5.1. Instalación de Apache](#51-instalación-de-apache)
  - [5.2. Comprobación de Apache](#52-comprobación-de-apache)
  - [5.3. Segunda ejecución del script](#53-segunda-ejecución-del-script)
- [6. Script setup_selfsigned_certificate.sh](#6-script-setup_selfsigned_certificatesh)
  - [6.1. Validación de la fecha del certificado](#61-validación-de-la-fecha-del-certificado)
  - [6.2. Validación de la sintaxis de Apache](#62-validación-de-la-sintaxis-de-apache)
  - [6.3. Variables del archivo .env.example](#63-variables-del-archivo-envexample)
- [7. Configuración del certificado](#7-configuración-del-certificado)
- [8. Virtual hosts](#8-virtual-hosts)
- [9. Verificaciones](#9-verificaciones)
- [10. Seguridad](#10-seguridad)
- [11. Sujeto, validez y SAN del certificado](#11-sujeto-validez-y-san-del-certificado)
- [12. Puertos de escucha](#12-puertos-de-escucha)
- [13. Redirección HTTP a HTTPS](#13-redirección-http-a-https)
- [14. Respuesta HTTPS](#14-respuesta-https)
- [15. Negociación TLS](#15-negociación-tls)
- [16. Uso en el navegador](#16-uso-en-el-navegador)
- [17. Finalización](#17-finalización)

---

# 1. Objetivo

El objetivo de esta práctica es desplegar un servidor web Apache en una instancia EC2 de AWS y configurar el acceso seguro mediante HTTPS utilizando un certificado autofirmado.

Para realizarlo se utilizan scripts Bash que automatizan la instalación de Apache y la configuración del certificado SSL/TLS. También se configuran los puertos necesarios, los Virtual Hosts y la redirección del tráfico HTTP hacia HTTPS.

Por último, se realizan diferentes comprobaciones desde la terminal y el navegador para verificar que la configuración funciona correctamente.

# 2. Creación de la instancia EC2

En primer lugar, se crea una instancia EC2 en AWS utilizando Ubuntu Server y el tipo de instancia indicado en la actividad.

<img width="1088" height="36" alt="Configuración de la instancia EC2" src="https://github.com/user-attachments/assets/86dfb3bc-244f-44e0-89cf-4df5198ff0b1" />

*Se muestra la configuración de la instancia EC2 que se utilizará para instalar Apache y realizar la práctica.*

Se configura un Security Group con las siguientes reglas de entrada:

| Servicio | Protocolo | Puerto | Uso |
|---|---|---:|---|
| SSH | TCP | 22 | Permite conectarse a la instancia y administrarla mediante terminal. |
| HTTP | TCP | 80 | Permite recibir peticiones HTTP, que posteriormente se redirigen a HTTPS. |
| HTTPS | TCP | 443 | Permite acceder al servidor mediante una conexión segura SSL/TLS. |

En el apartado de seguridad de AWS, dentro de los grupos de seguridad, se comprueba la configuración de las reglas de entrada.

<img width="1618" height="212" alt="Reglas del Security Group" src="https://github.com/user-attachments/assets/19e49c33-153a-45c9-875d-fbe0b730a2fc" />

*En esta captura se pueden observar las reglas del grupo de seguridad y los puertos habilitados para permitir el acceso SSH, HTTP y HTTPS.*

También se crea una IP elástica para que la instancia tenga una dirección IPv4 pública fija.

<img width="173" height="43" alt="IP elástica" src="https://github.com/user-attachments/assets/50c2f908-392a-4c0c-87e7-a77a65089add" />

*Esta es la dirección IP elástica asignada para utilizarla durante la práctica.*

A continuación, se asocia la IP elástica a la instancia EC2.

<img width="610" height="325" alt="Asociación de IP elástica" src="https://github.com/user-attachments/assets/3b5c8ed7-e4cf-4239-98a9-8258bdcf3093" />

*Se muestra la asociación de la dirección IP elástica con la instancia EC2 para mantener una dirección pública fija.*

# 3. Clonación del repositorio

Una vez creada la instancia, se accede a ella mediante SSH y se clona el repositorio de GitHub para disponer de los scripts y archivos de configuración.

```bash
git clone https://github.com/SaulGarciaaaa/sgg-practica-01-04.git
cd sgg-practica-01-04
```

<img width="592" height="109" alt="Clonación del repositorio" src="https://github.com/user-attachments/assets/d495f7b0-6c27-463c-8615-bb625f7f93e0" />

*En la terminal se observa cómo se descarga el repositorio de GitHub y se accede a su directorio para comenzar a trabajar con los archivos.*

# 4. Estructura del proyecto

El repositorio está organizado en diferentes carpetas para separar los archivos de configuración de Apache y los scripts encargados de automatizar la instalación.

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

Estructura actual del repositorio:

<img width="945" height="353" alt="Estructura del repositorio" src="https://github.com/user-attachments/assets/9a13a5db-6df5-4657-b986-cd2fabe84c22" />

*Se muestran las carpetas y archivos del proyecto. La carpeta `conf` contiene las plantillas de configuración de Apache, mientras que `scripts` contiene los archivos necesarios para automatizar la instalación y configuración HTTPS.*

Los principales archivos son:

- `README.md`: documentación de la práctica.
- `.gitignore`: evita subir archivos privados o que no deben incluirse en el repositorio.
- `conf/000-default.conf`: plantilla de configuración del Virtual Host HTTP.
- `conf/practica-https-ssl.conf`: plantilla de configuración del Virtual Host HTTPS.
- `scripts/install_apache.sh`: automatiza la instalación de Apache.
- `scripts/setup_selfsigned_certificate.sh`: genera el certificado y configura HTTPS.
- `scripts/.env.example`: plantilla con las variables necesarias para configurar el certificado.

# 5. Script install_apache.sh

Este script automatiza la instalación del servidor web Apache en la instancia EC2.

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

Sus funciones principales son:

- Comprobar mediante `dpkg -s apache2` si Apache ya está instalado.
- Si Apache ya está instalado, mostrar un mensaje y finalizar el script.
- Si no está instalado, actualizar los repositorios del sistema.
- Instalar Apache automáticamente sin necesitar intervención del usuario.
- Habilitar el servicio para que se inicie automáticamente.
- Iniciar Apache y dejarlo funcionando.

La opción `set -e` hace que el script termine si se produce un error en alguno de los comandos.

**Ejecución del script:**

```bash
sudo ./scripts/install_apache.sh
```

## 5.1. Instalación de Apache

<img width="963" height="556" alt="Instalación de Apache" src="https://github.com/user-attachments/assets/e5bf5cda-7a56-4ab2-ba1a-48b051a3a4ee" />

*Se muestra la ejecución del script durante la instalación de Apache, incluyendo los mensajes que indican el proceso de instalación.*

<img width="977" height="529" alt="Finalización de la instalación" src="https://github.com/user-attachments/assets/3087217c-7a02-4f4d-bdfd-c37b42eba7d2" />

*En esta captura se observa la finalización del proceso y el mensaje que confirma que Apache se ha instalado y arrancado correctamente.*

## 5.2. Comprobación de Apache

<img width="646" height="327" alt="Estado del servicio Apache" src="https://github.com/user-attachments/assets/2f1931f3-6fd5-46ec-ac5b-a3818d3e6ee2" />

*Se comprueba el estado del servicio Apache y se puede observar que se encuentra activo (`active (running)`), por lo que está funcionando correctamente.*

## 5.3. Segunda ejecución del script

<img width="635" height="34" alt="Segunda ejecución del script" src="https://github.com/user-attachments/assets/f58d4d1f-4669-4884-aac9-b45b49b709ed" />

*Se vuelve a ejecutar el script después de haber instalado Apache. Como el programa detecta que ya está instalado, muestra el mensaje correspondiente y finaliza sin repetir la instalación.*

# 6. Script setup_selfsigned_certificate.sh

Este segundo script automatiza la configuración HTTPS mediante la generación de un certificado autofirmado y la configuración de Apache para utilizarlo.

Primero comprueba que Apache está instalado y que existe el archivo `.env` con las variables necesarias.

Después genera la clave privada y el certificado mediante OpenSSL, configura los Virtual Hosts, habilita los módulos necesarios y reinicia Apache.

El script utiliza `set -e` para detener la ejecución si se produce algún error.

**Principales funciones:**

- Comprobar que Apache está instalado.
- Localizar el directorio del proyecto y el archivo `.env`.
- Leer las variables de configuración.
- Comprobar que las variables obligatorias están definidas.
- Verificar que la IP elástica está configurada.
- Comprobar que existen las plantillas de Apache.
- Crear los directorios necesarios para guardar el certificado y la clave privada.
- Generar el certificado autofirmado mediante OpenSSL.
- Incluir el dominio y la IP elástica en el campo SAN.
- Establecer los permisos adecuados para los archivos.
- Copiar las plantillas de configuración a Apache y sustituir los valores necesarios.
- Habilitar los módulos SSL y Rewrite.
- Habilitar el sitio HTTPS.
- Comprobar la sintaxis de Apache antes de reiniciar el servicio.

**Ejecución del script:**

```bash
sudo ./scripts/setup_selfsigned_certificate.sh
```

<img width="979" height="494" alt="Ejecución del script de configuración HTTPS" src="https://github.com/user-attachments/assets/638ac8f8-66ce-424d-b8b7-61554889b102" />

*Se muestra la ejecución del script encargado de generar el certificado autofirmado y configurar Apache para permitir conexiones HTTPS.*

## 6.1. Validación de la fecha del certificado

<img width="981" height="71" alt="Fechas de validez del certificado" src="https://github.com/user-attachments/assets/d16ea708-de3e-4f2d-88f6-d254c54c88ed" />

*Se comprueban las fechas de inicio y finalización de la validez del certificado para verificar durante cuánto tiempo será válido.*

## 6.2. Validación de la sintaxis de Apache

<img width="618" height="37" alt="Comprobación de sintaxis de Apache" src="https://github.com/user-attachments/assets/c876aa3f-502d-4a52-998d-3a14c5308043" />

*Se ejecuta la comprobación de configuración de Apache. El resultado `Syntax OK` indica que los archivos de configuración no contienen errores de sintaxis.*

## 6.3. Variables del archivo .env.example

El archivo `.env.example` sirve como plantilla para configurar los datos del certificado y las rutas utilizadas por el script.

```bash
# Datos del certificado
COUNTRY="ES"
STATE="Cantabria"
LOCALITY="Torrelavega"
ORGANIZATION="IES Miguel Herrero"
ORGANIZATIONAL_UNIT="Informatica"
COMMON_NAME="practica-https.test"
EMAIL="admin@example.com"

# Dominio e IP elastica
DOMAIN="practica-https.test"
ELASTIC_IP="18.210.39.46"

# Validez del certificado
DAYS=365

# Rutas del certificado y clave
CERT_FILE="/etc/ssl/certs/apache-selfsigned.crt"
CERT_KEY="/etc/ssl/private/apache-selfsigned.key"

# Nombres de las plantillas de configuracion Apache
HTTP_CONF="000-default.conf"
HTTPS_CONF="practica-https-ssl.conf"
```

Estas variables permiten modificar los datos del certificado sin tener que cambiar directamente el código del script.

- `COUNTRY`, `STATE` y `LOCALITY`: indican el país, provincia y localidad.
- `ORGANIZATION` y `ORGANIZATIONAL_UNIT`: identifican la organización y su unidad.
- `COMMON_NAME`: indica el nombre común del certificado.
- `DOMAIN`: establece el dominio utilizado por el servidor.
- `ELASTIC_IP`: contiene la IP elástica de la instancia.
- `DAYS`: determina el periodo de validez del certificado.
- `CERT_FILE`: indica dónde se guarda el certificado.
- `CERT_KEY`: indica dónde se guarda la clave privada.
- `HTTP_CONF` y `HTTPS_CONF`: identifican las plantillas de configuración de Apache.

La IP elástica y los datos de configuración deben mantenerse actualizados si se modifica la instancia o el dominio utilizado.

# 7. Configuración del certificado

Para habilitar HTTPS se utiliza un certificado autofirmado generado mediante OpenSSL.

El certificado se genera para el dominio `practica-https.test` y contiene también la IP elástica de la instancia en la extensión `subjectAltName` (SAN).

Los archivos se almacenan en las siguientes ubicaciones:

- Certificado: `/etc/ssl/certs/apache-selfsigned.crt`
- Clave privada: `/etc/ssl/private/apache-selfsigned.key`

La clave privada tiene permisos `600`, para que únicamente el propietario pueda leerla y modificarla. El certificado tiene permisos `644`, ya que no contiene información secreta.

Los datos utilizados para generar el certificado se encuentran en el archivo `.env`. Este archivo no se sube al repositorio, ya que contiene información de configuración específica de la instancia.

# 8. Virtual hosts

Para configurar Apache se utilizan dos archivos de configuración:

- `000-default.conf`: configura el acceso mediante HTTP por el puerto 80 y redirige las peticiones hacia HTTPS.
- `practica-https-ssl.conf`: configura el acceso HTTPS por el puerto 443 y establece las rutas del certificado y de la clave privada.

El script copia estas plantillas al directorio de configuración de Apache, sustituye los valores necesarios y habilita el sitio HTTPS.

De esta forma, Apache puede atender las peticiones HTTP y HTTPS utilizando las configuraciones correspondientes.

# 9. Verificaciones

Una vez ejecutados los scripts, se realizan distintas comprobaciones para verificar que la instalación y la configuración funcionan correctamente.

Las comprobaciones realizadas incluyen:

1. Instalación de Apache y estado del servicio.
2. Segunda ejecución del script de instalación.
3. Generación del certificado y comprobación de sus fechas.
4. Validación de la sintaxis de Apache.
5. Comprobación de los puertos 80 y 443.
6. Verificación de la redirección HTTP hacia HTTPS.
7. Comprobación de la respuesta del servidor HTTPS.
8. Verificación de la negociación TLS.
9. Acceso al servidor desde Firefox y consulta de los detalles del certificado.

En los siguientes apartados se muestran las capturas de estas comprobaciones.

# 10. Seguridad

Durante la práctica se tienen en cuenta varios aspectos relacionados con la seguridad:

- La conexión SSH utiliza el puerto 22 para administrar la instancia.
- El acceso HTTP se realiza mediante el puerto 80 y se redirige hacia HTTPS.
- Las conexiones seguras utilizan el puerto 443.
- La clave privada se almacena en `/etc/ssl/private/`.
- Se establecen permisos restrictivos para proteger la clave privada.
- El archivo `.env` real no se sube al repositorio.
- Se utiliza `.gitignore` para evitar incluir archivos privados.
- Se proporciona `.env.example` para mostrar las variables necesarias sin compartir el archivo de configuración real.

Al utilizar un certificado autofirmado, el navegador no reconoce automáticamente la entidad emisora como una autoridad certificadora de confianza. Por este motivo, puede mostrar una advertencia de seguridad al acceder a la página.

# 11. Sujeto, validez y SAN del certificado

<img width="988" height="70" alt="Información del certificado" src="https://github.com/user-attachments/assets/dd5b0569-3ca3-4b4a-ac7c-53bc3181a3fd" />

*Se muestran los datos principales del certificado, como el sujeto, las fechas de validez y la extensión SAN. Esta última permite asociar el certificado con el dominio y la dirección IP configurados.*

# 12. Puertos de escucha

<img width="989" height="88" alt="Puertos de escucha" src="https://github.com/user-attachments/assets/e9449dc3-edba-4100-8aec-6aefb1a0652c" />

*Se comprueba que Apache está escuchando en los puertos 80 y 443. El puerto 80 se utiliza para las conexiones HTTP y el 443 para las conexiones HTTPS.*

# 13. Redirección HTTP a HTTPS

<img width="489" height="105" alt="Redirección HTTP a HTTPS" src="https://github.com/user-attachments/assets/5728f790-f3d9-41c6-9de4-917b8f3d73eb" />

*Se comprueba que al realizar una petición mediante HTTP el servidor responde con una redirección permanente `301` hacia la dirección HTTPS. De esta manera, el usuario termina accediendo mediante una conexión segura.*

# 14. Respuesta HTTPS

<img width="537" height="185" alt="Respuesta HTTPS" src="https://github.com/user-attachments/assets/5adc7c0d-938e-4140-8029-c543a832aa01" />

*Se realiza una petición al servidor utilizando HTTPS y se comprueba que responde correctamente. Esto permite verificar que Apache está atendiendo las conexiones seguras mediante el puerto 443.*

# 15. Negociación TLS

<img width="643" height="574" alt="Primera comprobación de la negociación TLS" src="https://github.com/user-attachments/assets/746f57bc-f497-4036-a814-b764ee1b4e80" />

*Se utiliza OpenSSL para establecer una conexión con el servidor y comprobar el proceso de negociación TLS, así como la información del certificado presentado por Apache.*

<img width="480" height="376" alt="Segunda comprobación de la negociación TLS" src="https://github.com/user-attachments/assets/002fe179-1ae6-4c32-9abf-083613ebe196" />

*En esta segunda captura se muestran más detalles de la conexión establecida, permitiendo comprobar que el servidor utiliza TLS para proteger la comunicación.*

# 16. Uso en el navegador

Una vez realizadas las comprobaciones desde la terminal, se accede al dominio desde Firefox para verificar que la página se puede visualizar mediante HTTPS.

<img width="1363" height="574" alt="Acceso HTTPS desde Firefox" src="https://github.com/user-attachments/assets/1ef0929b-9ebb-4369-9cf1-5bfcf65aa97c" />

*Se accede al dominio `practica-https.test` desde Firefox. El navegador muestra una advertencia porque el certificado es autofirmado y no pertenece a una autoridad certificadora reconocida. Tras aceptar la excepción de seguridad, se puede acceder a la página.*

A continuación, se pulsa sobre el icono del candado y se accede a la información de seguridad de la conexión.

<img width="741" height="551" alt="Información de seguridad del navegador" src="https://github.com/user-attachments/assets/32935003-d73e-43d5-af71-d142f34f4b72" />

*Se consulta la información de seguridad de la página para comprobar que la conexión utiliza HTTPS y acceder a los datos del certificado.*

Por último, se abre el apartado del certificado para consultar sus detalles.

<img width="246" height="424" alt="Detalles del certificado en Firefox" src="https://github.com/user-attachments/assets/7ea97a66-dfec-4485-9b34-6d479a2c9f1f" />

*Se muestran los detalles del certificado utilizado por Apache, permitiendo consultar la información del certificado autofirmado desde el propio navegador.*

# 17. Finalización

Una vez terminada la práctica, se comprueba que Apache está instalado y funcionando, que el certificado se ha generado correctamente y que el servidor permite conexiones HTTPS.

También se verifica que las peticiones HTTP se redirigen hacia HTTPS y que la conexión segura funciona tanto desde la terminal como desde el navegador.
