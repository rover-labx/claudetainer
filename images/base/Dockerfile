FROM debian:bookworm-slim

# Install system dependencies in a single layer with cleanup
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        curl \
        jq \
        openssl \
        ca-certificates \
        gnupg && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Claude Code standalone binary
RUN curl -fsSL https://claude.ai/install.sh | sh

# Create non-root user
RUN useradd -m -s /bin/bash claude

# Copy scripts from build context (repo root)
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY scripts/github-auth.sh /usr/local/bin/github-auth.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/github-auth.sh

# Create workspace directory
RUN mkdir -p /workspace && chown claude:claude /workspace

# Switch to non-root user
USER claude

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
