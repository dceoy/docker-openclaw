variable "CLAWDBOT_VERSION" {
  default = "latest"
}

variable "CLAWDBOT_NODE_VERSION" {
  default = "22"
}

variable "CLAWDBOT_IMAGE" {
  default = "clawdbot"
}

variable "CLAWDBOT_DOCKER_APT_PACKAGES" {
  default = ""
}

group "default" {
  targets = ["clawdbot"]
}

group "all" {
  targets = ["clawdbot", "clawdbot-sandbox", "clawdbot-browser"]
}

target "clawdbot" {
  context = "."
  dockerfile = "Dockerfile"
  target = "clawdbot"
  platforms = ["linux/amd64", "linux/arm64"]
  args = {
    NODE_VERSION = "${CLAWDBOT_NODE_VERSION}"
    CLAWDBOT_VERSION = "${CLAWDBOT_VERSION}"
  }
  tags = ["${CLAWDBOT_IMAGE}:${CLAWDBOT_VERSION}"]
}

target "clawdbot-sandbox" {
  context = "."
  dockerfile = "Dockerfile"
  target = "clawdbot-sandbox"
  platforms = ["linux/amd64", "linux/arm64"]
  args = {
    NODE_VERSION = "${CLAWDBOT_NODE_VERSION}"
    CLAWDBOT_VERSION = "${CLAWDBOT_VERSION}"
    CLAWDBOT_DOCKER_APT_PACKAGES = "${CLAWDBOT_DOCKER_APT_PACKAGES}"
  }
  tags = ["${CLAWDBOT_IMAGE}:${CLAWDBOT_VERSION}-sandbox"]
}

target "clawdbot-browser" {
  context = "."
  dockerfile = "Dockerfile"
  target = "clawdbot-browser"
  platforms = ["linux/amd64", "linux/arm64"]
  args = {
    NODE_VERSION = "${CLAWDBOT_NODE_VERSION}"
    CLAWDBOT_VERSION = "${CLAWDBOT_VERSION}"
  }
  tags = ["${CLAWDBOT_IMAGE}:${CLAWDBOT_VERSION}-browser"]
}
