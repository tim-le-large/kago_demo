# Build
FROM eclipse-temurin:17-jdk-jammy AS build
WORKDIR /app

COPY gradlew .
COPY gradle gradle
COPY build.gradle settings.gradle ./
COPY src src

RUN chmod +x gradlew \
    && ./gradlew bootJar -x test --no-daemon \
    && cp build/libs/*.jar /app/application.jar

# Run
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

RUN useradd --system --no-create-home --shell /usr/sbin/nologin app \
    && chown -R app:app /app
USER app

COPY --from=build /app/application.jar /app/application.jar

ENV JAVA_OPTS="-Xms64m -Xmx384m"
EXPOSE 8080

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/application.jar"]
