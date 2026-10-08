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

# soupault only rewrites HTML; Markdown goes through the cmark-gfm preprocessor (pinned Ubuntu 24.04 package).
ARG CMARK_GFM_VERSION=0.29.0.gfm.6-6build1
RUN apt-get -yqq update \
 && apt-get -yqq install --no-install-recommends cmark-gfm=${CMARK_GFM_VERSION} \
 && rm -rf /var/lib/apt/lists/* && cmark-gfm --version

ARG SOUPAULT_VERSION=5.3.0
RUN ARCH="$(dpkg --print-architecture)" \
 && case "$ARCH" in amd64) SARCH=x86_64 ;; arm64) SARCH=arm64 ;; *) echo "unsupported $ARCH"; exit 1 ;; esac \
 && curl -fsSL "https://github.com/PataphysicalSociety/soupault/releases/download/${SOUPAULT_VERSION}/soupault-${SOUPAULT_VERSION}-linux-${SARCH}.tar.gz" \
    | tar -xz -C /tmp \
 && install -m 0755 /tmp/soupault-${SOUPAULT_VERSION}-linux-${SARCH}/soupault /usr/local/bin/soupault \
 && rm -rf /tmp/soupault-* && soupault --version-number

WORKDIR /opt/soupault/src

COPY src/ /opt/soupault/src/
COPY build.sh benchmark_config.json /opt/soupault/src/
