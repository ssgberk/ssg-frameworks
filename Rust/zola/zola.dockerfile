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

WORKDIR /opt/zola/src

ARG ZOLA_VERSION=0.23.6
RUN ARCH="$(dpkg --print-architecture)" \
 && case "$ARCH" in amd64) ZARCH=x86_64 ;; arm64) ZARCH=aarch64 ;; *) echo "unsupported $ARCH"; exit 1 ;; esac \
 && curl -fsSL "https://github.com/getzola/zola/releases/download/v${ZOLA_VERSION}/zola-v${ZOLA_VERSION}-${ZARCH}-unknown-linux-gnu.tar.gz" \
    | tar -xz -C /usr/local/bin && zola --version

COPY src/ /opt/zola/src/
COPY build.sh benchmark_config.json /opt/zola/src/
