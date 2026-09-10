# SekerCallMe workspace rules

- Read `docs/NORTH_STAR.md` and `docs/ARCHITECTURE.md` before changing runtime behavior.
- Never commit `.env`, generated client configuration, credentials, or runtime data.
- Keep the MCP gateway authenticated; do not expose the upstream MCP container directly.
- Prefer pinned container versions and verify upgrades with `make check` and `make smoke`.
- A completion notification is best effort through MCP. Use the Codex `notify` fallback when delivery must be guaranteed for every completed turn.
