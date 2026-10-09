# Builder stage: GHC + cabal compile the emanote executable from Hackage (untimed).
FROM haskell:9.10-slim-bookworm AS builder
ARG EMANOTE_VERSION=1.4.0.0
RUN if [ "$(dpkg --print-architecture)" = arm64 ]; then \
      printf '#!/bin/sh\nexec /usr/bin/gcc-12 -march=armv8.2-a+sha3 "$@"\n' > /usr/bin/gcc.new; \
      chmod +x /usr/bin/gcc.new && mv -f /usr/bin/gcc.new /usr/bin/gcc; \
    fi
# crypton's sha3_armv8.c needs the SHA3 extension on aarch64 (gcc 12): /usr/bin/gcc is replaced by a wrapper.
# Emanote 1.4.0.0's dependency set (vector, tailwind, aeson-optics) is solvable with GHC 9.8, not 9.10.
ENV GHCUP_INSTALL_BASE_PREFIX=/opt/ghcup
RUN curl -fsSL -o /usr/local/bin/ghcup "https://downloads.haskell.org/~ghcup/0.1.50.2/$(uname -m)-linux-ghcup-0.1.50.2" \
 && chmod +x /usr/local/bin/ghcup \
 && ghcup install ghc 9.8.4 --set \
 && ln -sf /opt/ghcup/.ghcup/bin/ghc-9.8.4 /usr/local/bin/ghc && ghc --version && ghc --info | grep -i 'C compiler command'
ENV PATH=/opt/ghcup/.ghcup/bin:$PATH
# tailwind and emanote use Template Haskell splices (staticWhich "tailwind" / "stork") that need the executables
# at compile time; empty stubs satisfy them (the real tools serve live reload and full-text search only). The cabal store is a BuildKit cache mount
# so a failed attempt resumes instead of recompiling ~280 packages.
RUN --mount=type=cache,target=/root/.local/state/cabal/store,id=ssgberk-emanote-cabal-store \
    for t in tailwind stork; do printf '#!/bin/sh\nexit 0\n' > /usr/local/bin/$t && chmod +x /usr/local/bin/$t; done \
 && cabal update --index-state=2026-10-01T00:00:00Z \
 && cabal install "emanote-${EMANOTE_VERSION}" -j1 --ghc-options=-j1 --allow-newer=tailwind:base \
      --install-method=copy --installdir=/out/bin --overwrite-policy=always \
 && strip /out/bin/emanote \
 && mkdir -p /out/share \
 && cp -r "$(find /root/.local/state/cabal/store -type d -path "*/emanote-${EMANOTE_VERSION}-*/share" | head -1)" /out/share/emanote \
 && ls /out/share/emanote && ldd /out/bin/emanote

# Runtime stage: stripped binary, its data files (default templates) and the benchmark skeleton.
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG HYPERFINE_VERSION=1.20.0
ARG EMANOTE_VERSION=1.4.0.0
LABEL org.ssgberk.emanote.version=$EMANOTE_VERSION

RUN apt-get -yqq update \
 && apt-get -yqq install --no-install-recommends \
      ca-certificates curl jq libgmp10 libffi8 zlib1g \
 && rm -rf /var/lib/apt/lists/*

RUN ARCH="$(dpkg --print-architecture)" \
 && curl -fsSL -o /tmp/hyperfine.deb \
      "https://github.com/sharkdp/hyperfine/releases/download/v${HYPERFINE_VERSION}/hyperfine_${HYPERFINE_VERSION}_${ARCH}.deb" \
 && dpkg -i /tmp/hyperfine.deb && rm /tmp/hyperfine.deb

COPY --from=builder /out/bin/emanote /usr/local/bin/emanote
COPY --from=builder /out/share/emanote /usr/local/share/emanote
# Emanote shells out to the absolute paths of `stork` and `tailwind` found at compile time.
# stork: stub that reads stdin and prints nothing, so the search index (-/stork.st) stays empty (Stork has no arm64
# release and only builds that index). tailwind: the real Tailwind CSS 3.4 standalone CLI (bundles the typography,
# forms, aspect-ratio and line-clamp plugins Emanote's config requires); it compiles tailwind.css during `gen`.
COPY --from=builder /usr/local/bin/stork /usr/local/bin/stork
ARG TAILWIND_VERSION=3.4.17
RUN case "$(dpkg --print-architecture)" in arm64) T=arm64 ;; *) T=x64 ;; esac \
 && curl -fsSL -o /usr/local/bin/tailwind \
      "https://github.com/tailwindlabs/tailwindcss/releases/download/v${TAILWIND_VERSION}/tailwindcss-linux-${T}" \
 && chmod +x /usr/local/bin/tailwind
ENV emanote_datadir=/usr/local/share/emanote

WORKDIR /opt/emanote/src
COPY src/site/ /opt/emanote/src/site/
COPY build.sh benchmark_config.json /opt/emanote/src/
