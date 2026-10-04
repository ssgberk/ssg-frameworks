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

RUN apt-get -yqq update && apt-get -yqq install --no-install-recommends software-properties-common gpg-agent \
 && add-apt-repository -y ppa:ondrej/php && apt-get -yqq update \
 && apt-get -yqq install --no-install-recommends php8.4-cli php8.4-mbstring php8.4-xml php8.4-curl php8.4-zip unzip \
 && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2.8 /usr/bin/composer /usr/local/bin/composer

WORKDIR /opt/jigsaw/src

COPY composer.json composer.lock /opt/jigsaw/src/
RUN composer install --no-interaction --no-progress

COPY src/ /opt/jigsaw/src/
COPY build.sh benchmark_config.json /opt/jigsaw/src/
