variable "OPENCLAW_VERSION" {
  default = ""
}

variable "CLAWDBOT_VERSION" {
  default = "latest"
}

variable "OPENCLAW_NODE_VERSION" {
  default = ""
}

variable "CLAWDBOT_NODE_VERSION" {
  default = "22"
}

variable "OPENCLAW_IMAGE" {
  default = ""
}

variable "CLAWDBOT_IMAGE" {
  default = "openclaw"
}

variable "OPENCLAW_DOCKER_APT_PACKAGES" {
  default = ""
}

variable "CLAWDBOT_DOCKER_APT_PACKAGES" {
  default = ""
}

group "default" {
  targets = ["openclaw"]
}

group "all" {
  targets = ["openclaw", "openclaw-sandbox", "openclaw-browser"]
}

target "openclaw" {
  context = "."
  dockerfile = "Dockerfile"
  target = "openclaw"
  platforms = ["linux/amd64", "linux/arm64"]
  args = {
    NODE_VERSION = "${OPENCLAW_NODE_VERSION:-${CLAWDBOT_NODE_VERSION:-22}}"
    OPENCLAW_VERSION = "${OPENCLAW_VERSION:-${CLAWDBOT_VERSION:-latest}}"
  }
  tags = ["${OPENCLAW_IMAGE:-${CLAWDBOT_IMAGE:-openclaw}}:${OPENCLAW_VERSION:-${CLAWDBOT_VERSION:-latest}}"]
}

target "openclaw-sandbox" {
  context = "."
  dockerfile = "Dockerfile"
  target = "openclaw-sandbox"
  platforms = ["linux/amd64", "linux/arm64"]
  args = {
    NODE_VERSION = "${OPENCLAW_NODE_VERSION:-${CLAWDBOT_NODE_VERSION:-22}}"
    OPENCLAW_VERSION = "${OPENCLAW_VERSION:-${CLAWDBOT_VERSION:-latest}}"
    OPENCLAW_DOCKER_APT_PACKAGES = "${OPENCLAW_DOCKER_APT_PACKAGES:-${CLAWDBOT_DOCKER_APT_PACKAGES:-}}"
  }
  tags = ["${OPENCLAW_IMAGE:-${CLAWDBOT_IMAGE:-openclaw}}:${OPENCLAW_VERSION:-${CLAWDBOT_VERSION:-latest}}-sandbox"]
}

target "openclaw-browser" {
  context = "."
  dockerfile = "Dockerfile"
  target = "openclaw-browser"
  platforms = ["linux/amd64", "linux/arm64"]
  args = {
    NODE_VERSION = "${OPENCLAW_NODE_VERSION:-${CLAWDBOT_NODE_VERSION:-22}}"
    OPENCLAW_VERSION = "${OPENCLAW_VERSION:-${CLAWDBOT_VERSION:-latest}}"
  }
  tags = ["${OPENCLAW_IMAGE:-${CLAWDBOT_IMAGE:-openclaw}}:${OPENCLAW_VERSION:-${CLAWDBOT_VERSION:-latest}}-browser"]
}
