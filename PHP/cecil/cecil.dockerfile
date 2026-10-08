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

# PHP 8.3 from the Ubuntu 24.04 archive (Cecil 9.9.1 requires PHP ^8.3 || ^8.4 || ^8.5)
RUN apt-get -yqq update \
 && apt-get -yqq install --no-install-recommends php8.3-cli php8.3-mbstring php8.3-xml php8.3-curl php8.3-zip php8.3-gd php8.3-intl unzip \
 && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2.8 /usr/bin/composer /usr/local/bin/composer

WORKDIR /opt/cecil/src

COPY composer.json composer.lock /opt/cecil/src/
RUN composer install --no-interaction --no-progress

COPY src/ /opt/cecil/src/
COPY build.sh benchmark_config.json /opt/cecil/src/
