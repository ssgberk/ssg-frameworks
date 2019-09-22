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

# Generator Dir
RUN mkdir /opt/jekyll
COPY . /opt/jekyll/
COPY build.sh benchmark_config.json /opt/jekyll/src/
WORKDIR /opt/jekyll/src

# Install Jekyll
RUN gem install bundle
RUN gem install jekyll

# Clean Installl
RUN apt-get -yqq clean  \
  && apt-get -yqq purge \
  && apt-get -yqq --purge autoremove  \
  && rm -rf /var/lib/apt/lists/*
