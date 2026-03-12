# Claudetainer

Docker images for running Claude Code autonomously on GitHub repositories.

## Images

| Image | Contents |
|---|---|
| `claudetainer/base` | Debian slim, Claude Code, git, entrypoint scripts |
| `claudetainer/java-node` | Base + Java 21 (Temurin) + Node 24.12.0 + npm 11.6.2 |

## Quick Start

```bash
# Build
docker build -t claudetainer/base:latest -f images/base/Dockerfile .
docker build -t claudetainer/java-node:latest -f images/java-node/Dockerfile .

# Run with GitHub App auth
docker run --rm \
  -e ANTHROPIC_API_KEY="sk-ant-..." \
  -e GITHUB_APP_ID="12345" \
  -e GITHUB_APP_PRIVATE_KEY="$(cat key.pem)" \
  -e GITHUB_APP_INSTALLATION_ID="67890" \
  -e GITHUB_REPOSITORY="owner/repo" \
  -e GITHUB_BRANCH="feature/my-task" \
  claudetainer/java-node "Fix the failing tests in the auth module"

# Run with a pre-generated token
docker run --rm \
  -e ANTHROPIC_API_KEY="sk-ant-..." \
  -e GITHUB_TOKEN="ghp_..." \
  -e GITHUB_REPOSITORY="owner/repo" \
  claudetainer/java-node "Refactor the database layer"
```

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `ANTHROPIC_API_KEY` | Yes | Anthropic API key for Claude Code |
| `GITHUB_TOKEN` | One of token or app vars | Pre-generated GitHub token |
| `GITHUB_APP_ID` | | GitHub App ID |
| `GITHUB_APP_PRIVATE_KEY` | | GitHub App private key (PEM content) |
| `GITHUB_APP_INSTALLATION_ID` | | GitHub App installation ID |
| `GITHUB_REPOSITORY` | Yes | Repository in `owner/repo` format |
| `GITHUB_BRANCH` | No | Branch to checkout or create |
| `CLAUDE_PROMPT` | No | Prompt for Claude (alternative to passing as args) |

## How It Works

1. Resolves GitHub authentication (GitHub App JWT exchange or direct token)
2. Configures git credentials
3. Clones the repository into `/workspace`
4. Checks out or creates the specified branch
5. Runs Claude Code with `--dangerously-skip-permissions`
6. Claude Code handles committing and pushing as instructed by the prompt or `CLAUDE.md`

## Adding Variants

Create a new Dockerfile in `images/<variant>/` that extends the base:

```dockerfile
FROM claudetainer/base:latest
USER root
# Install your tools...
USER claude
WORKDIR /workspace
```
