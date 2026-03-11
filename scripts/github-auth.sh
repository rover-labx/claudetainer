#!/usr/bin/env bash
set -euo pipefail

# GitHub App Auth Script
# Resolves a GitHub token by one of two methods:
#   1. If GITHUB_TOKEN is already set, echo it and exit.
#   2. If GitHub App credentials are set, generate a JWT and exchange it
#      for an installation token via the GitHub API.

# --- Helper: base64url encode (stdin) ---
base64url() {
  openssl base64 -A | tr '+/' '-_' | tr -d '='
}

# 1. If GITHUB_TOKEN is already available, use it directly.
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  echo "${GITHUB_TOKEN}"
  exit 0
fi

# 2. If GitHub App credentials are available, mint an installation token.
if [[ -n "${GITHUB_APP_ID:-}" && -n "${GITHUB_APP_PRIVATE_KEY:-}" && -n "${GITHUB_APP_INSTALLATION_ID:-}" ]]; then
  now=$(date +%s)
  iat=$((now - 60))
  exp=$((now + 600))

  # JWT header and payload
  header='{"alg":"RS256","typ":"JWT"}'
  payload="{\"iat\":${iat},\"exp\":${exp},\"iss\":\"${GITHUB_APP_ID}\"}"

  header_b64=$(printf '%s' "${header}" | base64url)
  payload_b64=$(printf '%s' "${payload}" | base64url)

  # Sign with the app's private key
  unsigned="${header_b64}.${payload_b64}"
  signature=$(printf '%s' "${unsigned}" \
    | openssl dgst -sha256 -sign <(printf '%s' "${GITHUB_APP_PRIVATE_KEY}") \
    | base64url)

  jwt="${unsigned}.${signature}"

  # Exchange JWT for an installation token
  response=$(curl -s -X POST \
    -H "Authorization: Bearer ${jwt}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/app/installations/${GITHUB_APP_INSTALLATION_ID}/access_tokens")

  token=$(echo "${response}" | jq -r '.token')

  if [[ -z "${token}" || "${token}" == "null" ]]; then
    echo "Error: failed to obtain installation token. API response:" >&2
    echo "${response}" >&2
    exit 1
  fi

  echo "${token}"
  exit 0
fi

# 3. No credentials available.
echo "Error: no GitHub credentials found. Set GITHUB_TOKEN or GITHUB_APP_ID, GITHUB_APP_PRIVATE_KEY, and GITHUB_APP_INSTALLATION_ID." >&2
exit 1
