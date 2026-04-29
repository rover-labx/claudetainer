#!/usr/bin/env bash
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Load credentials from Docker secret files (if not already in env) ---
for secret_name in ANTHROPIC_API_KEY CLAUDE_CODE_OAUTH_TOKEN GITHUB_APP_ID GITHUB_APP_PRIVATE_KEY GITHUB_APP_INSTALLATION_ID; do
  if [[ -z "${!secret_name:-}" ]]; then
    secret_file="/run/secrets/$(echo "$secret_name" | tr '[:upper:]' '[:lower:]')"
    if [[ -f "$secret_file" ]]; then
      val=$(cat "$secret_file")
      export "$secret_name=$val"
    fi
  fi
done

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
# stream-json emits one JSON event per line as each action happens
# (tool calls, text responses, tool results), giving real-time visibility.
echo "Launching Claude Code..."
claude --dangerously-skip-permissions ${CLAUDE_MODEL:+--model "$CLAUDE_MODEL"} \
  --output-format stream-json --verbose -p "$PROMPT" | log-formatter.sh
exit "${PIPESTATUS[0]}"
