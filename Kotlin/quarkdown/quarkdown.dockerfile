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

# The Linux release zip ships an x64-only JRE; the jars are platform independent,
# so use the distro JRE 17 (same major as the bundled one) on both amd64 and arm64.
RUN apt-get -yqq update \
 && apt-get -yqq install --no-install-recommends openjdk-17-jre-headless unzip \
 && rm -rf /var/lib/apt/lists/*

ARG QUARKDOWN_VERSION=2.6.3
RUN curl -fsSL -o /tmp/quarkdown.zip \
      "https://github.com/iamgio/quarkdown/releases/download/v${QUARKDOWN_VERSION}/quarkdown-linux-x64.zip" \
 && unzip -q /tmp/quarkdown.zip -d /opt \
 && rm -rf /tmp/quarkdown.zip /opt/quarkdown/runtime /opt/quarkdown/docs \
 && ln -s /opt/quarkdown/bin/quarkdown /usr/local/bin/quarkdown \
 && quarkdown --version

WORKDIR /opt/quarkdown-site/src

COPY src/ /opt/quarkdown-site/src/
COPY build.sh benchmark_config.json /opt/quarkdown-site/src/
