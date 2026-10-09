FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG HYPERFINE_VERSION=1.20.0

RUN apt-get -yqq update \
 && apt-get -yqq install --no-install-recommends \
      build-essential ca-certificates curl git jq libpcre3 moreutils tree wget xz-utils \
 && rm -rf /var/lib/apt/lists/*

RUN ARCH="$(dpkg --print-architecture)" \
 && curl -fsSL -o /tmp/hyperfine.deb \
      "https://github.com/sharkdp/hyperfine/releases/download/v${HYPERFINE_VERSION}/hyperfine_${HYPERFINE_VERSION}_${ARCH}.deb" \
 && dpkg -i /tmp/hyperfine.deb && rm /tmp/hyperfine.deb

ARG NIM_VERSION=2.2.12
RUN case "$(dpkg --print-architecture)" in amd64) NA=x64 ;; arm64) NA=arm64 ;; esac \
 && curl -fsSL "https://nim-lang.org/download/nim-${NIM_VERSION}-linux_${NA}.tar.xz" | tar -xJ -C /opt \
 && ln -s "/opt/nim-${NIM_VERSION}" /opt/nim
ENV PATH=/opt/nim/bin:/root/.nimble/bin:$PATH
ARG NIMIB_VERSION=0.4.2
# Transitive dependencies pinned to the versions nimib 0.4.2 resolved.
RUN nimble install -y fusion@1.2 jsony@1.1.6 markdown@0.8.8 parsetoml@0.7.2 \
 && nimble install -y "nimib@${NIMIB_VERSION}" && nim --version

WORKDIR /opt/nimib/src
COPY src/ /opt/nimib/src/
COPY build.sh benchmark_config.json /opt/nimib/src/
# Compiled once at image build (untimed); the timed run only executes the binary.
RUN nim c -d:release --hints:off --nimcache:/opt/nimib/nimcache -o:/opt/nimib/src/ssgrender ssgrender.nim
