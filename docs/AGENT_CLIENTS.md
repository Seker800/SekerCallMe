# Agent Client Integration Guide

Let Agent Speak is an authenticated Streamable HTTP MCP service, not a Codex-only feature. A complete client integration always has two independent parts:

1. **Capability**: register the MCP endpoint in the client's user, global, or agent scope.
2. **Behavior**: install `client/AGENTS.notification.md` in the client's persistent instruction scope.

The MCP connection makes publishing possible. The instruction policy tells the agent when and how to publish. Installing only one half is incomplete.

## Selection rules for an installing agent

1. Detect the actual client from installed commands, existing configuration, and the user's request. Do not assume Codex.
2. Prefer the narrowest scope that still follows the user across all projects:
   - personal user/global scope for Codex and Claude Code;
   - per-agent workspace scope for OpenClaw behavior, with its central MCP registry for capability;
   - the closest equivalent for another MCP client.
3. Preserve existing configuration and instructions. Update an existing `seker_call_me` entry instead of creating a duplicate.
4. Keep credentials in local environment or secret storage when the client supports it. Never commit a bearer token or paste it into chat.
5. Filter the server to `ntfy_publish_message` when the client supports tool allowlists.
6. Start a fresh session, verify tool discovery, publish one non-sensitive test result, and confirm that the server Mac speaks it.

The examples below use these placeholders:

- `<MCP_URL>`: the server's generated MCP URL, ending in `/mcp`;
- `SEKER_CALL_ME_MCP_TOKEN`: an environment variable containing the bearer token.

Resolve placeholders locally without printing their values. The environment variable must be available to the process that launches the agent client.

## Codex

### Global MCP capability

Merge the generated `[mcp_servers.seker_call_me]` table from `runtime/codex-config.toml` into the user's active Codex configuration, normally `~/.codex/config.toml`.

Keep these properties:

- `required = false`, so notification downtime does not block agent startup;
- `enabled_tools = ["ntfy_publish_message"]`;
- bearer authentication through a protected environment variable or local header configuration.

Codex Desktop, CLI, and IDE clients on the same host share the user-level MCP configuration.

### Global behavior

Merge `client/AGENTS.notification.md` into the user's active Codex `AGENTS.md`, normally `~/.codex/AGENTS.md`. Preserve unrelated instructions and ensure no `AGENTS.override.md` at the same global level replaces it.

### Verify

Start a new Codex task, then confirm:

- `seker_call_me` is enabled;
- only `ntfy_publish_message` is exposed from that server;
- the shared policy is loaded once;
- one completed test task produces one spoken result.

Official references: [Codex MCP](https://learn.chatgpt.com/docs/extend/mcp) and [Codex AGENTS.md discovery](https://learn.chatgpt.com/docs/agent-configuration/agents-md).

## Claude Code

### Global MCP capability

Use Claude Code's **user** MCP scope so the server is available in every project. Prefer JSON configuration with environment expansion so the token is not written literally into the command history or configuration:

```bash
claude mcp add-json seker-call-me \
  '{"type":"http","url":"<MCP_URL>","headers":{"Authorization":"Bearer ${SEKER_CALL_ME_MCP_TOKEN}"}}' \
  --scope user
```

If `seker-call-me` already exists in user scope, inspect and update it instead of blindly running the add command. Claude Code stores user-scoped MCP definitions in `~/.claude.json` and gives more specific local or project definitions precedence over user scope.

### Global behavior

Install the contents of `client/AGENTS.notification.md` as a user rule, for example:

```text
~/.claude/rules/seker-call-me.md
```

User rules apply across projects and avoid coupling the reminder contract to a single repository. Preserve any existing `~/.claude/CLAUDE.md` and rules. A project may also use `CLAUDE.md` or newer Claude Code versions may read `AGENTS.md`, but neither is a replacement for the cross-project user rule.

### Verify

Run:

```bash
claude mcp get seker-call-me
claude mcp list
```

Then start a fresh Claude Code session, use `/mcp` to confirm the connection, and complete one small test task. Verify that Claude calls the publishing tool once and that the server Mac speaks the concise result.

Official references: [Claude Code MCP scopes and HTTP authentication](https://code.claude.com/docs/en/mcp) and [Claude Code user rules and memory](https://code.claude.com/docs/en/memory).

## OpenClaw

OpenClaw separates its centrally managed MCP registry from each agent's workspace instructions. Configure both.

### Central MCP capability

Save an authenticated Streamable HTTP server in OpenClaw's `mcp.servers` registry:

```bash
openclaw mcp set seker-call-me \
  '{"url":"<MCP_URL>","transport":"streamable-http","headers":{"Authorization":"Bearer ${SEKER_CALL_ME_MCP_TOKEN}"},"toolFilter":{"include":["ntfy_publish_message"]}}'
```

The token environment variable must be available to the Gateway or runtime process that owns the MCP connection. After changing the registry, reload or restart that owner as required by the deployment.

If OpenClaw sandboxing is enabled and MCP tools do not appear, allow `bundle-mcp` in `tools.sandbox.tools.alsoAllow`. Do not broaden the sandbox tool policy when the exact server tool or bundle permission is sufficient.

### Per-agent behavior

Merge `client/AGENTS.notification.md` into the `AGENTS.md` of every OpenClaw agent workspace that should speak. The default single-agent workspace is normally `~/.openclaw/workspace`; multi-agent installations may assign a distinct workspace through `agents.entries.*.workspace`.

Do not put the behavior only in one arbitrary workspace and assume other OpenClaw agents inherit it. Each configured agent has its own bootstrap context.

### Verify

Run:

```bash
openclaw mcp status --verbose
openclaw mcp doctor seker-call-me --probe
```

Start a fresh agent session or reload the Gateway-owned runtime, confirm that the filtered publishing tool is visible, and complete one test task. For multi-agent setups, verify at least one session for each workspace where the policy was installed.

Official references: [OpenClaw MCP registry](https://docs.openclaw.ai/cli/mcp/registry), [OpenClaw MCP configuration](https://docs.openclaw.ai/gateway/config-extensions), and [OpenClaw agent workspaces](https://docs.openclaw.ai/agent-workspace).

## Other MCP-capable agents

Use the client's native global or user scope when it has one. The conceptual MCP entry is:

```json
{
  "name": "seker_call_me",
  "transport": "streamable-http",
  "url": "<MCP_URL>",
  "headers": {
    "Authorization": "Bearer ${SEKER_CALL_ME_MCP_TOKEN}"
  },
  "enabledTools": ["ntfy_publish_message"]
}
```

This is a conceptual example, not a universal file format. Field names and supported environment expansion differ between clients. Use that client's official schema instead of copying unknown keys.

Install `client/AGENTS.notification.md` through the first supported persistent mechanism in this order:

1. user/global instruction or rules file;
2. agent-profile or workspace bootstrap instructions;
3. project instruction file;
4. session system prompt as a last resort.

If the client has no global scope, document that limitation and install per project or per agent workspace. If it has no Streamable HTTP MCP support, do not claim compatibility; use a client-specific completion hook that publishes directly to ntfy, or leave that client unsupported until an adapter exists.

## Security and completion checks

For every client:

- never place bearer tokens, ntfy credentials, or topic names in a committed file;
- never print generated client configuration in agent-visible logs;
- preserve existing user instructions and MCP servers;
- keep the gateway authenticated and the upstream MCP container private;
- verify from a fresh session, because many clients build their tool catalog and instruction context at startup;
- report the selected scope, policy location, and verification result without reporting secret values.

Client integration is complete only when both the MCP tool and the shared policy are active in the intended global or agent scope and one end-to-end spoken test succeeds.
