FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG HYPERFINE_VERSION=1.20.0

RUN apt-get -yqq update \
 && apt-get -yqq install --no-install-recommends \
      build-essential ca-certificates curl git jq moreutils tree unzip wget xz-utils \
 && rm -rf /var/lib/apt/lists/*

RUN ARCH="$(dpkg --print-architecture)" \
 && curl -fsSL -o /tmp/hyperfine.deb \
      "https://github.com/sharkdp/hyperfine/releases/download/v${HYPERFINE_VERSION}/hyperfine_${HYPERFINE_VERSION}_${ARCH}.deb" \
 && dpkg -i /tmp/hyperfine.deb && rm /tmp/hyperfine.deb

# Deno release binary, verified against the sha256 published for each architecture
ARG DENO_VERSION=2.9.7
ARG DENO_SHA256_AMD64=c6527f24f4b16031d3ae4fa9f658d5f11534c8d84ce7dc8502420280919c3490
ARG DENO_SHA256_ARM64=c832298b1ad4422481334855f6003e0f54145762c5a134f20a489511d2f65bbf
RUN ARCH="$(dpkg --print-architecture)" \
 && case "$ARCH" in \
      amd64) DARCH=x86_64; SHA="${DENO_SHA256_AMD64}" ;; \
      arm64) DARCH=aarch64; SHA="${DENO_SHA256_ARM64}" ;; \
      *) echo "unsupported $ARCH"; exit 1 ;; \
    esac \
 && curl -fsSL -o /tmp/deno.zip \
      "https://github.com/denoland/deno/releases/download/v${DENO_VERSION}/deno-${DARCH}-unknown-linux-gnu.zip" \
 && echo "${SHA}  /tmp/deno.zip" | sha256sum -c - \
 && unzip -q /tmp/deno.zip -d /usr/local/bin && rm /tmp/deno.zip \
 && deno --version

WORKDIR /opt/lume/src

# No update check; modules live in DENO_DIR (kept, like node_modules) so the timed build is offline
ENV DENO_NO_UPDATE_CHECK=1
ENV DENO_DIR=/opt/lume/deno

# Lume is pinned in src/deno.json (import map) and src/deno.lock; the ARG records the version and must match
ARG LUME_VERSION=3.3.2
COPY src/ /opt/lume/src/
RUN grep -q "lume@${LUME_VERSION}/" deno.json
# Warm DENO_DIR with a real build of one sample post (lockfile enforced), then drop the sample output
RUN printf -- '---\ntitle: Warm\ndate: 2026-01-01T00:00:00Z\nsummary: Warm\nauthor: Warm\ntags:\n    - warm\n---\n# Warm\n' > site/posts/2026-01-01-1.md \
 && deno run -A --frozen lume/cli.ts \
 && rm -rf _site site/posts/2026-01-01-1.md

COPY build.sh benchmark_config.json /opt/lume/src/
