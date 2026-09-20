# Architecture

```text
AI agent clients
(Codex, Claude Code, OpenClaw, generic MCP)
    |
    | Streamable HTTP MCP + bearer token
    v
Caddy gateway :3010
    |
    | private Docker network
    v
ntfy-mcp-server :3010  --->  ntfy :80  --->  macOS voice subscriber
                              ^                       |
                              |                       v
                    optional client hooks        text normalizer
                                                     |
                                                     v
                                             local Qwen3-TTS
                                             (/usr/bin/say fallback)
```

## Boundaries

- Caddy is the only published MCP endpoint. It rejects requests without the configured bearer token.
- Published ports bind to the selected LAN address instead of every host interface. HTTP is acceptable only on a trusted LAN; use a VPN or trusted HTTPS reverse proxy on an untrusted network.
- `ntfy-mcp-server` is not published to the host and has no independent LAN attack surface.
- ntfy is published for subscribers, but anonymous access is denied. One least-privilege user receives read/write access only to the configured topic.
- Persistent ntfy state lives in a Docker volume. Secrets and generated client snippets live outside Git.
- Clients should keep the MCP optional when their configuration supports it, so a notification outage does not prevent agent work from starting.
- Audio playback stays outside Docker. A per-user macOS LaunchAgent subscribes to the authenticated ntfy JSON stream, normalizes only the message body, suppresses recent duplicates, and sends it to a replaceable speech-provider adapter.
- The optional pinned Qwen3-TTS runtime is an on-demand per-user LaunchAgent. It binds only to `127.0.0.1`, does not log request text, and permits no browser CORS origin. The speech adapter wakes it before a request; its supervisor exits after 20 idle minutes to release model memory. The adapter falls back to `/usr/bin/say` if startup or synthesis fails.
- The voice subscriber depends only on ntfy's public HTTP stream, so the speech backend can be replaced without changing the MCP server or agent clients.

## Stable machine identifiers

The public product name is Let Agent Speak. Machine-facing identifiers created before the rename—including `seker-call-me`, `seker_call_me`, `com.seker.callme.voice`, and the `SEKER_` environment-variable prefix—remain stable compatibility IDs. Treat them as opaque implementation details. Changing them without an explicit migration would create duplicate MCP entries, Compose projects, or LaunchAgents on existing installations.

## Client adapters

The server exposes one authenticated Streamable HTTP MCP endpoint and has no client-specific behavior. Each client adapter supplies two things:

1. a user- or agent-scoped MCP registration that exposes only `ntfy_publish_message` when filtering is supported;
2. the shared behavioral contract from `client/AGENTS.notification.md` through that client's persistent instruction mechanism.

Codex uses user-level `config.toml` and `AGENTS.md`; Claude Code uses a user-scoped MCP entry and user rules; OpenClaw uses its central MCP registry plus each agent workspace's `AGENTS.md`. Generic clients follow the same two-part contract using their nearest equivalent scopes. Details live in `docs/AGENT_CLIENTS.md`.

## Announcement policy

Every configured agent receives the same policy from `client/AGENTS.notification.md` through its native persistent instruction mechanism. At the end of every user task it announces exactly once with a concise outcome. If progress is blocked, the announcement states the concrete action the operator must take instead of merely asking for attention. Intermediate progress and repeated updates stay silent, and an explicit request to stay quiet overrides the default for that task.

## Reliability model

MCP calls are initiated by the model and can be skipped when a run is interrupted or the model fails to follow instructions. Persistent global policy makes the intended behavior stable across projects, but prompt instructions alone are not a delivery guarantee. Clients with a completion lifecycle hook can call ntfy directly as a mechanical fallback; the repository currently ships a Codex hook. Model and hook publishing paths are intentionally independent and converge only at ntfy, while speech delivery remains a separate subscriber.

## Upgrade policy

Container versions are pinned in `compose.yaml`. Upgrade one component at a time, then run `make check` and `make smoke` before committing the version change.

The Qwen3-TTS source and model revisions are pinned independently in the installer. Local compatibility and security patches are applied deterministically before compilation; upgrades require the same check, smoke, and audible voice-test cycle.
