# syntax=docker/dockerfile:1.10
ARG OPENCLAW_NODE_VERSION=22
FROM node:${OPENCLAW_NODE_VERSION}-bookworm-slim AS base

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ENV \
  DEBIAN_FRONTEND=noninteractive \
  TERM=xterm-256color \
  NODE_ENV=production

LABEL \
  org.opencontainers.image.source="https://github.com/openclaw/openclaw" \
  org.opencontainers.image.url="https://openclaw.ai" \
  org.opencontainers.image.documentation="https://docs.openclaw.ai/install/docker" \
  org.opencontainers.image.licenses="MIT" \
  org.opencontainers.image.title="OpenClaw" \
  org.opencontainers.image.description="OpenClaw gateway and CLI runtime container image"

# Preserve downloaded apt artifacts in BuildKit cache mounts across rebuilds.
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
        ca-certificates curl git hostname jq openssl procps ripgrep tini

FROM base AS openclaw-installer

ARG OPENCLAW_VERSION=latest

ENV \
  PNPM_HOME=/opt/pnpm \
  PNPM_STORE_DIR=/opt/pnpm/store \
  PATH=/opt/pnpm:${PATH}

RUN \
      install -d -m 0755 "${PNPM_HOME}" "${PNPM_STORE_DIR}" \
      && corepack enable \
      && corepack prepare pnpm@latest --activate

RUN \
      --mount=type=cache,id=openclaw-pnpm-store,target=/opt/pnpm/store \
      pnpm add -g --store-dir "${PNPM_STORE_DIR}" --package-import-method=copy \
      "openclaw@${OPENCLAW_VERSION}" \
      && chmod -R a+rX "${PNPM_HOME}"

FROM base AS runtime

ARG USER_NAME='claw'
ARG USER_UID=1001
ARG USER_GID=1001
ARG OPENCLAW_DOCKER_APT_PACKAGES=''
ARG OPENCLAW_INSTALL_BROWSER=''
ARG OPENCLAW_INSTALL_DOCKER_CLI=''
ARG OPENCLAW_DOCKER_GPG_FINGERPRINT='9DC858229FC7DD38854AE2D88D81803C0EBFCD88'

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ENV \
  DEBIAN_FRONTEND=noninteractive \
  PNPM_HOME=/opt/pnpm \
  PNPM_STORE_DIR=/opt/pnpm/store \
  PATH=/opt/pnpm:${PATH} \
  HOME=/home/${USER_NAME} \
  CHROME_PATH=/usr/bin/chromium \
  PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
  PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

# hadolint ignore=DL3008
RUN \
      --mount=type=cache,id=openclaw-apt-cache,target=/var/cache/apt,sharing=locked \
      --mount=type=cache,id=openclaw-apt-lib,target=/var/lib/apt,sharing=locked \
      if [[ -n "${OPENCLAW_DOCKER_APT_PACKAGES}" ]]; then \
        apt-get -yqq update \
        && apt-get -yqq install --no-install-recommends --no-install-suggests ${OPENCLAW_DOCKER_APT_PACKAGES}; \
      fi

# hadolint ignore=DL3008
RUN \
      --mount=type=cache,id=openclaw-apt-cache,target=/var/cache/apt,sharing=locked \
      --mount=type=cache,id=openclaw-apt-lib,target=/var/lib/apt,sharing=locked \
      if [[ -n "${OPENCLAW_INSTALL_BROWSER}" ]]; then \
        apt-get -yqq update \
        && apt-get -yqq install --no-install-recommends --no-install-suggests \
          chromium chromium-sandbox fonts-liberation xvfb; \
      fi

# hadolint ignore=DL3008
RUN \
      --mount=type=cache,id=openclaw-apt-cache,target=/var/cache/apt,sharing=locked \
      --mount=type=cache,id=openclaw-apt-lib,target=/var/lib/apt,sharing=locked \
      if [[ -n "${OPENCLAW_INSTALL_DOCKER_CLI}" ]]; then \
        apt-get -yqq update \
        && apt-get -yqq install --no-install-recommends --no-install-suggests gnupg \
        && install -m 0755 -d /etc/apt/keyrings \
        && curl -fsSL 'https://download.docker.com/linux/debian/gpg' -o /tmp/docker.gpg.asc \
        && expected_fingerprint="$(printf '%s' "${OPENCLAW_DOCKER_GPG_FINGERPRINT}" | tr '[:lower:]' '[:upper:]' | tr -d '[:space:]')" \
        && actual_fingerprint="$(gpg --batch --show-keys --with-colons /tmp/docker.gpg.asc | awk -F: '$1 == "fpr" { print toupper($10); exit }')" \
        && if [[ -z "$actual_fingerprint" ]] \
          || [[ "$actual_fingerprint" != "$expected_fingerprint" ]]; then \
          echo "ERROR: Docker repository GPG fingerprint mismatch (expected $expected_fingerprint, got ${actual_fingerprint:-<empty>})" >&2; \
          exit 1; \
        fi \
        && gpg --dearmor -o /etc/apt/keyrings/docker.gpg /tmp/docker.gpg.asc \
        && rm -f /tmp/docker.gpg.asc \
        && chmod a+r /etc/apt/keyrings/docker.gpg \
        && printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable\n' \
          "$(dpkg --print-architecture)" > /etc/apt/sources.list.d/docker.list \
        && apt-get -yqq update \
        && apt-get -yqq install --no-install-recommends --no-install-suggests docker-ce-cli docker-compose-plugin; \
      fi

COPY --from=openclaw-installer /opt/pnpm /opt/pnpm

RUN \
      if [[ "${USER_NAME}" == 'node' ]]; then \
        groupmod --gid "${USER_GID}" node \
        && usermod --uid "${USER_UID}" --gid "${USER_GID}" node; \
      else \
        groupmod --gid "${USER_GID}" --new-name "${USER_NAME}" node \
        && usermod --uid "${USER_UID}" --gid "${USER_GID}" --home "${HOME}" --login "${USER_NAME}" --move-home node; \
      fi \
      && install -d -m 0755 -o "${USER_UID}" -g "${USER_GID}" "${HOME}/.openclaw/workspace" \
      && chown -R "${USER_UID}:${USER_GID}" "${HOME}" \
      && ln -sf "${PNPM_HOME}/openclaw" /usr/local/bin/openclaw

USER ${USER_NAME}
WORKDIR ${HOME}/.openclaw/workspace

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD openclaw --version >/dev/null \
    || exit 1

ENTRYPOINT ["/usr/bin/tini", "--", "openclaw"]
