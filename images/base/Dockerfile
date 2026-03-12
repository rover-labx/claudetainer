FROM debian:bookworm-slim

# Install system dependencies in a single layer with cleanup
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        curl \
        jq \
        openssl \
        ca-certificates \
        gnupg \
        xz-utils && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Claude Code standalone binary and make it available system-wide
RUN curl -fsSL https://claude.ai/install.sh | bash && \
    mv /root/.local/share/claude/versions/* /usr/local/bin/claude && \
    chmod +x /usr/local/bin/claude && \
    rm -rf /root/.local

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
