# Tagging Strategy

## Image Naming

Images follow the pattern `ghcr.io/rover-labx/claudetainer-<variant>:<tag>`.

| Image | Description |
|-------|-------------|
| `claudetainer-base` | Base image (Debian slim, Claude Code, entrypoint) |
| `claudetainer-java-node` | Java 21 + Node 24.12.0 |

## Tag Types

### `latest`

Floating tag, updated on every push to `main`. Always points to the most recent build.

```
ghcr.io/rover-labx/claudetainer-base:latest
ghcr.io/rover-labx/claudetainer-java-node:latest
```

### Tool stack (variant images only)

Encodes the major versions of installed runtimes. Floating — updated on every build with the same tool versions.

```
ghcr.io/rover-labx/claudetainer-java-node:java21-node24
```

### Version (on `v*` tag only)

Immutable semver tag, created when a git tag like `v1.0.0` is pushed.

```
ghcr.io/rover-labx/claudetainer-base:1.0.0
ghcr.io/rover-labx/claudetainer-java-node:1.0.0
ghcr.io/rover-labx/claudetainer-java-node:java21-node24-1.0.0
```

### Commit SHA

Short commit hash for traceability. Immutable — each build produces a unique SHA tag.

```
ghcr.io/rover-labx/claudetainer-base:sha-a14638f
ghcr.io/rover-labx/claudetainer-java-node:sha-a14638f
```

## Full Tag Matrix

| Trigger | Tags produced |
|---------|---------------|
| Push `v1.0.0` tag | `latest`, `sha-<commit>`, tool stack, `1.0.0`, tool stack + `1.0.0` |

Images are only pushed to the registry on `v*` tag pushes. Pushes to `main` only validate the build.

### Example for `java-node` on tag `v1.0.0` at commit `a14638f`

```
ghcr.io/rover-labx/claudetainer-java-node:latest
ghcr.io/rover-labx/claudetainer-java-node:java21-node24
ghcr.io/rover-labx/claudetainer-java-node:1.0.0
ghcr.io/rover-labx/claudetainer-java-node:java21-node24-1.0.0
ghcr.io/rover-labx/claudetainer-java-node:sha-a14638f
```

## Which Tag to Use

| Use case | Recommended tag |
|----------|----------------|
| Always get the latest build | `latest` |
| Pin to a specific tool stack | `java21-node24` |
| Pin to an exact release | `java21-node24-1.0.0` or `1.0.0` |
| Trace back to a specific commit | `sha-a14638f` |

## When Tool Versions Change

- **Tool upgrade** (e.g. Node 24 → 26): new tool stack tag `java21-node26` is created, old `java21-node24` stops receiving updates
- **Logic change** (same tools): bump the project version. The tool stack tag floats forward, the versioned tag (`java21-node24-1.1.0`) is immutable
- **Tool added**: create a new image variant (e.g. `claudetainer-java-node-maven`) rather than silently changing what an existing image contains
