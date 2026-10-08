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

WORKDIR /opt/zine/src

ARG ZINE_VERSION=0.14.0
RUN ARCH="$(dpkg --print-architecture)" \
 && case "$ARCH" in \
      amd64) MARCH=x86_64;  SHA=897642f46c3872a6311f2ab3d4c622f5f8625bfee8e1de2d0de42597c1385629 ;; \
      arm64) MARCH=aarch64; SHA=cfb670abd5ca85a02e0cb9c6db57c36ed3c55a768b054727242d3243e7eceafa ;; \
      *) echo "unsupported $ARCH"; exit 1 ;; \
    esac \
 && curl -fsSL -o /tmp/zine.tar.xz \
      "https://github.com/kristoff-it/zine/releases/download/v${ZINE_VERSION}/${MARCH}-linux-musl.tar.xz" \
 && echo "${SHA}  /tmp/zine.tar.xz" | sha256sum -c - \
 && tar -xJf /tmp/zine.tar.xz -C /usr/local/bin zine && rm /tmp/zine.tar.xz && zine version

COPY src/ /opt/zine/src/
COPY build.sh benchmark_config.json /opt/zine/src/
