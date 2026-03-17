# Claudetainer

Docker images for autonomous Claude Code execution on GitHub repositories.

## Project Structure

```
images/base/Dockerfile       - Base image: Debian slim + Claude Code standalone
images/java-node/Dockerfile  - Variant: Java 21 + Node 24.12.0
scripts/entrypoint.sh        - Shared entrypoint: auth, clone, branch, run
scripts/github-auth.sh       - GitHub App token generation (JWT + installation token)
docker-bake.hcl              - Docker Bake build definitions (targets, tags, dependencies)
.github/workflows/           - CI/CD: build.yml (PR), release.yml (push), build-images.yml (reusable)
```

## Building

Images are built with [Docker Bake](https://docs.docker.com/build/bake/). Targets and tags are defined in `docker-bake.hcl`.

```bash
docker buildx bake --load        # Build all images
docker buildx bake base --load   # Build a single target
docker buildx bake --print       # Preview resolved tags
```

## Architecture

- **Base image** (`claudetainer/base`): Debian bookworm-slim, system deps (git, curl, jq, openssl, xz-utils), Claude Code standalone binary, non-root `claude` user, entrypoint scripts.
- **Variant images** extend base with language runtimes. They `FROM claudetainer/base:latest`, switch to `USER root` for installs, then back to `USER claude`.
- **Entrypoint** handles: env validation (requires `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN`), GitHub auth (App or token), git clone, branch checkout/creation, Claude Code launch with `--dangerously-skip-permissions`.
- Claude Code handles git operations (commit, push) via prompt or project CLAUDE.md instructions.

## Conventions

- Commit format: `<scope> (<type>): <description>` (see `docs/commit-conventions.md`)
- Multi-arch support: Node.js downloads detect amd64/arm64 via `dpkg --print-architecture`
- Image naming: `ghcr.io/rover-labx/claudetainer-<variant>:<tag>`
