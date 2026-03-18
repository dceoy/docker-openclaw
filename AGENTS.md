# Repository Guidelines

## Project Structure & Module Organization

This repository is intentionally small and Docker-centric. It packages the published [`openclaw`](https://www.npmjs.com/package/openclaw) npm package into a shared image used by the gateway and CLI Compose services.

- `Dockerfile`: Builds the `openclaw` runtime image on `node:<ver>-bookworm-slim`, installs the published package with `pnpm`, and optionally adds Chromium/Xvfb or Docker CLI tooling via `OPENCLAW_...` build args.
- `compose.yml`: Source of truth for local runtime defaults and `docker buildx bake`; defines shared anchors plus `openclaw-gateway` and `openclaw-cli`.
- `.env.example`: Template for build args, ports, bind mounts, gateway auth, browser tuning, and provider credentials.
- `README.md`: Primary usage and configuration documentation.
- `AGENTS.md`: Repository guidance for coding agents; `CLAUDE.md` is a symlink to this file.
- `.agents/skills/local-qa/`: Local QA skill definition and `scripts/qa.sh` for markdown formatting plus lint/security checks.
- `.github/workflows/ci.yml`: CI/CD orchestration using reusable workflows for lint/scan, image build/push, and Dependabot auto-merge.
- `.github/dependabot.yml` and `.github/renovate.json`: Dependency update automation.

Keep new files at the repo root unless they are CI/config/automation artifacts (for example `.github/...` or `.agents/...`). Treat `.openclaw/` and `workspace/` as local bind-mount data directories, not committed source.

## Build, Test, and Development Commands

Use Docker Compose for local workflows:

- `docker compose build` builds the shared image from `Dockerfile`.
- `docker buildx bake` builds the default multi-platform target from `compose.yml`.
- `docker compose up -d --build openclaw-gateway` rebuilds and starts the long-running gateway service.
- `docker compose run --rm openclaw-cli` starts an interactive CLI container that shares the gateway network namespace.
- `docker compose run --rm openclaw-cli onboard` runs onboarding flows inside the CLI container.
- `docker compose run --rm openclaw-cli dashboard --no-open` runs the dashboard without trying to open a browser on the host.
- `docker build -t openclaw:local .` builds directly without Compose or Bake.
- `cd .agents/skills/local-qa && ./scripts/qa.sh` runs markdown formatting plus workflow and security checks.

Before opening a PR, at minimum run a fresh build and one container smoke test.

## Coding Style & Naming Conventions

- YAML uses 2-space indentation and lowercase keys.
- Dockerfile instructions are uppercase and grouped into explicit multi-line `RUN` blocks.
- Prefer explicit shell safety (`bash -euo pipefail`) and deterministic install steps.
- Keep build args and related configuration names prefixed with `OPENCLAW_`.
- Keep filenames lowercase and use descriptive, tool-oriented names.

## Testing Guidelines

There is no unit-test framework in this repo. Validation is operational:

- Local: run `docker compose build`, at least one `docker compose run --rm openclaw-cli ...` smoke test, and `.agents/skills/local-qa/scripts/qa.sh` when you touch docs or CI/docker config.
- CI:
  - `docker-lint-and-scan` runs on pushes and pull requests to `main`, and via `workflow_dispatch` when `workflow=lint-and-scan`.
  - `docker-build-and-push` runs only via `workflow_dispatch` when `workflow=build`.
  - `dependabot-auto-merge` runs on Dependabot pull requests.

If behavior changes, include exact verification commands and outcomes in the PR description.

## Commit & Pull Request Guidelines

Follow the existing history's style: concise, imperative summaries, optionally with a conventional prefix when it helps scope (example: `chore: update Dockerfile and CI build config`).

PRs should include:

- What changed and why.
- Any related issue link.
- Local validation commands executed.
- Screenshots only when container output or UI behavior would benefit from them.

## Security & Configuration Tips

Never commit API keys, tokens, `.env`, `.openclaw/`, or workspace contents. Provide secrets via environment variables at runtime. Keep `OPENCLAW_GATEWAY_TOKEN`, `CLAUDE_*` session credentials, and provider API keys such as `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, `OPENROUTER_API_KEY`, and `ELEVENLABS_API_KEY` local-only. Do not bake secrets into image layers or enable Docker socket access unless you explicitly need Docker-backed sandboxing.
