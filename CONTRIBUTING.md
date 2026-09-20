# Contributing to Let Agent Speak

Thanks for helping make Let Agent Speak simpler, safer, and more dependable.

## Before you start

- Search existing issues before opening a new one.
- Use a GitHub issue to discuss substantial behavior or architecture changes first.
- Report security problems privately by following [`SECURITY.md`](SECURITY.md).
- Keep the project focused on reliable, private notifications for MCP-capable agent hosts.

## Development setup

You need macOS, Docker with Docker Compose, `curl`, `jq`, and `openssl`. Neural-speech development also requires Apple Silicon, Git, Make, and Xcode Command Line Tools.

```bash
git clone https://github.com/Seker800/LetAgentSpeak.git
cd LetAgentSpeak
make init
make voice-ai-install # optional; Apple Silicon only
make voice-install
```

Generated credentials live in `.env`, and generated client configuration and logs live in `runtime/`. These paths are intentionally ignored. Never add credentials, real LAN configuration, or runtime data to a commit.

## Making a change

1. Read [`docs/NORTH_STAR.md`](docs/NORTH_STAR.md) and [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) before changing runtime behavior.
2. Keep Caddy as the authenticated MCP boundary; do not publish the upstream MCP container.
3. Prefer small, composable changes over coupling any agent client directly to the speech backend.
4. Keep container versions pinned.
5. Update both `README.md` and `README.zh-CN.md` when user-facing setup or behavior changes.
6. Keep the Qwen source and model revisions pinned, its listener loopback-only, and request text out of logs.

## Validation

Run the static checks for every change:

```bash
make check
```

For runtime, networking, authentication, container, or dependency changes, also run:

```bash
make smoke
```

The smoke test verifies service health, anonymous denial, topic isolation, MCP bearer authentication, protocol initialization, tool discovery, message publication, and readback.

For speech lifecycle changes, also run:

```bash
make voice-ai-status
make voice-status
make voice-test
```

`make voice-ai-status` may validly report either running or sleeping. `make voice-test` publishes and speaks a real notification.

## Pull requests

Keep each pull request focused. Explain the motivation, the security or architecture impact, and exactly how you validated the result. Screenshots are useful only when the visible documentation or UI changed.

By contributing, you agree that your contributions are licensed under the project's [MIT License](LICENSE) and that you will follow the [Code of Conduct](CODE_OF_CONDUCT.md).
