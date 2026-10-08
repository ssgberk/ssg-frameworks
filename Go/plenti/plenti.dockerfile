FROM golang:1.25-bookworm AS builder

# Plenti publishes release binaries for linux amd64 only; v8go ships prebuilt V8 for arm64 too,
# so the pinned tag is compiled from source (cgo) and works on both architectures.
ARG PLENTI_VERSION=0.7.25
ARG PLENTI_COMMIT=bd0e349a477065e8e2197ec22b654af38080f877
RUN git clone https://github.com/plentico/plenti /src \
 && cd /src && git checkout "${PLENTI_COMMIT}" \
 && CGO_ENABLED=1 go build -trimpath -o /out/plenti . \
 && /out/plenti --help >/dev/null

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

WORKDIR /opt/plenti/src

ARG PLENTI_VERSION=0.7.25
COPY --from=builder /out/plenti /usr/local/bin/plenti

COPY src/ /opt/plenti/src/
COPY build.sh benchmark_config.json /opt/plenti/src/
