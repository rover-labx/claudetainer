#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
REGISTRY="${REGISTRY:-claudetainer}"
TAG="${TAG:-latest}"

# Images in dependency order (base must be built first)
IMAGES=(
  base
  java-node
)

for image in "${IMAGES[@]}"; do
  echo "==> Building ${REGISTRY}/${image}:${TAG}"
  docker build \
    -t "${REGISTRY}/${image}:${TAG}" \
    -f "${REPO_ROOT}/images/${image}/Dockerfile" \
    "${REPO_ROOT}"
  echo "==> Done: ${REGISTRY}/${image}:${TAG}"
  echo
done

echo "All images built successfully."
