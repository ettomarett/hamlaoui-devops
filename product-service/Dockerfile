FROM openjdk:17-jdk-slim
FROM maven:3.8.1-openjdk-17-slim

WORKDIR /app

COPY target/*.jar app.jar

EXPOSE 8080

ENV JAVA_OPTS=""

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"] 