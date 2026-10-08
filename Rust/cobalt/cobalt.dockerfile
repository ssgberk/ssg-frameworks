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

WORKDIR /opt/cobalt/src

ARG COBALT_VERSION=0.20.4
RUN ARCH="$(dpkg --print-architecture)" \
 && case "$ARCH" in amd64) CARCH=x86_64 ;; arm64) CARCH=aarch64 ;; *) echo "unsupported $ARCH"; exit 1 ;; esac \
 && curl -fsSL "https://github.com/cobalt-org/cobalt.rs/releases/download/v${COBALT_VERSION}/cobalt-v${COBALT_VERSION}-${CARCH}-unknown-linux-gnu.tar.gz" \
    | tar -xz -C /usr/local/bin ./cobalt \
 && cobalt --version

COPY src/ /opt/cobalt/src/
COPY build.sh benchmark_config.json /opt/cobalt/src/
