ARG BASE_IMAGE=claudetainer/base:latest
FROM ${BASE_IMAGE}

USER root

# Install Eclipse Temurin JDK 21
RUN curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor -o /usr/share/keyrings/adoptium.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb bookworm main" > /etc/apt/sources.list.d/adoptium.list && \
    apt-get update && apt-get install -y --no-install-recommends temurin-21-jdk && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Node.js 24.12.0 (ships with npm 11.6.2)
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then NODE_ARCH="x64"; elif [ "$ARCH" = "arm64" ]; then NODE_ARCH="arm64"; else echo "Unsupported arch: $ARCH" && exit 1; fi && \
    curl -fsSL "https://nodejs.org/dist/v24.12.0/node-v24.12.0-linux-${NODE_ARCH}.tar.xz" | tar -xJ -C /usr/local --strip-components=1 && \
    node --version && npm --version

USER claude

WORKDIR /workspace
