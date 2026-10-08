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
 && apt-get -yqq install --no-install-recommends openjdk-21-jre-headless unzip \
 && rm -rf /var/lib/apt/lists/* \
 && java -version

WORKDIR /opt/jbake/src

ARG JBAKE_VERSION=2.7.0
RUN curl -fsSL -o /tmp/jbake.zip \
      "https://github.com/jbake-org/jbake/releases/download/v${JBAKE_VERSION}/jbake-${JBAKE_VERSION}-bin.zip" \
 && unzip -q /tmp/jbake.zip -d /opt && rm /tmp/jbake.zip \
 && ln -s "/opt/jbake-${JBAKE_VERSION}-bin/bin/jbake" /usr/local/bin/jbake \
 && jbake -h >/dev/null

COPY src/ /opt/jbake/src/
COPY build.sh benchmark_config.json /opt/jbake/src/
