FROM eclipse-temurin:25-jre
#FROM eclipse-temurin:17-jre-alpine

WORKDIR /app
COPY target/hola-docker-*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
