# Builder stage: GHC + cabal compile the `site` executable once (untimed, as a real Hakyll site does).
FROM haskell:9.10-slim-bookworm AS builder
WORKDIR /build
COPY src/hakyll-site.cabal src/cabal.project* ./
# crypton's sha3_armv8.c needs the SHA3 extension enabled on aarch64 (gcc 12 rejects it otherwise):
# a gcc wrapper adds the flag for dependencies too (--ghc-options only reaches local packages).
RUN if [ "$(dpkg --print-architecture)" = arm64 ]; then \
      printf '#!/bin/sh\nexec /usr/bin/gcc -march=armv8.2-a+sha3 "$@"\n' > /usr/local/bin/gcc-ssgberk; \
    else \
      printf '#!/bin/sh\nexec /usr/bin/gcc "$@"\n' > /usr/local/bin/gcc-ssgberk; \
    fi && chmod +x /usr/local/bin/gcc-ssgberk
RUN cabal update --index-state=2026-10-01T00:00:00Z \
 && cabal build exe:site -j1 --only-dependencies --with-gcc=/usr/local/bin/gcc-ssgberk --ghc-options=-j1
COPY src/site.hs ./
RUN cabal build exe:site -j1 --with-gcc=/usr/local/bin/gcc-ssgberk --ghc-options=-j1 \
 && mkdir -p /out && cp "$(cabal list-bin exe:site)" /out/site && strip /out/site \
 && ldd /out/site

# Runtime stage: compiled binary, shared libs it needs, templates and the benchmark skeleton.
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG HYPERFINE_VERSION=1.20.0
# Pinned in src/hakyll-site.cabal and src/cabal.project.freeze; repeated here so the version is machine-readable.
ARG HAKYLL_VERSION=4.17.0.0
LABEL org.ssgberk.hakyll.version=$HAKYLL_VERSION

RUN apt-get -yqq update \
 && apt-get -yqq install --no-install-recommends \
      ca-certificates curl jq libgmp10 libffi8 zlib1g \
 && rm -rf /var/lib/apt/lists/*

RUN ARCH="$(dpkg --print-architecture)" \
 && curl -fsSL -o /tmp/hyperfine.deb \
      "https://github.com/sharkdp/hyperfine/releases/download/v${HYPERFINE_VERSION}/hyperfine_${HYPERFINE_VERSION}_${ARCH}.deb" \
 && dpkg -i /tmp/hyperfine.deb && rm /tmp/hyperfine.deb

WORKDIR /opt/hakyll/src

COPY --from=builder /out/site /opt/hakyll/src/site
COPY src/templates/ /opt/hakyll/src/templates/
COPY src/assets/ /opt/hakyll/src/assets/
COPY src/index.html /opt/hakyll/src/index.html
COPY build.sh benchmark_config.json /opt/hakyll/src/
