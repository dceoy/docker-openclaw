# syntax=docker/dockerfile:1.10
ARG OPENCLAW_NODE_VERSION=24
FROM node:${OPENCLAW_NODE_VERSION}-bookworm-slim AS runtime

ARG USER_NAME='agent'
ARG USER_UID=1001
ARG USER_GID=1001

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ENV \
  DEBIAN_FRONTEND=noninteractive \
  TERM=xterm-256color \
  NODE_ENV=production \
  OPENCLAW_APP_DIR=/opt/oc \
  PATH=/opt/oc/node_modules/.bin:${PATH} \
  CHROME_PATH=/usr/bin/chromium \
  PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
  PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

RUN \
      rm -f /etc/apt/apt.conf.d/docker-clean \
      && printf 'Binary::apt::APT::Keep-Downloaded-Packages "true";\n' \
        > /etc/apt/apt.conf.d/keep-cache

# hadolint ignore=DL3008
RUN \
      --mount=type=cache,id=openclaw-apt-cache,target=/var/cache/apt,sharing=locked \
      --mount=type=cache,id=openclaw-apt-lib,target=/var/lib/apt,sharing=locked \
      apt-get -yqq update \
      && apt-get -yqq install --no-install-recommends --no-install-suggests \
        ca-certificates chromium chromium-sandbox curl fonts-liberation git \
        hostname jq openssl procps ripgrep tini xvfb

WORKDIR ${OPENCLAW_APP_DIR}

RUN \
      --mount=type=bind,source=.,target=/mnt/host \
      cp -a /mnt/host/package.json /mnt/host/pnpm-lock.yaml .

RUN \
      --mount=type=cache,id=openclaw-pnpm-store,target=/pnpm/store \
      corepack pnpm install --prod --frozen-lockfile --package-import-method=copy \
        --store-dir /pnpm/store \
      && chmod -R a+rX "${OPENCLAW_APP_DIR}"

RUN \
      if [[ "${USER_NAME}" == 'node' ]]; then \
        groupmod --gid "${USER_GID}" node \
        && usermod --uid "${USER_UID}" --gid "${USER_GID}" node; \
      else \
        groupmod --gid "${USER_GID}" --new-name "${USER_NAME}" node \
        && usermod --uid "${USER_UID}" --gid "${USER_GID}" --home "/home/${USER_NAME}" --login "${USER_NAME}" --move-home node; \
      fi \
      && install -d -m 0755 -o "${USER_UID}" -g "${USER_GID}" "/home/${USER_NAME}/.openclaw/workspace" \
      && chown -R "${USER_UID}:${USER_GID}" "/home/${USER_NAME}" \
      && ln -sf "${OPENCLAW_APP_DIR}/node_modules/openclaw/openclaw.mjs" /usr/local/bin/openclaw

ENV HOME=/home/${USER_NAME}

USER ${USER_NAME}
WORKDIR ${HOME}/.openclaw/workspace

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD openclaw --version >/dev/null \
    || exit 1

ENTRYPOINT ["/usr/bin/tini", "--", "openclaw"]
