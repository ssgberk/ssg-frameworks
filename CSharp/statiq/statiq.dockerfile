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

# .NET SDK 10.0.401 (LTS), pinned tarball for amd64 and arm64
ARG DOTNET_SDK_VERSION=10.0.401
ENV DOTNET_ROOT=/usr/local/dotnet
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV DOTNET_NOLOGO=1
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
RUN ARCH="$(dpkg --print-architecture)" \
 && case "$ARCH" in amd64) DARCH=x64 ;; arm64) DARCH=arm64 ;; *) echo "unsupported $ARCH"; exit 1 ;; esac \
 && mkdir -p "$DOTNET_ROOT" \
 && curl -fsSL "https://builds.dotnet.microsoft.com/dotnet/Sdk/${DOTNET_SDK_VERSION}/dotnet-sdk-${DOTNET_SDK_VERSION}-linux-${DARCH}.tar.gz" \
    | tar -xz -C "$DOTNET_ROOT" \
 && ln -s "$DOTNET_ROOT/dotnet" /usr/local/bin/dotnet \
 && dotnet --version

# Statiq.Web is a NuGet library: a small console app is restored and compiled here (untimed);
# the timed build only runs the compiled app, with no restore and no network.
ARG STATIQ_VERSION=1.0.0-beta.60
ENV DOTNET_ROLL_FORWARD=Major
COPY app/ /opt/statiq/app/
RUN cd /opt/statiq/app && dotnet build -c Release -p:StatiqWebVersion=${STATIQ_VERSION} -o /opt/statiq/app/bin -p:UseAppHost=false --nologo -v q

WORKDIR /opt/statiq/src
COPY src/ /opt/statiq/src/
COPY build.sh benchmark_config.json /opt/statiq/src/
