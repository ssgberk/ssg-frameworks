FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive

# Update then install needed programs
RUN apt-get -yqq update && \
  apt-get -yqq upgrade && \
  apt-get -yqq install \
  software-properties-common build-essential patch coreutils \
  make gcc g++ zlib1g-dev git wget curl jq tree moreutils \
  python python3 python3-pip ruby ruby-dev

# Instaling Hyperfine
RUN wget https://github.com/sharkdp/hyperfine/releases/download/v1.7.0/hyperfine_1.7.0_amd64.deb \
  && dpkg -i hyperfine_1.7.0_amd64.deb \
  && rm hyperfine_1.7.0_amd64.deb

# Generator Dir
RUN mkdir /opt/jigsaw
COPY . /opt/jigsaw/
COPY build.sh benchmark_config.json /opt/jigsaw/src/
WORKDIR /opt/jigsaw/src

# Instaling Node
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && /|RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
  && apt-get install -y nodejs \
  && npm install -g yarn

# Install PHP
RUN apt-add-repository ppa:ondrej/php --yes \
  && apt update -qq \
  && apt-get -y install \
      php7.1 \
      php7.1-cgi \
      php7.1-cli \
      php7.1-common \
      php7.1-curl \
      php7.1-dev \
      php7.1-gd \
      php7.1-gmp \
      php7.1-json \
      php7.1-ldap \
      php7.1-mysql \
      php7.1-odbc \
      php7.1-opcache \
      php7.1-pspell \
      php7.1-readline \
      php7.1-sqlite3 \
      php7.1-tidy \
      php7.1-xmlrpc \
      php7.1-xsl \
      php7.1-fpm \
      php7.1-intl \
      php7.1-mcrypt \
      php7.1-mbstring \
      php7.1-zip \
      php-xdebug

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer creates=/usr/local/bin/composer
RUN php /usr/local/bin/composer global require "fxp/composer-asset-plugin:~1.1.1" \
  && php /usr/local/bin/composer global require "hirak/prestissimo:^0.3"

# node-sass gets built from source (??) so we need the build-base package
RUN php /usr/local/bin/composer global require "tightenco/jigsaw" && \
	composer clear-cache && \
	npm install -g npm && \
	npm cache clean --force

ENV PATH="/root/.composer/vendor/tightenco/jigsaw:${PATH}"

# Clean Installl
RUN apt-get -yqq clean  \
  && apt-get -yqq purge \
  && apt-get -yqq --purge autoremove  \
  && rm -rf /var/lib/apt/lists/*
