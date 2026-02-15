variable "OPENCLAW_VERSION" {
  default = "latest"
}

variable "OPENCLAW_NODE_VERSION" {
  default = "22"
}

variable "OPENCLAW_IMAGE" {
  default = "openclaw"
}

variable "OPENCLAW_DOCKER_APT_PACKAGES" {
  default = ""
}

group "default" {
  targets = ["openclaw"]
}

group "all" {
  targets = ["openclaw", "openclaw-sandbox", "openclaw-browser"]
}

target "openclaw" {
  context    = "."
  dockerfile = "Dockerfile"
  target     = "openclaw"
  platforms  = ["linux/amd64", "linux/arm64"]
  args = {
    NODE_VERSION     = "${OPENCLAW_NODE_VERSION}"
    OPENCLAW_VERSION = "${OPENCLAW_VERSION}"
  }
  tags = ["${OPENCLAW_IMAGE}:${OPENCLAW_VERSION}"]
}

target "openclaw-sandbox" {
  context    = "."
  dockerfile = "Dockerfile"
  target     = "openclaw-sandbox"
  platforms  = ["linux/amd64", "linux/arm64"]
  args = {
    NODE_VERSION                 = "${OPENCLAW_NODE_VERSION}"
    OPENCLAW_VERSION             = "${OPENCLAW_VERSION}"
    OPENCLAW_DOCKER_APT_PACKAGES = "${OPENCLAW_DOCKER_APT_PACKAGES}"
  }
  tags = ["${OPENCLAW_IMAGE}:${OPENCLAW_VERSION}-sandbox"]
}

target "openclaw-browser" {
  context    = "."
  dockerfile = "Dockerfile"
  target     = "openclaw-browser"
  platforms  = ["linux/amd64", "linux/arm64"]
  args = {
    NODE_VERSION     = "${OPENCLAW_NODE_VERSION}"
    OPENCLAW_VERSION = "${OPENCLAW_VERSION}"
  }
  tags = ["${OPENCLAW_IMAGE}:${OPENCLAW_VERSION}-browser"]
}
