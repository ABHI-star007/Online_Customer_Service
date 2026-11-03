FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn -B -q dependency:go-offline
COPY src ./src
RUN mvn -B -q -DskipTests package

FROM eclipse-temurin:17-jre
# MariaDB runs in the same container because Render's free plan has no
# private services. Its data lives on the container filesystem, so it is
# wiped whenever the instance restarts, sleeps or redeploys.
RUN apt-get update \
 && apt-get install -y --no-install-recommends mariadb-server \
 && rm -rf /var/lib/apt/lists/*
COPY docker/my-small.cnf /etc/mysql/mariadb.conf.d/99-small.cnf
COPY docker/start.sh /start.sh
RUN chmod +x /start.sh
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
# 512 MB is shared with MariaDB, so cap the JVM explicitly
ENV JAVA_TOOL_OPTIONS="-Xmx200m -XX:MaxMetaspaceSize=110m -XX:ReservedCodeCacheSize=32m -XX:TieredStopAtLevel=1 -XX:+UseSerialGC -Xss512k"
EXPOSE 8080
CMD ["/start.sh"]
