# docker-openclaw

Dockerfile for [OpenClaw](https://github.com/openclaw/openclaw)

## Features

- Multi-stage Dockerfile with optimized builds
- Multiple image variants:
  - `openclaw` - Standard image for running the gateway
  - `openclaw-sandbox` - Sandbox image with optional additional packages
  - `openclaw-browser` - Browser-enabled image with Chromium for automation
- Docker Compose configuration with service profiles
- Support for multiple platforms (linux/amd64, linux/arm64)

## Prerequisites

- Docker Engine 20.10+
- Docker Compose v2.0+

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

3. Edit `.env` and configure your credentials:

   ```bash
   # Required for Claude integration
   CLAUDE_AI_SESSION_KEY=your_session_key
   CLAUDE_WEB_SESSION_KEY=your_web_session_key
   CLAUDE_WEB_COOKIE=your_cookie
   ```

4. Create necessary directories:

   ```bash
   mkdir -p .openclaw workspace
   ```

5. Start the gateway service:

   ```bash
   docker compose up -d openclaw-gateway
   ```

## Usage

### Running the Gateway

Start the gateway service:

```bash
docker compose up -d openclaw-gateway
```

The gateway will be available at:

- HTTP: `http://localhost:18789`
- WebSocket: `ws://localhost:18790`

### Running the CLI

Start an interactive CLI session:

```bash
docker compose run --rm openclaw-cli
```

Or use the onboarding wizard:

```bash
docker compose run --rm openclaw-cli openclaw onboard
```

### Running with Browser Support

For browser automation features:

```bash
docker compose --profile browser up -d openclaw-browser
```

### Running the Sandbox

For isolated sandbox execution:

```bash
docker compose --profile sandbox up -d openclaw-sandbox
```

## Building Images

### Build the standard image

```bash
docker compose build openclaw-gateway
```

### Build with Docker Buildx Bake

Build the default gateway image:

```bash
docker buildx bake
```

Build all images (gateway, sandbox, browser):

```bash
docker buildx bake all
```

Override versions with environment variables:

```bash
OPENCLAW_VERSION=1.0.0 OPENCLAW_NODE_VERSION=22 docker buildx bake all
```

### Build all images

```bash
docker compose --profile cli --profile sandbox --profile browser build
```

### Build with specific version

```bash
OPENCLAW_VERSION=1.0.0 docker compose build openclaw-gateway
```

### Build with additional packages (sandbox)

```bash
OPENCLAW_DOCKER_APT_PACKAGES="python3 python3-pip" docker compose --profile sandbox build openclaw-sandbox
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENCLAW_VERSION` | `latest` | OpenClaw version to install |
| `OPENCLAW_NODE_VERSION` | `22` | Node.js version |
| `OPENCLAW_IMAGE` | `openclaw` | Docker image name |
| `OPENCLAW_CONFIG_DIR` | `./.openclaw` | Configuration directory |
| `OPENCLAW_WORKSPACE_DIR` | `./workspace` | Workspace directory |
| `OPENCLAW_GATEWAY_PORT` | `18789` | Gateway HTTP port |
| `OPENCLAW_GATEWAY_WS_PORT` | `18790` | Gateway WebSocket port |
| `CLAUDE_AI_SESSION_KEY` | - | Claude AI session key |
| `CLAUDE_WEB_SESSION_KEY` | - | Claude web session key |
| `CLAUDE_WEB_COOKIE` | - | Claude web cookie |
| `OPENAI_API_KEY` | - | OpenAI API key (optional) |
| `ANTHROPIC_API_KEY` | - | Anthropic API key (optional) |
| `ELEVENLABS_API_KEY` | - | ElevenLabs API key (optional) |

### Volume Mounts

| Container Path | Description |
|----------------|-------------|
| `/home/node/.openclaw` | OpenClaw configuration and data |
| `/workspace` | Working directory for projects |

## Services

| Service | Profile | Description |
|---------|---------|-------------|
| `openclaw-gateway` | (default) | Main gateway service |
| `openclaw-cli` | `cli` | Interactive CLI |
| `openclaw-sandbox` | `sandbox` | Sandbox execution environment |
| `openclaw-browser` | `browser` | Browser automation support |

## License

[MIT](LICENSE)

## References

- [OpenClaw](https://github.com/openclaw/openclaw)
- [devcontainer-ai-coder](https://github.com/dceoy/devcontainer-ai-coder)
