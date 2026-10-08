FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG HYPERFINE_VERSION=1.20.0

RUN apt-get -yqq update \
 && apt-get -yqq install --no-install-recommends \
      build-essential ca-certificates curl git jq moreutils tree wget xz-utils \
 && rm -rf /var/lib/apt/lists/*

RUN ARCH="$(dpkg --print-architecture)" \
 && curl -fsSL -o /tmp/hyperfine.deb \
      "https://github.com/sharkdp/hyperfine/releases/download/v${HYPERFINE_VERSION}/hyperfine_${HYPERFINE_VERSION}_${ARCH}.deb" \
 && dpkg -i /tmp/hyperfine.deb && rm /tmp/hyperfine.deb

# ---- RUNTIME block: Temurin JRE + Clojure CLI ----
ARG TEMURIN_VERSION=25.0.4.1_1
ARG TEMURIN_TAG=jdk-25.0.4.1%2B1
ARG CLOJURE_VERSION=1.12.6.1673
ENV JAVA_HOME=/opt/java
ENV PATH=/opt/java/bin:$PATH
RUN ARCH="$(dpkg --print-architecture)" \
 && case "$ARCH" in amd64) JARCH=x64 ;; arm64) JARCH=aarch64 ;; *) echo "unsupported $ARCH"; exit 1 ;; esac \
 && mkdir -p /opt/java \
 && curl -fsSL "https://github.com/adoptium/temurin25-binaries/releases/download/${TEMURIN_TAG}/OpenJDK25U-jre_${JARCH}_linux_hotspot_${TEMURIN_VERSION}.tar.gz" \
    | tar -xz -C /opt/java --strip-components=1 \
 && java -version \
 && curl -fsSL -o /tmp/clojure-install.sh \
      "https://github.com/clojure/brew-install/releases/download/${CLOJURE_VERSION}/linux-install.sh" \
 && bash /tmp/clojure-install.sh && rm /tmp/clojure-install.sh

# Cryogen: cryogen-core and cryogen-flexmark are pinned in deps.edn.
ARG CRYOGEN_VERSION=0.5.1
LABEL org.ssgberk.cryogen.version=$CRYOGEN_VERSION

WORKDIR /opt/cryogen/src

# ---- GENERATOR block: resolve every dependency into ~/.m2 and cache the classpath (the timed build runs offline) ----
COPY src/deps.edn /opt/cryogen/src/deps.edn
RUN clojure -P -M:build \
 && find ~/.m2 -name 'cryogen-core*.jar' | grep "${CRYOGEN_VERSION}" \
 && ls /opt/cryogen/src/.cpcache

COPY src/ /opt/cryogen/src/
COPY build.sh benchmark_config.json /opt/cryogen/src/
