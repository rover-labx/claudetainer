#!/usr/bin/env bash
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Validate required environment variables ---
if [[ -z "${ANTHROPIC_API_KEY:-}" && -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]]; then
  echo "Error: ANTHROPIC_API_KEY or CLAUDE_CODE_OAUTH_TOKEN is required but neither is set." >&2
  exit 1
fi

if [[ -z "${GITHUB_REPOSITORY:-}" ]]; then
  echo "Error: GITHUB_REPOSITORY is required but not set." >&2
  exit 1
fi

# --- Resolve GitHub auth ---
echo "Resolving GitHub authentication..."
TOKEN=$("${SCRIPTS_DIR}/github-auth.sh")

# --- Configure git and gh CLI ---
echo "Configuring git..."
git config --global credential.helper '!f() { echo "password=${TOKEN}"; }; f'
export GH_TOKEN="${TOKEN}"
git config --global user.email "claude[bot]@users.noreply.github.com"
git config --global user.name "Claude (claudetainer)"

# --- Clone repository ---
echo "Cloning ${GITHUB_REPOSITORY}..."
git clone "https://x-access-token:${TOKEN}@github.com/${GITHUB_REPOSITORY}.git" /workspace

cd /workspace

# --- Branch management ---
if [[ -n "${GITHUB_BRANCH:-}" ]]; then
  if git ls-remote --exit-code --heads origin "${GITHUB_BRANCH}" >/dev/null 2>&1; then
    echo "Checking out existing branch ${GITHUB_BRANCH}..."
    git checkout "${GITHUB_BRANCH}"
  else
    echo "Creating new branch ${GITHUB_BRANCH} from default branch..."
    git checkout -b "${GITHUB_BRANCH}"
  fi
fi

# --- Resolve prompt ---
if [[ $# -gt 0 ]]; then
  PROMPT="$*"
elif [[ -n "${CLAUDE_PROMPT:-}" ]]; then
  PROMPT="${CLAUDE_PROMPT}"
else
  echo "Error: no prompt provided. Pass arguments or set CLAUDE_PROMPT." >&2
  exit 1
fi

# --- Run Claude Code ---
echo "Launching Claude Code..."
exec claude --dangerously-skip-permissions ${CLAUDE_MODEL:+--model "$CLAUDE_MODEL"} -p "$PROMPT"
