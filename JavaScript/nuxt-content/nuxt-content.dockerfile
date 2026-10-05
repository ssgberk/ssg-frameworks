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

ARG NODE_VERSION=24.21.0
RUN ARCH="$(dpkg --print-architecture)" \
 && case "$ARCH" in amd64) NARCH=x64 ;; arm64) NARCH=arm64 ;; *) echo "unsupported $ARCH"; exit 1 ;; esac \
 && curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NARCH}.tar.xz" \
    | tar -xJ -C /usr/local --strip-components=1 \
 && node --version && npm --version

WORKDIR /opt/nuxt-content/src
ENV NPM_CONFIG_UPDATE_NOTIFIER=false
# Same V8 heap cap for every Node generator, inside the 8 GB container limit (BT spec 008)
ENV NODE_OPTIONS=--max-old-space-size=6144

ENV NUXT_TELEMETRY_DISABLED=1

COPY package.json package-lock.json /opt/nuxt-content/src/
RUN npm ci

COPY src/ /opt/nuxt-content/src/
COPY build.sh benchmark_config.json /opt/nuxt-content/src/
