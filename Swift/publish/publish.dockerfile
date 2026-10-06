# Builder stage: Swift toolchain (large) compiles the site generator; only the binary leaves this stage.
FROM ubuntu:24.04 AS builder

ARG DEBIAN_FRONTEND=noninteractive
ARG SWIFT_VERSION=6.4.0
ARG PUBLISH_VERSION=0.9.0

RUN apt-get -yqq update \
 && apt-get -yqq install --no-install-recommends \
      binutils ca-certificates curl git libc6-dev libcurl4-openssl-dev libedit2 libgcc-13-dev \
      libpython3-dev libsqlite3-0 libstdc++-13-dev libxml2-dev libncurses-dev libz3-dev \
      pkg-config tzdata zlib1g-dev gnupg2 \
 && rm -rf /var/lib/apt/lists/*

RUN ARCH="$(dpkg --print-architecture)" \
 && case "$ARCH" in amd64) P=ubuntu2404; S=ubuntu24.04 ;; arm64) P=ubuntu2404-aarch64; S=ubuntu24.04-aarch64 ;; *) echo "unsupported $ARCH"; exit 1 ;; esac \
 && curl -fsSL "https://download.swift.org/swift-${SWIFT_VERSION}-release/${P}/swift-${SWIFT_VERSION}-RELEASE/swift-${SWIFT_VERSION}-RELEASE-${S}.tar.gz" \
    | tar -xz --strip-components=2 -C /usr \
 && swift --version

WORKDIR /opt/publish/src
COPY src/Package.swift src/Package.resolved* /opt/publish/src/
COPY src/Sources/ /opt/publish/src/Sources/
RUN grep -q "exact: \"${PUBLISH_VERSION}\"" Package.swift \
 && swift build -c release \
 && cp -L .build/release/SSGBerk /tmp/SSGBerk \
 && cp Package.resolved /tmp/Package.resolved \
 && mkdir /tmp/swiftlibs && cp -a /usr/lib/swift/linux/*.so* /tmp/swiftlibs/

# Runtime stage: no toolchain, only what the timed build needs.
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG HYPERFINE_VERSION=1.20.0

RUN apt-get -yqq update \
 && apt-get -yqq install --no-install-recommends \
      build-essential ca-certificates curl git jq moreutils tree wget xz-utils tzdata \
 && rm -rf /var/lib/apt/lists/*

RUN ARCH="$(dpkg --print-architecture)" \
 && curl -fsSL -o /tmp/hyperfine.deb \
      "https://github.com/sharkdp/hyperfine/releases/download/v${HYPERFINE_VERSION}/hyperfine_${HYPERFINE_VERSION}_${ARCH}.deb" \
 && dpkg -i /tmp/hyperfine.deb && rm /tmp/hyperfine.deb

WORKDIR /opt/publish/src

# Publish locates the project root from the compile-time path of main.swift, so the
# layout (Package.swift, Sources/, Content/, Resources/) and the path match the builder stage.
COPY src/ /opt/publish/src/
# Static stdlib linking fails on 6.4 (ICU symbols), so ship the Swift runtime shared libraries only.
COPY --from=builder /tmp/swiftlibs/ /usr/lib/swift/linux/
COPY --from=builder /tmp/SSGBerk /opt/publish/src/.build/release/SSGBerk
COPY build.sh benchmark_config.json /opt/publish/src/
