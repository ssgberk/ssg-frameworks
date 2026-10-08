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

# Bridgetown 2.2 needs Ruby >= 3.3 (Ubuntu 24.04 ships 3.2), so Ruby is built from source.
ARG RUBY_VERSION=3.4.9
ARG RUBY_SHA256=4231c54072601a171faed1699f105985e9971c94cd382b78feb4eb44eec2dd1a
RUN apt-get -yqq update \
 && apt-get -yqq install --no-install-recommends autoconf bison libssl-dev zlib1g-dev libffi-dev libyaml-dev libreadline-dev libgmp-dev \
 && rm -rf /var/lib/apt/lists/* \
 && curl -fsSL -o /tmp/ruby.tar.xz "https://cache.ruby-lang.org/pub/ruby/3.4/ruby-${RUBY_VERSION}.tar.xz" \
 && echo "${RUBY_SHA256}  /tmp/ruby.tar.xz" | sha256sum -c - \
 && tar -xJf /tmp/ruby.tar.xz -C /tmp \
 && cd "/tmp/ruby-${RUBY_VERSION}" \
 && ./configure --disable-install-doc --enable-shared \
 && make -j"$(nproc)" && make install \
 && cd / && rm -rf /tmp/ruby.tar.xz "/tmp/ruby-${RUBY_VERSION}" \
 && ldconfig \
 && gem install bundler --no-document

WORKDIR /opt/bridgetown/site

COPY Gemfile Gemfile.lock /opt/bridgetown/site/
ENV BUNDLE_FROZEN=true
ENV BRIDGETOWN_ENV=production
RUN bundle install

COPY src/ /opt/bridgetown/site/
COPY build.sh benchmark_config.json /opt/bridgetown/site/
