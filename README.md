# PRACTICA 2. DOCKER - DOCKER COMPOSE.
## Vicente Andani Auñón

<img src="img/dc.jpg" alt="icono docker compose" with="200" height="200">

`¿Qué es Docker?`

Docker es una plataforma de software que le permite crear, probar e implementar aplicaciones rápidamente. Docker empaqueta software en unidades estandarizadas llamadas contenedores que incluyen todo lo necesario para que el software se ejecute. Utilizando Docker evitamos la sobrecarga de iniciar y mantener máquinas virtuales.

Docker permite entregar código con mayor rapidez, estandarizar las operaciones de las aplicaciones, transferir el código con facilidad y ahorrar dinero al mejorar el uso de recursos. Con Docker, se obtiene un solo objeto que se puede ejecutar de manera fiable en cualquier lugar.

`¿Qué es Docker Compose?`

Docker Compose es una herramienta que permite simplificar el uso de Docker. 
Con Compose se puede crear diferentes contenedores, diferentes servicios, unirlos a un volúmen común, iniciarlos y apagarlos, etc. Es un componente fundamental para poder construir aplicaciones y microservicios. 

Docker Compose te permite mediante archivos YAML instruir al Docker Engine a realizar tareas, programaticamente.

`Introducción a la práctica`

En esta práctica aprenderemos el funcionamiento de Docker junto a Docker Compose. Tendremos que realizar un archivo docker compose que contendrá 3 servicios (la aplicación, Prometheus y Grafana) conectados entre si, en ese archivo docker compose tambien utilizaremos un DockerFile. Finalmente intentaremos implementar la practica en un proyecto más grande.

## Aplicación

Primero vamos a proceder a realizar un contendedor que se encargará de poner en funcionamiento un servidor express. Para ello tenemos que realizar un Dockerfile.

He movido los archivos del servidor a la carpeta src.

### Creación del dockerignore.

Antes de realizar el Dockerfile es recomendable crear un dockerignore para evitar que archivos/carpetas inecesarias se pasen al contenedor, en mi caso voy a introducir en el dockerignore la carpeta node_modules (ya que en el servidor ya instalaremos los paquetes necesarios.)

Para ello creamos un fichero con el nombre *.dockerignore* y añadimos *node_modules*

### Creación del Dockerfile.

Ahora vamos a empezar creando el Dockerfile de la siguiente forma.
```
FROM node:alpine3.10
RUN mkdir myapp
WORKDIR /myapp
COPY ./src .
RUN npm install
EXPOSE 3000
CMD ["node", "app.js"]
```

Primero obtenemos la imagen alpine3.10 de Node. Ahora tenemos que indicar la ruta donde estará nuestra aplicación funcionando, en mi caso creo una carpeta llamada "myapp" y establezco el directorio de trabajo a esa misma carpeta.

Copiamos el contenido de la carpeta local src (donde tenemos el servidor) al directorio de trabajo actual, esto copiara los archivos de dentro de SRC a la carpeta myapp de nuestro contenedor.

Ahora vamos a instalar los paquetes necesarios para el funcionamiento del servidor, en el Dockerfile indicamos que realize un NPM INSTALL en el directorio donde tenemos el packages.json.

Tenemos que exponer el puerto 3000 para después poder vincularlo con uno de nuestra maquina real.

Finalmente le indicamos al Dockerfile que ejecute el servidor con node app.js, esto dejará abierto el servidor en el contenedor.


### Test Dockerfile
Una vez finalizado el Dockerfile recomiendo probarlo realizando un build y viendo que podemos acceder

```
docker build . --tag myapp
```
<img src="img/myapp_docker_build.png" alt="myapp_docker_build" with="200" height="auto">

Ahora comprobamos que la imagen se ha creado correctamente

```
docker images
```
<img src="img/myapp_docker_images.png" alt="myapp_docker_images" with="200" height="auto">

Vamos a crear un contenedor con esa imagen, simplemente para probar que funciona correctamente antes de realizar el archivo docker-compose.

```
sudo docker run -d -p 9001:3000 --name myapp myapp
```
<img src="img/myapp_docker_container.png" alt="myapp_docker_container" with="200" height="auto">

Y si vamos al navegador por el puerto indicado podremos acceder a la web que esta sirviendo el servidor express en el contenedor creado.

<img src="img/myapp_docker_test.png" alt="myapp_docker_test" with="200" height="auto">


## Crear el Docker Compose 

Vamos a crear un archivo *docker-compose.yml* en el cual iniciaremos tres servicios, el primero será la Aplicación con su dockerfile, después el prometheus para recoger metricas en tiempo real y el Grafana para crear graficas obtenidas desde el prometheus.

Primero vamos a añadir el servicio que se encargará de crear el contenedor con el Dockerfile anteriormente creado.

Quedará asi:

```
version: '3'
services:
  myapp_practica:
    build: .
    container_name: myapp_practica
    networks:
    - network_practica
    ports:
    - '83:3000'
networks:
  network_practica:
```

Con el parámetro build indicamos que tiene que partir de un Dockerfile, al estar en la misma ubicación se pone un punto.
A continuación, le asignamos el nombre de contenedor, y creamos la network que utilizarán los tres servicios. Posteriormente, asignamos el puerto 83 de nuestro ordenador al 3000 del contenedor.

### Prometheus

Prometheus es una aplicación que nos permite recoger métricas de de una aplicación en tiempo real.

Ahora vamos crear el servicio que se encargará de montar el contendor del prometheus

El *docker-compose.yml* quedará así:

```
version: '3'
services:
  myapp_practica:
    build: .
    container_name: myapp_practica
    networks:
    - network_practica
    ports:
    - '83:3000'
  prometheus:
    image: prom/prometheus:v2.20.1
    container_name: prometheus_practica
    networks:
    - network_practica
    ports:
    - "9090:9090"
    volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml
    command:
    - --config.file=/etc/prometheus/prometheus.yml
    depends_on:
    - myapp_practica
networks:
  network_practica:
```

Partimos de la imagen *prom/prometheus:v2.20.1*, al contenedor le asignaremos el nombre *prometheus_practica* y le asignamos la network *network_practica*. 
Le asignamos el puerto 9090 y copiamos la configuración a la ruta */etc/prometheus/*, le indicamos que ejecute el siguiente comando para que cargue la configuración previamente copiada: *--config.file=/etc/prometheus/prometheus.yml*. Finalmente, indicamos que dependa del servicio *myapp_practica* para que se inicie cuando este servicio se haya iniciado.
