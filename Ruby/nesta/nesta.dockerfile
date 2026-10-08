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
 && apt-get -yqq install --no-install-recommends ruby ruby-dev zlib1g-dev libffi-dev libyaml-dev \
 && rm -rf /var/lib/apt/lists/* \
 && gem install bundler --no-document

WORKDIR /opt/nesta/src

COPY Gemfile Gemfile.lock /opt/nesta/src/
ENV BUNDLE_FROZEN=true
RUN bundle install

COPY src/ /opt/nesta/src/
COPY build.sh benchmark_config.json /opt/nesta/src/
