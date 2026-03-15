# Investigation: Docker-in-Docker Support for Claudetainer

**Date**: 2026-03-15
**Status**: Concluded
**Context**: Some projects use Testcontainers (or similar tools) that require a Docker daemon during test execution. This document evaluates how Claudetainer can support this.

## Problem

Claudetainer runs Claude Code inside a Docker container. By default, there is no Docker daemon available inside the container, which means any test relying on Testcontainers will fail.

## Existing Ecosystem: Docker Sandboxes

Docker released [Docker Sandboxes](https://www.docker.com/blog/docker-sandboxes-run-claude-code-and-other-coding-agents-unsupervised-but-safely/) (January 2026), an official product for running coding agents in isolated microVM environments. It natively supports Docker-in-Docker inside the sandbox.

However, Docker Sandboxes is **not viable as a Claudetainer backend today**:

- Requires Docker Desktop (macOS/Windows only, experimental Linux via Desktop 4.57)
- No documented headless/non-interactive mode
- No Linux server support — most CI runners are headless Linux
- Focused on local developer safety, not CI/remote orchestration
- Does not handle GitHub auth, repo cloning, or branch management

Claudetainer remains the right approach for headless CI/automation use cases. Docker Sandboxes could become a complementary runtime backend if Linux/CI support is added.

## Approaches Evaluated

### 1. Docker Socket Mounting (DooD)

Mount the host's Docker socket into the container:

```bash
docker run \
  -v /var/run/docker.sock:/var/run/docker.sock \
  claudetainer/java-node:latest
```

**How it works**: The container uses the host's Docker daemon. Testcontainers spawns sibling containers on the host.

**Pros**:
- Simple to implement (install Docker CLI in image, ~50MB)
- Officially recommended by Testcontainers ("Docker Wormhole" pattern)
- Works on all CI providers with Docker support

**Cons — Security**:
- Containers spawned by Testcontainers run on the host, not inside the container
- Claude has full access to the Docker API via the socket
- Claude could escape isolation by creating a container with `-v /:/host` or `--privileged`
- This **defeats Claudetainer's isolation goal**

**Verdict**: Viable but requires additional safeguards (see mitigations below).

### 2. Privileged Docker-in-Docker (DinD)

Run a full Docker daemon inside the container with `--privileged`:

```bash
docker run --privileged claudetainer/java-node:latest
```

**How it works**: A `dockerd` process runs inside the container. Testcontainers talks to this local daemon. All spawned containers live inside the Claudetainer container.

**Pros**:
- Full isolation — spawned containers live and die with the Claudetainer container
- No orphaned containers on the host
- Clean cleanup in CI

**Cons — Security**:
- `--privileged` grants the container full access to the host kernel
- Disables seccomp, AppArmor, SELinux — all confinement mechanisms
- Allows mounting host filesystems, loading kernel modules, accessing devices
- Container escape is trivial for any process inside
- **Defeats Claudetainer's isolation goal entirely**

**Verdict**: Rejected. The security tradeoff is worse than socket mounting.

### 3. Sysbox Runtime

Use the [Sysbox](https://github.com/nestybox/sysbox) container runtime for unprivileged DinD:

```bash
docker run --runtime=sysbox-runc claudetainer/java-node:latest
```

**Pros**:
- Unprivileged DinD with strong isolation
- No `--privileged` needed
- Best security/functionality tradeoff

**Cons**:
- **Linux only** — does not work on macOS (Docker Desktop runs containers in a Linux VM, but Sysbox cannot be installed inside it)
- Requires Sysbox installed on the host
- Not available on most CI providers

**Verdict**: Not usable for macOS users. Could be documented as an option for Linux CI servers.

## Socket Mounting Mitigations

If a user opts into socket mounting, two mitigation strategies were evaluated:

### Docker Socket Proxy (Tecnativa/docker-socket-proxy)

A reverse proxy that filters Docker API calls by endpoint.

- Controls access at the URL level (e.g., allow `/containers/*`, deny `/volumes/*`)
- **Cannot inspect request bodies** — cannot block bind mounts or privileged container creation
- Claude could call `POST /containers/create` with `{"Binds": ["/:/host"]}` and the proxy would allow it

**Verdict**: Insufficient. Does not protect against the specific escape vectors.

### OPA Docker Authorization Plugin (opa-docker-authz)

A Docker Engine authorization plugin using Open Policy Agent (OPA) that inspects the full request body.

- **Can block bind mounts** to sensitive host paths (inspects `Binds`, resolves symlinks)
- **Can block privileged container creation** (inspects `HostConfig.Privileged`)
- **Can block capability escalation** (`CAP_SYS_ADMIN`, etc.)
- Allows everything Testcontainers needs (create/start/stop containers, pull images, networks)

Example Rego policy:

```rego
package docker.authz

default allow = false

allow {
    input.Method == "GET"
}

allow {
    input.Method == "POST"
    input.Path == "/containers/create"
    not input.Body.HostConfig.Privileged
    no_dangerous_binds
}

no_dangerous_binds {
    not dangerous_bind
}

dangerous_bind {
    bind := input.Body.HostConfig.Binds[_]
    startswith(bind, "/:")
}

# Container lifecycle (start, stop, kill, wait, remove)
allow {
    input.Method == "POST"
    regex.match("^/containers/[a-zA-Z0-9]+/(start|stop|kill|wait|remove)$", input.Path)
}

# Image pull (required by Testcontainers)
allow {
    input.Method == "POST"
    input.Path == "/images/create"
}

# Network create/remove (required by Testcontainers)
allow {
    input.Method == "POST"
    regex.match("^/networks(/create|/[a-zA-Z0-9]+/disconnect)?$", input.Path)
}

allow {
    input.Method == "DELETE"
    regex.match("^/networks/[a-zA-Z0-9]+$", input.Path)
}
```

**Limitation**: This is a daemon-level plugin — installed on the host's Docker Engine, not inside a container. Requires host-level configuration (`daemon.json`). Good for CI servers you control, awkward for local dev on macOS.

**Verdict**: Best mitigation available. Recommended for CI environments.

## Testcontainers Graceful Skip

When Docker is unavailable, Testcontainers tests can be **skipped instead of failed** using a built-in annotation parameter:

```java
@Testcontainers(disabledWithoutDocker = true)
class MyIntegrationTest {
    // Tests are skipped when Docker is not reachable
}
```

This is a native Testcontainers feature. Projects that already use this flag will work out of the box in Claudetainer without Docker access.

For projects that don't use this flag, Claude can be instructed to either:

- Add `disabledWithoutDocker = true` before running tests
- Exclude integration tests via build tool flags:
  - Maven: `-DexcludedGroups=integration`
  - Gradle: `test { useJUnitPlatform { excludeTags("integration") } }`

## Conclusion

### Recommended approach: layered opt-in

| Mode | Docker access | Testcontainers | Security | Setup |
|------|--------------|----------------|----------|-------|
| **Default** | None | Skipped (`disabledWithoutDocker`) | Full isolation | Nothing extra |
| **Socket mount** | Host daemon | Works | Reduced (mitigate with OPA on CI) | `-v /var/run/docker.sock` |
| **Socket mount + OPA** | Host daemon (filtered) | Works | Good (escape vectors blocked) | OPA plugin on host |

### Implementation plan

1. **Default: no Docker socket.** Safe by default. Instruct Claude to handle Testcontainers gracefully (skip or exclude).
2. **Opt-in: socket mount.** Install Docker CLI (client only) in the base image. Document the `-v /var/run/docker.sock:/var/run/docker.sock` flag and associated risks.
3. **Recommended for CI: OPA authz plugin.** Provide a ready-made Rego policy and setup guide for CI servers where the Docker daemon is under operator control.
