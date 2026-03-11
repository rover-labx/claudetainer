# Commit Conventions

## Format

```
<scope> (<type>): <description>
```

## Scopes

| Scope | Description |
|-------|-------------|
| `core` | Project-wide files (.dockerignore, root configs) |
| `base` | Base Docker image (Dockerfile, system deps, Claude Code install) |
| `java-node` | Java-Node variant image |
| `scripts` | Entrypoint, GitHub auth, and shared scripts |
| `docs` | Documentation, plans, conventions |
| `ci` | CI/CD pipelines, GitHub Actions |

## Types

| Type | Description |
|------|-------------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `refactor` | Code restructuring without behavior change |
| `docs` | Documentation updates |
| `build` | Build configuration, dependencies, CI/CD |

## Guidelines

- Keep the description concise (< 72 characters)
- Use imperative mood ("Add feature" not "Added feature")
- Lowercase description (no capital after colon)
- No period at the end

## Examples

```
scripts (feat): add GitHub App JWT token generation
base (fix): pin Claude Code installer to specific version
java-node (build): upgrade Node to 24.12.0
docs (docs): update commit conventions for claudetainer
scripts (refactor): extract auth logic from entrypoint
ci (feat): add multi-variant build workflow
```

## Multi-line Commits

For complex changes, add a blank line and bullet points:

```
scripts (feat): add GitHub App authentication support

- Generate JWT from app ID and private key
- Exchange JWT for installation access token
- Fall back to GITHUB_TOKEN if app vars not set
```
