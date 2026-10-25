# Hola Docker

Proyecto de ejemplo basado en Spring Boot que expone un endpoint REST y puede ejecutarse tanto directamente como dentro de un contenedor Docker.

## Requisitos

- Java 25 con `javac`.
- Docker Engine funcionando.
- Maven no es necesario si se usa el wrapper incluido (`./mvnw`).

Para instalar la pila en Ubuntu o Debian puedes ejecutar:

```bash
./requirements.sh
```

Y verificar la versión instalada:

```bash
java -version
javac -version
```

Ambos comandos deben mostrar Java 25.

## Ejecutar la aplicación

Desde la raíz del proyecto:

```bash
./mvnw spring-boot:run
```

La aplicación queda disponible en:

- http://localhost:8080
- Endpoint: http://localhost:8080/hello

La respuesta del endpoint es:

```text
Hello Docker Danny Reina!
```

También puedes ejecutar la clase principal desde VS Code o desde tu IDE favorito abriendo `HolaDockerApplication.java`.

## Script de gestión interactiva

El repositorio incluye un menú para compilar, verificar requisitos, crear la imagen Docker y arrancar el contenedor:

```bash
./gestor.sh
```

Opciones disponibles:

1. Comprobar requisitos del sistema
2. Empaquetar la aplicación
3. Construir la imagen Docker
4. Ejecutar el contenedor
5. Mostrar el estado de la aplicación
6. Salir

## Empaquetado y pruebas

Generar el JAR:

```bash
./mvnw clean package -DskipTests
```

Ejecutar tests:

```bash
./mvnw test
```

## Docker

Primero empaqueta la aplicación y luego crea la imagen:

```bash
./mvnw clean package -DskipTests
docker build -t hola-docker:v1.0.0 .
```

Ejecuta el contenedor:

```bash
docker run -d --name hola-docker-container -p 8080:8080 hola-docker:v1.0.0
```

La imagen usa Java 25 y el archivo JAR generado se copia a `/app/app.jar` en el contenedor.

## Estructura principal

- `src/main/java/.../HolaDockerApplication.java`: clase principal
- `src/main/java/.../HolaController.java`: controlador REST
- `Dockerfile`: definición de la imagen Docker
- `gestor.sh`: menú interactivo para gestión del proyecto
- `requirements.sh`: instalación de Java 25 y Maven
- `pom.xml`: configuración de Maven y Spring Boot
