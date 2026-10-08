FROM golang:1.25-bookworm AS builder

ARG INK_COMMIT=f9aeb2b15e860440d85c1370ac408f561598567e
RUN git clone https://github.com/InkProject/ink /src \
 && cd /src && git checkout "${INK_COMMIT}" \
 && CGO_ENABLED=0 go build -trimpath -o /out/ink . \
 && /out/ink --version

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

WORKDIR /opt/ink/src

# Ink publishes no versions (the only release is the rolling "nightly" tag), so the
# image builds the pinned upstream commit. INK_VERSION is the label recorded in the index.
ARG INK_VERSION=nightly-f9aeb2b
COPY --from=builder /out/ink /usr/local/bin/ink

COPY src/ /opt/ink/src/
COPY build.sh benchmark_config.json /opt/ink/src/
