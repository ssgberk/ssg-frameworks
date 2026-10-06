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

WORKDIR /opt/observable-framework/src
ENV NPM_CONFIG_UPDATE_NOTIFIER=false
ENV OBSERVABLE_TELEMETRY_DISABLE=true
# Same V8 heap cap for every Node generator, inside the 8 GB container limit (BT spec 008)
ENV NODE_OPTIONS=--max-old-space-size=6144

COPY package.json package-lock.json /opt/observable-framework/src/
RUN npm ci

COPY src/ /opt/observable-framework/src/
COPY build.sh benchmark_config.json /opt/observable-framework/src/

# Resolve Framework's built-in npm modules (npm:<lib>@latest) once, untimed, into
# src/.observablehq/cache/{_npm,_observablehq}; they are dependencies like node_modules and survive
# the timed prepare step. Only the data-loader output is wiped between timed runs.
RUN number_of_files=1 content_size=0.500 SSGBERK_GENERATE_ONLY=1 ./build.sh \
 && npx observable build \
 && rm -rf dist src/posts/20*.md src/.observablehq/cache/posts.json
