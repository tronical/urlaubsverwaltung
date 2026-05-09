# syntax=docker/dockerfile:1.7

# ---------------------------------------------------------------------------
# Builder: compile the Spring Boot fat jar from source.
# Maven's frontend-maven-plugin downloads its own Node/NPM, so we only need
# a JDK 25 here. We pull Liberica to match .tool-versions.
# ---------------------------------------------------------------------------
FROM eclipse-temurin:25-jdk-noble AS builder

ENV MAVEN_OPTS="-Dmaven.repo.local=/root/.m2/repository -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn"

WORKDIR /build

# Pre-fetch Maven dependencies for better layer caching.
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN ./mvnw -B -ntp dependency:go-offline -DskipTests || true

# Now copy the rest of the source and build.
COPY . .
RUN ./mvnw -B -ntp -DskipTests clean package \
 && cp target/urlaubsverwaltung-*.jar /tmp/urlaubsverwaltung.jar

# ---------------------------------------------------------------------------
# Runtime: Cloudron base + Liberica JRE 25.
# ---------------------------------------------------------------------------
FROM cloudron/base:5.0.0

ENV LIBERICA_VERSION=25.0.2+12 \
    JAVA_HOME=/opt/jdk-25 \
    PATH=/opt/jdk-25/bin:$PATH

RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) liberica_arch=amd64 ;; \
      arm64) liberica_arch=aarch64 ;; \
      *) echo "unsupported arch: $arch" >&2; exit 1 ;; \
    esac; \
    url="https://download.bell-sw.com/java/${LIBERICA_VERSION}/bellsoft-jdk${LIBERICA_VERSION}-linux-${liberica_arch}.tar.gz"; \
    curl -fsSL "$url" -o /tmp/jdk.tar.gz; \
    mkdir -p /opt/jdk-25; \
    tar -xzf /tmp/jdk.tar.gz -C /opt/jdk-25 --strip-components=1; \
    rm /tmp/jdk.tar.gz; \
    java -version

RUN mkdir -p /app/code /app/data
WORKDIR /app/code

COPY --from=builder /tmp/urlaubsverwaltung.jar /app/code/urlaubsverwaltung.jar
COPY cloudron/start.sh /app/code/start.sh
RUN chmod +x /app/code/start.sh

EXPOSE 8080

CMD ["/app/code/start.sh"]
