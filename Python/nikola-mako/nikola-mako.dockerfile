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
RUN mkdir /opt/nikola
COPY . ./opt/nikola/
COPY build.sh benchmark_config.json /opt/nikola/src/
WORKDIR /opt/nikola/src

# Instaling Nikola
RUN pip3 install -U pip setuptools wheel
RUN pip3 install opentimestamps-client yuicompressor Nikola[Extras]

# Clean Installl
RUN apt-get -yqq clean  \
  && apt-get -yqq purge \
  && apt-get -yqq --purge autoremove  \
  && rm -rf /var/lib/apt/lists/*
