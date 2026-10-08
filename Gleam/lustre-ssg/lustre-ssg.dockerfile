# Official Gleam image: Gleam + Erlang/OTP 29 (Debian trixie), amd64 and arm64.
FROM ghcr.io/gleam-lang/gleam:v1.19.1-erlang-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG HYPERFINE_VERSION=1.20.0
# Pinned in src/gleam.toml and src/manifest.toml; repeated here so the version is machine-readable.
ARG LUSTRE_SSG_VERSION=0.11.0
LABEL org.ssgberk.lustre-ssg.version=$LUSTRE_SSG_VERSION

RUN apt-get -yqq update \
 && apt-get -yqq install --no-install-recommends \
      bash ca-certificates curl jq \
 && rm -rf /var/lib/apt/lists/*

RUN ARCH="$(dpkg --print-architecture)" \
 && curl -fsSL -o /tmp/hyperfine.deb \
      "https://github.com/sharkdp/hyperfine/releases/download/v${HYPERFINE_VERSION}/hyperfine_${HYPERFINE_VERSION}_${ARCH}.deb" \
 && dpkg -i /tmp/hyperfine.deb && rm /tmp/hyperfine.deb

WORKDIR /opt/lustre-ssg/src

# Dependencies are fetched and the project compiled once, untimed, at image build;
# the timed `gleam run -m build` then runs offline against build/ (incremental no-op compile check).
COPY src/ /opt/lustre-ssg/src/
RUN gleam deps download && gleam build && gleam --version
COPY build.sh benchmark_config.json /opt/lustre-ssg/src/
