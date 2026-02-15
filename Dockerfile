# syntax=docker/dockerfile:1
ARG NODE_VERSION=22

FROM ubuntu:24.04 AS builder

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive
ARG NODE_VERSION

RUN \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get -yqq update \
    && apt-get -yqq upgrade \
    && apt-get -yqq install --no-install-recommends --no-install-suggests \
      ca-certificates curl gnupg

RUN \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
      | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION}.x nodistro main" \
      | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get -yqq update \
    && apt-get -yqq install --no-install-recommends --no-install-suggests \
      nodejs

RUN \
    corepack enable \
    && npm install -g npm@latest pnpm@latest


FROM ubuntu:24.04 AS base

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

ENV HOME=/home/node \
    TERM=xterm-256color \
    NODE_ENV=production

COPY --from=builder /etc/apt/keyrings /etc/apt/keyrings
COPY --from=builder /etc/apt/sources.list.d /etc/apt/sources.list.d
COPY --from=builder /usr/lib/node_modules /usr/lib/node_modules
COPY --from=builder /usr/bin/node /usr/bin/node
COPY --from=builder /usr/bin/npm /usr/bin/npm
COPY --from=builder /usr/bin/npx /usr/bin/npx
COPY --from=builder /usr/bin/corepack /usr/bin/corepack

RUN \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get -yqq update \
    && apt-get -yqq upgrade \
    && apt-get -yqq install --no-install-recommends --no-install-suggests \
      ca-certificates curl gh git jq procps ripgrep tini \
    && apt-get -yqq autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN \
    useradd -m -s /bin/bash -d /home/node node \
    && mkdir -p /home/node/.openclaw /workspace \
    && chown -R node:node /home/node /workspace


FROM base AS openclaw-runtime

ARG OPENCLAW_VERSION=latest

RUN \
    npm install -g "openclaw@${OPENCLAW_VERSION}" \
    && npm cache clean --force

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD openclaw --version >/dev/null || exit 1


FROM openclaw-runtime AS openclaw

USER node
WORKDIR /workspace

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["openclaw", "gateway"]


FROM openclaw-runtime AS openclaw-sandbox

ARG OPENCLAW_DOCKER_APT_PACKAGES=""

RUN \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    if [ -n "${OPENCLAW_DOCKER_APT_PACKAGES}" ]; then \
      apt-get -yqq update \
      && apt-get -yqq install --no-install-recommends --no-install-suggests \
        ${OPENCLAW_DOCKER_APT_PACKAGES}; \
    fi

USER node
WORKDIR /workspace

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["openclaw", "gateway"]


FROM openclaw-runtime AS openclaw-browser

RUN \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get -yqq update \
    && apt-get -yqq install --no-install-recommends --no-install-suggests \
      chromium chromium-sandbox fonts-liberation \
      libasound2t64 libatk-bridge2.0-0t64 libatk1.0-0t64 libatspi2.0-0t64 \
      libcups2t64 libdbus-1-3 libdrm2 libgbm1 libgtk-3-0t64 \
      libnspr4 libnss3 libwayland-client0 libxcomposite1 \
      libxdamage1 libxfixes3 libxkbcommon0 libxrandr2 xdg-utils

ENV CHROME_PATH=/usr/bin/chromium \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

USER node
WORKDIR /workspace

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["openclaw", "gateway"]
