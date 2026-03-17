# CI/CD

## Overview

Images are built with [Docker Bake](https://docs.docker.com/build/bake/) and pushed to [GitHub Container Registry](https://ghcr.io) (`ghcr.io`).

Build definitions (targets, tags, dependencies, labels) live in `docker-bake.hcl`. GitHub Actions workflows orchestrate CI/CD.

## Workflows

```
.github/workflows/
  build.yml          - Build validation: builds all images without pushing (PR + main)
  release.yml        - Release: builds and pushes to ghcr.io
  build-images.yml   - Reusable workflow called by both
```

### Build

- **Trigger**: pull request against `main` and push to `main`
- **What it does**: builds all images using `docker buildx bake` to validate Dockerfiles and scripts compile correctly
- **Push**: no
- **Multi-arch**: no (native only, saves CI time)

### Release

- **Trigger**: `v*` tag push only
- **What it does**: builds all images for `linux/amd64` and `linux/arm64`, pushes to `ghcr.io`
- **Push**: yes
- **Auth**: `GITHUB_TOKEN` with `packages: write` (provided automatically by GitHub Actions)

### Build Images (reusable)

Shared workflow used by both `build.yml` and `release.yml`. Accepts a `push` boolean input that controls:
- Whether to log into `ghcr.io`
- Whether to set up QEMU (needed for cross-compilation)
- Whether to push images or just build them
- Whether to build multi-arch (`linux/amd64,linux/arm64`) or native only

## Docker Bake

All build configuration is in `docker-bake.hcl`:

```bash
# Build all images locally
docker buildx bake --load

# Build a single target
docker buildx bake base --load

# Preview resolved tags and config
docker buildx bake --print
```

### Targets

| Target | Dockerfile | Description |
|--------|-----------|-------------|
| `base` | `images/base/Dockerfile` | Debian slim + Claude Code + entrypoint |
| `java-node` | `images/java-node/Dockerfile` | Base + Java 21 + Node 24.12.0 |

### Dependencies

`java-node` depends on `base` via Bake's `contexts` mechanism. Bake resolves this automatically — it builds `base` first and feeds its output to `java-node`. No manual ordering needed.

### Variables

| Variable | Default | CI override | Description |
|----------|---------|-------------|-------------|
| `REGISTRY` | `ghcr.io/rover-labx` | `ghcr.io/${{ github.repository_owner }}` | Registry prefix for image tags |
| `VERSION` | `""` (empty) | Extracted from `v*` git tag | Semver version (e.g. `1.0.0`) |
| `SHA` | `""` (empty) | Short commit SHA | Commit hash for traceability |

## Registry

Images are pushed to GitHub Container Registry under the `rover-labx` organization:

- `ghcr.io/rover-labx/claudetainer-base`
- `ghcr.io/rover-labx/claudetainer-java-node`

Packages inherit visibility and access from the source repository. OCI labels (`org.opencontainers.image.source`) link packages to the repo automatically.
