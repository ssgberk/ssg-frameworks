# Builder stage: scala-cli + JDK compile and package the site generator into one fat jar (untimed).
FROM eclipse-temurin:21-jdk-noble AS builder
ARG SCALA_CLI_VERSION=1.18.0
RUN apt-get -yqq update && apt-get -yqq install --no-install-recommends ca-certificates curl gzip \
 && rm -rf /var/lib/apt/lists/*
RUN case "$(dpkg --print-architecture)" in amd64) F=x86_64-pc-linux ;; arm64) F=aarch64-pc-linux ;; *) echo unsupported; exit 1 ;; esac \
 && curl -fsSL "https://github.com/VirtusLab/scala-cli/releases/download/v${SCALA_CLI_VERSION}/scala-cli-${F}.gz" | gunzip > /usr/local/bin/scala-cli \
 && chmod +x /usr/local/bin/scala-cli
WORKDIR /build
COPY src/Main.scala ./
RUN mkdir -p /out && scala-cli --power package --assembly --server=false -o /out/laika-site.jar Main.scala \
 && ls -l /out

# Runtime stage: a JRE, the fat jar, the site skeleton and the benchmark skeleton.
FROM eclipse-temurin:21-jre-noble

ARG DEBIAN_FRONTEND=noninteractive
ARG HYPERFINE_VERSION=1.20.0
# Pinned in src/Main.scala (//> using dep); repeated here so the version is machine-readable.
ARG LAIKA_VERSION=1.3.2
LABEL org.ssgberk.laika.version=$LAIKA_VERSION

RUN apt-get -yqq update \
 && apt-get -yqq install --no-install-recommends ca-certificates curl jq \
 && rm -rf /var/lib/apt/lists/*

RUN ARCH="$(dpkg --print-architecture)" \
 && curl -fsSL -o /tmp/hyperfine.deb \
      "https://github.com/sharkdp/hyperfine/releases/download/v${HYPERFINE_VERSION}/hyperfine_${HYPERFINE_VERSION}_${ARCH}.deb" \
 && dpkg -i /tmp/hyperfine.deb && rm /tmp/hyperfine.deb

WORKDIR /opt/laika/src

COPY --from=builder /out/laika-site.jar /opt/laika/laika-site.jar
COPY src/site/ /opt/laika/src/site/
COPY build.sh benchmark_config.json /opt/laika/src/
