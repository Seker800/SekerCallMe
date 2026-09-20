# Let Agent Speak workspace rules

- Read `docs/NORTH_STAR.md` and `docs/ARCHITECTURE.md` before changing runtime behavior.
- Never commit `.env`, generated client configuration, credentials, or runtime data.
- Keep the MCP gateway authenticated; do not expose the upstream MCP container directly.
- Prefer pinned container versions and verify upgrades with `make check` and `make smoke`.
- A completion notification is best effort through MCP. Use the Codex `notify` fallback when delivery must be guaranteed for every completed turn.

## AI deployment workflow

- For any request to deploy, connect, repair, or verify Let Agent Speak, read `docs/AGENT_DEPLOY.md` and `docs/AGENT_CLIENTS.md` before acting.
- First identify whether this machine is the server Mac, an AI agent client, or both. Do not install server components on a client-only host.
- Detect the actual client instead of assuming Codex. Use that client's documented user/global MCP scope and persistent instruction mechanism.
- Treat `.env`, generated client configuration, MCP bearer tokens, ntfy credentials, and topic names as secrets. Never print them in chat, logs, commits, or captured command output.
- Merge MCP configuration and notification guidance into existing user files; never replace an entire global configuration or instruction file.
- Install the shared reminder contract from `client/AGENTS.notification.md`. Keep it project-independent so it applies in every repository or workspace handled by that agent.
- Do not declare deployment complete until the applicable acceptance checks in `docs/AGENT_DEPLOY.md` pass. Report results without secret values.
