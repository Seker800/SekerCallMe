# Architecture

```text
Codex hosts
    |
    | Streamable HTTP MCP + bearer token
    v
Caddy gateway :3010
    |
    | private Docker network
    v
ntfy-mcp-server :3010  --->  ntfy :80  --->  browser / phone
                              ^
                              |
                       optional notify hook
```

## Boundaries

- Caddy is the only published MCP endpoint. It rejects requests without the configured bearer token.
- Published ports bind to the selected LAN address instead of every host interface. HTTP is acceptable only on a trusted LAN; use a VPN or trusted HTTPS reverse proxy on an untrusted network.
- `ntfy-mcp-server` is not published to the host and has no independent LAN attack surface.
- ntfy is published for subscribers, but anonymous access is denied. One least-privilege user receives read/write access only to the configured topic.
- Persistent ntfy state lives in a Docker volume. Secrets and generated client snippets live outside Git.
- The MCP is optional in Codex configuration, so a notification outage never prevents coding work from starting.

## Reliability model

MCP calls are initiated by the model and can be skipped when a run is interrupted or the model fails to follow instructions. The MCP path is used for useful, human-readable summaries. Codex's external `notify` command can call ntfy directly as a turn-completion fallback. The two paths are intentionally independent.

## Upgrade policy

Container versions are pinned in `compose.yaml`. Upgrade one component at a time, then run `make check` and `make smoke` before committing the version change.
