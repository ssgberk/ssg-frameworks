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

WORKDIR /opt/site/src

ARG QUARTO_VERSION=1.10.18
RUN ARCH="$(dpkg --print-architecture)" \
 && case "$ARCH" in amd64|arm64) ;; *) echo "unsupported $ARCH"; exit 1 ;; esac \
 && curl -fsSL -o /tmp/quarto.deb \
      "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-${ARCH}.deb" \
 && apt-get -yqq update && apt-get -yqq install --no-install-recommends /tmp/quarto.deb \
 && rm -rf /tmp/quarto.deb /var/lib/apt/lists/* && quarto --version

COPY src/ /opt/site/src/
COPY build.sh benchmark_config.json /opt/site/src/
