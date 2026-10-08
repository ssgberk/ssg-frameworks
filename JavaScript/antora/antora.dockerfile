FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG HYPERFINE_VERSION=1.20.0

RUN apt-get -yqq update \
 && apt-get -yqq install --no-install-recommends \
      build-essential ca-certificates curl git jq moreutils tree wget xz-utils zip \
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

WORKDIR /opt/antora/src
ENV NPM_CONFIG_UPDATE_NOTIFIER=false
# Same V8 heap cap for every Node generator, inside the 8 GB container limit (BT spec 008)
ENV NODE_OPTIONS=--max-old-space-size=6144

COPY package.json package-lock.json /opt/antora/src/
RUN npm ci

COPY src/ /opt/antora/src/
COPY build.sh benchmark_config.json /opt/antora/src/

# Antora reads content sources from git: make the project a one-commit repository whose
# working tree holds the generated posts (playbook: worktrees). The UI bundle is built
# locally from ui/ (Antora never fetches one at build time).
RUN cd ui && zip -qr ../ui-bundle.zip . && cd .. \
 && git init -q -b main . \
 && git -c user.name=ssgberk -c user.email=ssgberk@example.com add antora.yml modules \
 && git -c user.name=ssgberk -c user.email=ssgberk@example.com commit -q -m init
