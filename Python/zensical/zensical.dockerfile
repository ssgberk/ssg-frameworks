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

RUN apt-get -yqq update \
 && apt-get -yqq install --no-install-recommends python3 python3-venv python3-dev \
 && rm -rf /var/lib/apt/lists/* \
 && python3 -m venv /opt/venv
ENV PATH=/opt/venv/bin:$PATH

WORKDIR /opt/zensical/src

COPY requirements.txt /opt/zensical/src/
RUN pip install --no-cache-dir -r requirements.txt && zensical --version

COPY src/ /opt/zensical/src/
COPY build.sh benchmark_config.json /opt/zensical/src/
