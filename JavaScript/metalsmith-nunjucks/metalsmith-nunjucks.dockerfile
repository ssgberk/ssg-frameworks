FROM ubuntu:18.04

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

# Instaling Node
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && /|RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
  && apt-get install -y nodejs \
  && npm install -g yarn

# Generator Dir
RUN mkdir /opt/metalsmith
COPY . /opt/metalsmith/
COPY build.sh benchmark_config.json Makefile package.json /opt/metalsmith/src/
WORKDIR /opt/metalsmith/src

# Instaling Metalsmith
RUN yarn
RUN apt-get update && apt-get install -y lighttpd
COPY lighttpd.conf /etc/lighttpd/

# Clean Installl
RUN apt-get -yqq clean  \
  && apt-get -yqq purge \
  && apt-get -yqq --purge autoremove  \
  && rm -rf /var/lib/apt/lists/*
