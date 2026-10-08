# Marmite publishes Linux release binaries for x86_64 only, so on arm64 the pinned
# version is compiled from the crates.io source (same version, same lockfile).
FROM rust:1-bookworm AS marmite-build
ARG DEBIAN_FRONTEND=noninteractive
ARG MARMITE_VERSION=0.4.2
RUN mkdir -p /out \
 && ARCH="$(dpkg --print-architecture)" \
 && case "$ARCH" in \
      amd64) curl -fsSL "https://github.com/rochacbruno/marmite/releases/download/${MARMITE_VERSION}/marmite-${MARMITE_VERSION}-x86_64-unknown-linux-gnu.tar.gz" \
               | tar -xz -C /out ;; \
      arm64) cargo install marmite --locked --version "${MARMITE_VERSION}" --root /cargo-out \
               && cp /cargo-out/bin/marmite /out/marmite ;; \
      *) echo "unsupported $ARCH"; exit 1 ;; \
    esac \
 && ls -l /out

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

WORKDIR /opt/marmite/src

COPY --from=marmite-build /out/marmite /usr/local/bin/marmite
RUN chmod +x /usr/local/bin/marmite && marmite --version

COPY src/ /opt/marmite/src/
COPY build.sh benchmark_config.json /opt/marmite/src/
