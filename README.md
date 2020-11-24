# PRACTICA 2. DOCKER - DOCKER COMPOSE.
## Vicente Andani Auñón

<img src="img/dc.jpg" alt="icono docker compose" with="200" height="200">

## `¿Qué es Docker?`

Docker es una plataforma de software que le permite crear, probar e implementar aplicaciones rápidamente. Docker empaqueta software en unidades estandarizadas llamadas contenedores que incluyen todo lo necesario para que el software se ejecute. Utilizando Docker evitamos la sobrecarga de iniciar y mantener máquinas virtuales.

Docker permite entregar código con mayor rapidez, estandarizar las operaciones de las aplicaciones, transferir el código con facilidad y ahorrar dinero al mejorar el uso de recursos. Con Docker, se obtiene un solo objeto que se puede ejecutar de manera fiable en cualquier lugar.

### `Como instalar Docker en Ubuntu`

Para instalar Docker tendremos que ejecutar los siguientes comandos en nuestra terminal:

```
sudo apt update

sudo apt install apt-transport-https ca-certificates curl software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"

apt-cache policy docker-ce

sudo apt install docker-ce

sudo systemctl status docker
```

## `¿Qué es Docker Compose?`

Docker Compose es una herramienta que permite simplificar el uso de Docker. 
Con Compose se puede crear diferentes contenedores, diferentes servicios, unirlos a un volúmen común, iniciarlos y apagarlos, etc. Es un componente fundamental para poder construir aplicaciones y microservicios. 

Docker Compose te permite mediante archivos YAML instruir al Docker Engine a realizar tareas, programaticamente.

### `Como instalar Docker-Compose en Ubuntu`

Para instalar Docker-Compose tendremos que ejecutar los siguientes comandos en nuestra terminal:

```
sudo apt update

sudo curl -L "https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose
```

## `Introducción a la práctica`

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


### Grafana

Grafana es un servicio que se encarga de graficar las métricas creadas por Prometheus.

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
  grafana:
    image: grafana/grafana:7.1.5
    container_name: grafana_practica
    networks:
    - network_practica
    ports:
    - "3500:3000"
    volumes:
    - ./datasources.yml:/etc/grafana/provisioning/datasources/datasources.yml
    - myGrafanaVol:/var/lib/grafana
    environment:
      GF_AUTH_DISABLE_LOGIN_FORM: "true"
      GF_AUTH_ANONYMOUS_ENABLED: "true"
      GF_AUTH_ANONYMOUS_ORG_ROLE: Admin
      GF_INSTALL_PLUGINS: grafana-clock-panel 1.0.1
    depends_on:
    - prometheus
volumes:
  myGrafanaVol:
networks:
  network_practica:
```

Partimos de la imagen *grafana/grafana:7.1.5*, al contenedor le asignaremos el nombre *grafana_practica* y le asignamos la network *network_practica*. 
Le asignamos el puerto 3500 (ya que el 3000 lo tenemos en uso) y copiamos datasources a la ruta */etc/grafana/provisioning/datasources*, creamos un nuevo volumen llamado *myGrafanaVol* y lo asignamos a */var/lib/grafana*. Ahora vamos a establecer las variables de entorno, *GF_AUTH_DISABLE_LOGIN_FORM: "true"* esta variable sirve para deshabilitar el login, *GF_AUTH_ANONYMOUS_ENABLED: "true"* con esta habilitamos el usuario Anónimo, *GF_AUTH_ANONYMOUS_ORG_ROLE: Admin* para cambiar el rol del usuario Anónimo a Admin, *GF_INSTALL_PLUGINS: grafana-clock-panel 1.0.1* y instalamos el siguiente plugin. Finalmente indicamos que dependa del servicio Prometheus para que se inicie después que el.

## Ejecutar el Docker Compose 

Una vez creado el Docker Compose vamos a proceder a ejecutarlo, para ello ejecutamos el siguiente comando:

```
docker-compose up
```
<img src="img/docker-compose-up.png" alt="docker-compose-up" with="200" height="auto">
<img src="img/docker-compose-up2.png" alt="docker-compose-up" with="200" height="auto">

Ahora vamos al navegador y comprobamos las siguientes rutas:

```
localhost:83
```
Aquí podremos ver la app funcionando correctamente.

<img src="img/localhost83.png" alt="localhost83" with="200" height="auto">

```
localhost:9090
```

Aquí nos dirigiremos al apartado Status/Targets y veremos que el se muestra el acceso correcto a las métricas capturadas de la app.

<img src="img/localhost9090.png" alt="localhost9090" with="200" height="auto">

```
localhost:3500
```

Aquí podremos añádir paneles y graficas de nuestra aplicación

<img src="img/localhost3500.png" alt="localhost3500" with="200" height="auto">

### Crear panel asociado a los endpoints con Grafana.

Dentro de Grafana (*localhost:3500*) nos dirigimos a Create ->  Dashboard

<img src="img/dashboard.png" alt="dashboard" with="200" height="auto">

Seguidamente presionamos en añadir nuevo panel, y vamos a proceder a crear un panel con cada endpoint y después creamos un panel con la suma de las visitas de los dos endpoints.

<img src="img/addpanel.png" alt="addpanel" with="200" height="auto">

Para crear un panel con los dos endpoints nos dirigimos a Metrics y seleccionamos los endpoints.

<img src="img/endpoint.png" alt="endpoint" with="200" height="auto">

Tiene que quedar algo asi:

<img src="img/panel1.png" alt="panel1" with="200" height="auto">

Le damos a aplicar.

Ahora vamos a crear el siguiente panel (suma de todos los endpoints), repetimos el proceso anterior pero en Metrics introducimos lo siguiente:

```
sum(counterHomeEndpoint+counterMessageEndpoint)
```

<img src="img/sumpanel.png" alt="sumpanel" with="200" height="auto">

Y en el apartado Visualization seleccionamos el siguiente tema:

<img src="img/tema.png" alt="tema" with="200" height="auto">

Aplciamos y guardamos el Dashboard:

<img src="img/paneles.png" alt="paneles" with="200" height="auto">

<img src="img/save.png" alt="save" with="200" height="auto">

Ahora podemos hacer unas cuantas visitas a los endpoints (*localhost:83* y *localhost:83/message*) y ver las gráficas:

<img src="img/fianl_grafana.png" alt="fianl_grafana" with="200" height="auto">



