# Claudetainer

Docker images for autonomous Claude Code execution on GitHub repositories.

## Project Structure

```
images/base/Dockerfile       - Base image: Debian slim + Claude Code standalone
images/java-node/Dockerfile  - Variant: Java 21 + Node 24.12.0
scripts/entrypoint.sh        - Shared entrypoint: auth, clone, branch, run
scripts/github-auth.sh       - GitHub App token generation (JWT + installation token)
```

## Building

All Docker builds use the repo root as context:

```bash
docker build -t claudetainer/base:latest -f images/base/Dockerfile .
docker build -t claudetainer/java-node:latest -f images/java-node/Dockerfile .
```

## Architecture

- **Base image** (`claudetainer/base`): Debian bookworm-slim, system deps (git, curl, jq, openssl, xz-utils), Claude Code standalone binary, non-root `claude` user, entrypoint scripts.
- **Variant images** extend base with language runtimes. They `FROM claudetainer/base:latest`, switch to `USER root` for installs, then back to `USER claude`.
- **Entrypoint** handles: env validation, GitHub auth (App or token), git clone, branch checkout/creation, Claude Code launch with `--dangerously-skip-permissions`.
- Claude Code handles git operations (commit, push) via prompt or project CLAUDE.md instructions.

## Conventions

- Commit format: `<scope> (<type>): <description>` (see `docs/commit-conventions.md`)
- Multi-arch support: Node.js downloads detect amd64/arm64 via `dpkg --print-architecture`
- Image naming: `claudetainer/<variant>:<tag>`
