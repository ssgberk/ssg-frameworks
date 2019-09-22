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
RUN mkdir /opt/hugo
COPY . /opt/hugo/
COPY build.sh benchmark_config.json /opt/hugo/src/
WORKDIR /opt/hugo/src

# Install Hugo
RUN wget https://github.com/gohugoio/hugo/releases/download/v0.58.2/hugo_0.58.2_Linux-64bit.deb \
  && dpkg -i hugo_0.58.2_Linux-64bit.deb \
  && rm hugo_0.58.2_Linux-64bit.deb

# Clean Installl
RUN apt-get -yqq clean  \
  && apt-get -yqq purge \
  && apt-get -yqq --purge autoremove  \
  && rm -rf /var/lib/apt/lists/*
