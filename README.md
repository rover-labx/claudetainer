# Claudetainer

Docker images for running Claude Code autonomously on GitHub repositories.

## Images

| Image | Contents |
|---|---|
| `claudetainer/base` | Debian slim, Claude Code, git, entrypoint scripts |
| `claudetainer/java-node` | Base + Java 21 (Temurin) + Node 24.12.0 + npm 11.6.2 |

## Building

Images are built with [Docker Bake](https://docs.docker.com/build/bake/). Targets and tags are defined in `docker-bake.hcl`.

```bash
# Build all images
docker buildx bake --load

# Build a single target
docker buildx bake base --load

# Preview resolved tags without building
docker buildx bake --print
```

## Quick Start

```bash
# Run with API key + GitHub App auth
docker run --rm \
  -e ANTHROPIC_API_KEY="sk-ant-..." \
  -e GITHUB_APP_ID="12345" \
  -e GITHUB_APP_PRIVATE_KEY="$(cat key.pem)" \
  -e GITHUB_APP_INSTALLATION_ID="67890" \
  -e GITHUB_REPOSITORY="owner/repo" \
  -e GITHUB_BRANCH="feature/my-task" \
  claudetainer/java-node "Fix the failing tests in the auth module"

# Run with OAuth token (Claude Max subscription, no per-token billing)
docker run --rm \
  -e CLAUDE_CODE_OAUTH_TOKEN="sk-ant-oat01-..." \
  -e GITHUB_TOKEN="ghp_..." \
  -e GITHUB_REPOSITORY="owner/repo" \
  claudetainer/java-node "Refactor the database layer"
```

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `ANTHROPIC_API_KEY` | One of API key or OAuth token | Anthropic API key (pay-per-token billing) |
| `CLAUDE_CODE_OAUTH_TOKEN` | | OAuth token from `claude setup-token` (Claude Max subscription) |
| `GITHUB_TOKEN` | One of token or app vars | Pre-generated GitHub token |
| `GITHUB_APP_ID` | | GitHub App ID |
| `GITHUB_APP_PRIVATE_KEY` | | GitHub App private key (PEM content) |
| `GITHUB_APP_INSTALLATION_ID` | | GitHub App installation ID |
| `GITHUB_REPOSITORY` | Yes | Repository in `owner/repo` format |
| `GITHUB_BRANCH` | No | Branch to checkout or create |
| `CLAUDE_PROMPT` | No | Prompt for Claude (alternative to passing as args) |

## How It Works

1. Validates Claude auth (`ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN`)
2. Resolves GitHub authentication (GitHub App JWT exchange or direct token)
3. Configures git credentials
4. Clones the repository into `/workspace`
5. Checks out or creates the specified branch
6. Runs Claude Code with `--dangerously-skip-permissions`
7. Claude Code handles committing and pushing as instructed by the prompt or `CLAUDE.md`

### Claude Authentication

| Method | Env Var | Billing | How to get |
|---|---|---|---|
| API Key | `ANTHROPIC_API_KEY` | Pay-per-token | [console.anthropic.com](https://console.anthropic.com) |
| OAuth Token | `CLAUDE_CODE_OAUTH_TOKEN` | Claude Max subscription (fixed monthly) | Run `claude setup-token` locally |

Generate an OAuth token by running `claude setup-token` on a machine with a browser. The token is valid for ~1 year.

## Adding Variants

Create a new Dockerfile in `images/<variant>/` that extends the base:

```dockerfile
FROM claudetainer/base:latest
USER root
# Install your tools...
USER claude
WORKDIR /workspace
```
