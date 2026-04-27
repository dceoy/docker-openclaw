# docker-openclaw

Docker wrapper files for running the published
[`openclaw`](https://www.npmjs.com/package/openclaw) package in containers.

The root `Dockerfile` now uses a cache-aware multi-stage build: one stage
installs the published package from the committed `package.json` and
`pnpm-lock.yaml`, and the final runtime stage copies only the installed runtime
artifacts into the image.

## Features

- Multi-stage Docker build for a leaner runtime image
- BuildKit cache mounts for `apt` and `pnpm` to speed rebuilds
- `pnpm`-based installation of the published `openclaw` package pinned in `package.json`
- Configurable runtime user name, UID, and GID
- Root-context Docker builds that do not read from `./openclaw`
- Shared image for `openclaw-gateway` and `openclaw-cli`
- Optional browser and Docker CLI support via build args
- Multi-platform `docker buildx bake` target

## Prerequisites

- Docker Engine 20.10+
- Docker Compose v2+

## Quick Start

1. Clone this repository:

   ```bash
   git clone https://github.com/dceoy/docker-openclaw.git
   cd docker-openclaw
   ```

2. Copy the example environment file:

   ```bash
   cp .env.example .env
   ```

3. Edit `.env` and set the values you need. In most cases you will want at least:

   ```bash
   OPENCLAW_GATEWAY_TOKEN=change-me-to-a-long-random-token
   ANTHROPIC_API_KEY=...
   ```

4. Create the host directories used by bind mounts:

   ```bash
   mkdir -p .openclaw workspace
   ```

5. Build and start the gateway:

   ```bash
   docker compose up -d --build openclaw-gateway
   ```

6. Run onboarding or other CLI flows as needed:

   ```bash
   docker compose run --rm openclaw-cli onboard
   ```

## Usage

### Run the gateway

```bash
docker compose up -d openclaw-gateway
```

Default endpoints:

- HTTP: `http://127.0.0.1:18789`
- Bridge/WebSocket: `ws://127.0.0.1:18790`

The published bind mode is controlled by `OPENCLAW_GATEWAY_BIND` and should use
OpenClaw bind values such as `lan` or `loopback`.

### Run the CLI

```bash
docker compose run --rm openclaw-cli
docker compose run --rm openclaw-cli onboard
docker compose run --rm openclaw-cli dashboard --no-open
docker compose run -T --rm openclaw-cli devices list --json
```

### Enable browser automation support

Set `OPENCLAW_INSTALL_BROWSER=1` in `.env`, then rebuild:

```bash
docker compose build
docker compose up -d openclaw-gateway
```

### Enable Docker CLI support for sandboxing

Set `OPENCLAW_INSTALL_DOCKER_CLI=1` in `.env`, rebuild the image, and mount the
host Docker socket into the container if you want Docker-backed agent sandboxing.
The root Compose file does not mount the socket by default.

## Building Images

### Build with Docker Compose

```bash
docker compose build
```

### Build with Docker Buildx Bake

```bash
docker buildx bake
```

`docker buildx bake` now reads the build definition directly from `compose.yml`.
The default bake target is `openclaw-gateway`, so no separate `docker-bake.hcl`
file is required.

### Build directly with `docker build`

```bash
DOCKER_BUILDKIT=1 docker build -t openclaw:local .
```

### Update the OpenClaw version

Use `pnpm` to update the pinned dependency, then rebuild the image:

```bash
corepack pnpm add --save-exact openclaw@<version>
docker compose build
```

Example overrides:

```bash
OPENCLAW_NODE_VERSION=22 docker buildx bake
OPENCLAW_USER_NAME=developer docker buildx bake
OPENCLAW_INSTALL_BROWSER=1 docker buildx bake
```

The Dockerfile relies on BuildKit cache mounts. `docker compose build` and
`docker buildx bake` already use BuildKit; set `DOCKER_BUILDKIT=1` for plain
`docker build` if your Docker installation doesn't enable it by default.

For direct `docker build` usage, pass the runtime-user build args explicitly
when needed:

```bash
DOCKER_BUILDKIT=1 docker build \
  --build-arg USER_NAME=developer \
  --build-arg USER_UID=1001 \
  --build-arg USER_GID=1001 \
  -t openclaw:local .
```

## Configuration

### Core variables

| Variable                             | Default          | Description                                             |
| ------------------------------------ | ---------------- | ------------------------------------------------------- |
| `OPENCLAW_IMAGE`                     | `openclaw:local` | Image name and tag used by Compose and Bake             |
| `OPENCLAW_NODE_VERSION`              | `22`             | Node.js major version used for the base image           |
| `OPENCLAW_USER_NAME`                 | `claw`           | Runtime username passed to Docker build arg `USER_NAME` |
| `OPENCLAW_USER_UID`                  | `1001`           | Runtime UID passed to Docker build arg `USER_UID`       |
| `OPENCLAW_USER_GID`                  | `1001`           | Runtime GID passed to Docker build arg `USER_GID`       |
| `OPENCLAW_DOCKER_APT_PACKAGES`       | -                | Extra apt packages added to the runtime image           |
| `OPENCLAW_INSTALL_BROWSER`           | -                | Set to `1` to install Chromium + Xvfb                   |
| `OPENCLAW_INSTALL_DOCKER_CLI`        | -                | Set to `1` to add Docker CLI support                    |
| `OPENCLAW_CONFIG_DIR`                | `./.openclaw`    | Host path mounted to `/home/<user>/.openclaw`           |
| `OPENCLAW_WORKSPACE_DIR`             | `./workspace`    | Host path mounted to `/home/<user>/.openclaw/workspace` |
| `OPENCLAW_GATEWAY_BIND`              | `lan`            | Gateway bind mode passed to OpenClaw                    |
| `OPENCLAW_GATEWAY_PORT`              | `18789`          | Published HTTP port                                     |
| `OPENCLAW_BRIDGE_PORT`               | `18790`          | Published bridge/WebSocket port                         |
| `OPENCLAW_GATEWAY_TOKEN`             | -                | Gateway auth token                                      |
| `OPENCLAW_ALLOW_INSECURE_PRIVATE_WS` | -                | Allow trusted private-network `ws://` targets           |

The OpenClaw package version is pinned in `package.json` and resolved in
`pnpm-lock.yaml`.

### Provider passthrough

The Compose file also passes these optional provider variables through to the
containers when present in `.env`:

- `CLAUDE_AI_SESSION_KEY`
- `CLAUDE_WEB_SESSION_KEY`
- `CLAUDE_WEB_COOKIE`
- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `GEMINI_API_KEY`
- `OPENROUTER_API_KEY`
- `ELEVENLABS_API_KEY`

### Volume mounts

`<user>` resolves to `OPENCLAW_USER_NAME` and defaults to `claw`.

| Container path                     | Description                          |
| ---------------------------------- | ------------------------------------ |
| `/home/<user>/.openclaw`           | OpenClaw state, config, and sessions |
| `/home/<user>/.openclaw/workspace` | Workspace used by agents and tools   |

## Services

| Service            | Description                                                         |
| ------------------ | ------------------------------------------------------------------- |
| `openclaw-gateway` | Main gateway container                                              |
| `openclaw-cli`     | Interactive CLI container that shares the gateway network namespace |

## References

- [OpenClaw](https://github.com/openclaw/openclaw)
- [OpenClaw package on npm](https://www.npmjs.com/package/openclaw)
