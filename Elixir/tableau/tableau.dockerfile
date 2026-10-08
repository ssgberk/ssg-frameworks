# Erlang/OTP 28.5.0.7 + Elixir 1.20.4 on Ubuntu 24.04 (hexpm builder image, pinned by tag; amd64 and arm64)
FROM hexpm/elixir:1.20.4-erlang-28.5.0.7-ubuntu-noble-20260917

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

ENV MIX_ENV=prod
ENV MIX_HOME=/opt/mix
ENV HEX_HOME=/opt/hex
RUN mix local.hex --force && mix local.rebar --force

WORKDIR /opt/tableau/src

# Deps are fetched and compiled in the image, so the timed build runs offline.
ARG TABLEAU_VERSION=0.30.0
COPY src/mix.exs src/mix.lock /opt/tableau/src/
RUN grep -q "\"== ${TABLEAU_VERSION}\"" mix.exs
COPY src/config/ /opt/tableau/src/config/
RUN mix deps.get --only prod && mix deps.compile

COPY src/ /opt/tableau/src/
RUN mix compile
COPY build.sh benchmark_config.json /opt/tableau/src/
