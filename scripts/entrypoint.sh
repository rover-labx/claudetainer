#!/usr/bin/env bash
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Load secrets from /run/secrets/ ---
# All sensitive values are injected via docker compose secrets and mounted as
# files at /run/secrets/<name>. We read them here and export as env vars so
# downstream tools (github-auth.sh, claude) can consume them.
read_secret() {
  local name="$1"
  local file="/run/secrets/${name}"
  if [[ -f "$file" ]]; then
    cat "$file"
  fi
}

export ANTHROPIC_API_KEY="$(read_secret anthropic_api_key)"
export CLAUDE_CODE_OAUTH_TOKEN="$(read_secret claude_code_oauth_token)"
export GITHUB_TOKEN="$(read_secret github_token)"
export GITHUB_APP_ID="$(read_secret github_app_id)"
export GITHUB_APP_PRIVATE_KEY="$(read_secret github_app_private_key)"
export GITHUB_APP_INSTALLATION_ID="$(read_secret github_app_installation_id)"

# --- Validate required secrets ---
if [[ -z "${ANTHROPIC_API_KEY}" && -z "${CLAUDE_CODE_OAUTH_TOKEN}" ]]; then
  echo "Error: anthropic_api_key or claude_code_oauth_token secret is required but neither is present at /run/secrets/." >&2
  exit 1
fi

if [[ -z "${GITHUB_REPOSITORY:-}" ]]; then
  echo "Error: GITHUB_REPOSITORY is required but not set." >&2
  exit 1
fi

# --- Resolve GitHub auth ---
echo "Resolving GitHub authentication..."
TOKEN=$("${SCRIPTS_DIR}/github-auth.sh")

# --- Configure git ---
echo "Configuring git..."
git config --global credential.helper '!f() { echo "password=${TOKEN}"; }; f'
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
exec claude --dangerously-skip-permissions -p "$PROMPT"
