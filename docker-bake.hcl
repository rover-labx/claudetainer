variable "REGISTRY" {
  default = "ghcr.io/rover-labx"
}

variable "VERSION" {
  default = ""
}

variable "SHA" {
  default = ""
}

group "default" {
  targets = ["base", "java-node"]
}

target "_common" {
  context = "."
}

target "base" {
  inherits   = ["_common"]
  dockerfile = "images/base/Dockerfile"
  tags = concat(
    ["${REGISTRY}/claudetainer-base:latest"],
    VERSION != "" ? ["${REGISTRY}/claudetainer-base:${VERSION}"] : [],
    SHA != "" ? ["${REGISTRY}/claudetainer-base:sha-${SHA}"] : []
  )
}

target "java-node" {
  inherits   = ["_common"]
  dockerfile = "images/java-node/Dockerfile"
  contexts = {
    "base" = "target:base"
  }
  args = {
    BASE_IMAGE = "base"
  }
  tags = concat(
    [
      "${REGISTRY}/claudetainer-java-node:latest",
      "${REGISTRY}/claudetainer-java-node:java21-node24",
    ],
    VERSION != "" ? [
      "${REGISTRY}/claudetainer-java-node:${VERSION}",
      "${REGISTRY}/claudetainer-java-node:java21-node24-${VERSION}",
    ] : [],
    SHA != "" ? ["${REGISTRY}/claudetainer-java-node:sha-${SHA}"] : []
  )
}
