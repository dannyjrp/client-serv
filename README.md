# Hola Docker

Sample Spring Boot application. The Maven project and interactive management script are in `hola-docker/`.

## Requirements

- JDK 25, including `javac`. On Ubuntu, install it with `sudo apt install openjdk-25-jdk`.
- Docker Engine for image and container operations. The daemon must be running for Docker commands.
- Maven does not need to be installed separately; the project includes the Maven Wrapper (`mvnw`).

Check Java with:

```bash
java -version
javac -version
```

Both commands should report version 25.

## Run from VS Code

Open the repository root in VS Code, then use the integrated terminal:

```bash
cd hola-docker
./mvnw spring-boot:run
```

The application starts at <http://localhost:8080>. The `/hello` endpoint returns `Hello Docker Danny Reina!`.

Alternatively, open `HolaDockerApplication.java` and run its `main` method in VS Code.

## Interactive Manager

Start the menu from the repository root with:

```bash
cd hola-docker
./gestor.sh
```

The menu provides these options:

1. **Check system prerequisites**: checks for `java`, Maven (`mvn` or the project's `mvnw`), and `docker`.
2. **Package the application**: runs `./mvnw clean package -DskipTests`. The executable JAR is generated under `hola-docker/target/` (currently `hola-docker-0.0.1-SNAPSHOT.jar`).
3. **Build the Docker image**: requires a generated JAR and builds `hola-docker:v1.0.0` from the Dockerfile.
4. **Run the Docker container**: requires Docker and the image. Starts `hola-docker-container`, mapping port 8080. If a container with that name is running, the script asks whether to stop and remove it first; a stopped container with that name is removed automatically.
5. **Show application status**: reports whether the JAR exists and its size, whether the Docker image exists and when it was created, and whether an application container is running. It reports when Docker status cannot be queried.
6. **Exit**: displays a farewell message and ends the script.

## Tests

From `hola-docker/`, run:

```bash
./mvnw test
```

## Docker

First package the application, then build the image from `hola-docker/`:

```bash
./mvnw clean package -DskipTests
docker build -t hola-docker:v1.0.0 .
```

The Dockerfile copies the generated JAR from `target/` to `/app/app.jar` and runs it with the Java 25 runtime. The Java 17 Alpine base image is currently commented out: a Java 17 runtime cannot execute a JAR compiled for Java 25.
