# Repository Guidelines

## Commands

### Development Setup

- `docker compose build` builds the shared `openclaw` image from `Dockerfile`.
- `docker buildx bake` builds the default multi-platform target defined in `compose.yml`.
- `docker compose up -d --build openclaw-gateway` rebuilds and starts the long-running gateway service.
- `docker compose run --rm openclaw-cli` starts an interactive CLI container that shares the gateway network namespace.
- `docker compose run --rm openclaw-cli onboard` runs onboarding flows inside the CLI container.
- `docker compose run --rm openclaw-cli dashboard --no-open` runs the dashboard without trying to open a browser on the host.
- `docker build -t openclaw:local .` performs a direct image build without Compose or Bake.

### Code Quality and Documentation

**Important**: Run these before committing or opening a PR when you change docs, Docker config, or CI automation.

1. **format and lint**: Use `local-qa` skill.
2. **Documentation update**: If behavior or configuration changes, update `README.md`, `.env.example`, and related guidance in the same change.

## Architecture

### Runtime Model

- This repository is intentionally small and Docker-centric. It packages the published [`openclaw`](https://www.npmjs.com/package/openclaw) npm package into a shared image used by the gateway and CLI Compose services.
- `openclaw-gateway` is the long-running service that publishes the HTTP and bridge/WebSocket endpoints.
- `openclaw-cli` is an ephemeral CLI container that shares the gateway network namespace for onboarding, dashboard, and agent workflows.
- `.openclaw/` and `workspace/` are bind-mounted local state directories and should not be treated as committed source.

### Key Dependencies

- Docker Compose drives the local runtime workflow, and `docker buildx bake` is the supported multi-platform build entry point.
- The published `openclaw` package is installed during image build with `pnpm`; this repository does not vendor the application source tree.
- Optional browser automation and Docker-backed sandbox tooling are enabled with build args rather than separate images.

### Repository Layout

- `Dockerfile`: Builds the runtime image on `node:<ver>-bookworm-slim`, installs the published package with `pnpm`, and optionally adds Chromium/Xvfb or Docker CLI tooling through `OPENCLAW_...` build args.
- `compose.yml`: Source of truth for local defaults and `docker buildx bake`; defines shared anchors plus `openclaw-gateway` and `openclaw-cli`.
- `.env.example`: Template for build args, ports, bind mounts, gateway auth, browser tuning, and provider credentials.

## Quality Standards

- Dockerfile instructions stay uppercase and should be grouped into explicit multi-line `RUN` blocks.
- Optimize cache usage with `--mount=type=cache` for package manager caches and build dependencies in Dockerfile.
- Use multi-stage builds to keep the final image minimal and focused on runtime dependencies in Dockerfile.
- Keep repository-specific build args and environment variables prefixed with `OPENCLAW_`.

## Security & Configuration Tips

- Never commit API keys, tokens, `.env`, `.openclaw/`, or `workspace/` contents.
- Provide secrets through environment variables at runtime instead of baking them into image layers.
- Keep `OPENCLAW_GATEWAY_TOKEN`, `CLAUDE_*` session credentials, and provider API keys such as `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, `OPENROUTER_API_KEY`, and `ELEVENLABS_API_KEY` local-only.
- Do not enable Docker socket access unless you explicitly need Docker-backed sandboxing.

## Commit & Pull Request Guidelines

- Run QA checks using `local-qa` skill before committing or creating a PR.
- Branch names use appropriate prefixes on creation (e.g., `feature/...`, `bugfix/...`, `refactor/...`, `docs/...`, `chore/...`).
- When instructed to create a PR, create it as a draft with appropriate labels by default.

## Code Design Principles

Always prefer the simplest design that works.

- **KISS**: Choose straightforward solutions and avoid unnecessary abstraction.
- **DRY**: Remove duplication when it improves clarity and maintainability.
- **YAGNI**: Do not add features, hooks, or flexibility until they are needed.
- **SOLID/Clean Code**: Apply these as tools, only when they keep the design simpler and easier to change.

## Development Methodology

Keep delivery incremental, test-backed, and easy to review.

- Make small, safe, reversible changes.
- Prefer `Red -> Green -> Refactor`.
- Do not mix feature work and refactoring in the same commit.
- Refactor when it improves clarity or removes real duplication (Rule of Three).
- Keep tests fast, focused, and self-validating.
