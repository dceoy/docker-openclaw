ARG OPENCLAW_NODE_VERSION=22
FROM node:${OPENCLAW_NODE_VERSION}-bookworm-slim

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive
ARG OPENCLAW_VERSION=latest
ARG OPENCLAW_DOCKER_APT_PACKAGES=""
ARG OPENCLAW_INSTALL_BROWSER=""
ARG OPENCLAW_INSTALL_DOCKER_CLI=""
ARG OPENCLAW_DOCKER_GPG_FINGERPRINT="9DC858229FC7DD38854AE2D88D81803C0EBFCD88"

ENV HOME=/home/node \
    TERM=xterm-256color \
    NODE_ENV=production \
    PNPM_HOME=/pnpm \
    PNPM_STORE_DIR=/pnpm/store \
    PATH=/pnpm:$PATH

LABEL org.opencontainers.image.source="https://github.com/openclaw/openclaw" \
  org.opencontainers.image.url="https://openclaw.ai" \
  org.opencontainers.image.documentation="https://docs.openclaw.ai/install/docker" \
  org.opencontainers.image.licenses="MIT" \
  org.opencontainers.image.title="OpenClaw" \
  org.opencontainers.image.description="OpenClaw gateway and CLI runtime container image"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates curl git hostname jq openssl procps ripgrep tini && \
    rm -rf /var/lib/apt/lists/*

RUN install -d -m 0755 "$PNPM_HOME" "$PNPM_STORE_DIR" /home/node/.openclaw/workspace && \
    corepack enable && \
    corepack prepare pnpm@latest --activate

RUN pnpm config set store-dir "$PNPM_STORE_DIR" && \
    pnpm add -g "openclaw@${OPENCLAW_VERSION}" && \
    pnpm store prune && \
    chmod -R a+rX "$PNPM_HOME"

RUN if [ -n "$OPENCLAW_DOCKER_APT_PACKAGES" ]; then \
      apt-get update && \
      apt-get install -y --no-install-recommends $OPENCLAW_DOCKER_APT_PACKAGES && \
      rm -rf /var/lib/apt/lists/*; \
    fi

RUN if [ -n "$OPENCLAW_INSTALL_BROWSER" ]; then \
      apt-get update && \
      apt-get install -y --no-install-recommends \
        chromium chromium-sandbox fonts-liberation xvfb && \
      rm -rf /var/lib/apt/lists/*; \
    fi

RUN if [ -n "$OPENCLAW_INSTALL_DOCKER_CLI" ]; then \
      apt-get update && \
      apt-get install -y --no-install-recommends ca-certificates curl gnupg && \
      install -m 0755 -d /etc/apt/keyrings && \
      curl -fsSL https://download.docker.com/linux/debian/gpg -o /tmp/docker.gpg.asc && \
      expected_fingerprint="$(printf '%s' "$OPENCLAW_DOCKER_GPG_FINGERPRINT" | tr '[:lower:]' '[:upper:]' | tr -d '[:space:]')" && \
      actual_fingerprint="$(gpg --batch --show-keys --with-colons /tmp/docker.gpg.asc | awk -F: '$1 == "fpr" { print toupper($10); exit }')" && \
      if [ -z "$actual_fingerprint" ] || [ "$actual_fingerprint" != "$expected_fingerprint" ]; then \
        echo "ERROR: Docker repository GPG fingerprint mismatch (expected $expected_fingerprint, got ${actual_fingerprint:-<empty>})" >&2; \
        exit 1; \
      fi && \
      gpg --dearmor -o /etc/apt/keyrings/docker.gpg /tmp/docker.gpg.asc && \
      rm -f /tmp/docker.gpg.asc && \
      chmod a+r /etc/apt/keyrings/docker.gpg && \
      printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable\n' \
        "$(dpkg --print-architecture)" > /etc/apt/sources.list.d/docker.list && \
      apt-get update && \
      apt-get install -y --no-install-recommends docker-ce-cli docker-compose-plugin && \
      rm -rf /var/lib/apt/lists/*; \
    fi

ENV CHROME_PATH=/usr/bin/chromium \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

RUN chown -R node:node /home/node && \
    ln -sf /pnpm/openclaw /usr/local/bin/openclaw

USER node
WORKDIR /home/node/.openclaw/workspace

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD openclaw --version >/dev/null || exit 1

ENTRYPOINT ["/usr/bin/tini", "--", "openclaw"]
