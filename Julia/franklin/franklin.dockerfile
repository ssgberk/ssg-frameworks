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

# Julia official release tarball, pinned (amd64 and arm64).
ARG JULIA_VERSION=1.13.1
RUN ARCH="$(dpkg --print-architecture)" \
 && case "$ARCH" in amd64) JARCH=x64; JFILE=x86_64 ;; arm64) JARCH=aarch64; JFILE=aarch64 ;; *) echo "unsupported $ARCH"; exit 1 ;; esac \
 && JMINOR="${JULIA_VERSION%.*}" \
 && mkdir -p /opt/julia \
 && curl -fsSL "https://julialang-s3.julialang.org/bin/linux/${JARCH}/${JMINOR}/julia-${JULIA_VERSION}-linux-${JFILE}.tar.gz" \
    | tar -xz -C /opt/julia --strip-components=1 \
 && ln -s /opt/julia/bin/julia /usr/local/bin/julia && julia --version

# The depot (packages and precompile caches) stays in the image, like node_modules.
ENV JULIA_DEPOT_PATH=/opt/julia-depot
ENV JULIA_PKG_PRECOMPILE_AUTO=0
ENV JULIA_PKG_SERVER=
ENV JULIA_PKG_OFFLINE=true

WORKDIR /opt/franklin/src

# Franklin.jl pinned through Project.toml + Manifest.toml; this ARG records the version.
ARG FRANKLIN_VERSION=0.10.97
COPY src/Project.toml src/Manifest.toml /opt/franklin/src/
RUN JULIA_PKG_OFFLINE=false JULIA_PKG_SERVER=https://pkg.julialang.org julia --project -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()' \
 && julia --project -e 'using Franklin'

COPY src/ /opt/franklin/src/
COPY build.sh benchmark_config.json /opt/franklin/src/
