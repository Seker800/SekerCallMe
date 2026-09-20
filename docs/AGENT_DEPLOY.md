# AI Agent Deployment Guide

This runbook is the authoritative deployment path for an AI agent working in this repository. It covers a macOS server, supported AI agent clients on the trusted local network, and the common case where one Mac has both roles. Client-specific integration belongs in `docs/AGENT_CLIENTS.md`.

Read `docs/NORTH_STAR.md` and `docs/ARCHITECTURE.md` first. Preserve their security boundaries: Caddy is the only published MCP endpoint, the upstream MCP container remains private, and credentials never enter Git or conversation output.

## 1. Identify the host role

Before changing anything, determine which role the current machine has:

- **Server Mac**: runs Docker Compose, ntfy, the authenticated MCP gateway, and the macOS voice subscriber.
- **AI agent client**: Codex, Claude Code, OpenClaw, or another compatible client that connects to the server's Streamable HTTP MCP endpoint. It does not need Docker or the voice subscriber.
- **Both**: perform the server workflow, then configure the locally installed agent client with its native adapter.

If the role cannot be established from the request, operating system, repository, and existing configuration, ask one concise question before installing components.

## 2. Protect secrets and existing configuration

The following are secret runtime material:

- `.env`;
- generated client configuration under `runtime/`;
- MCP bearer tokens;
- ntfy usernames, passwords, and topic names;
- generated client configuration copied to another host.

Required handling rules:

1. Never commit, paste into chat, or include these values in logs or completion summaries.
2. Do not run commands that print `.env` or the generated client configuration to captured output.
3. Preserve existing global client configuration and instruction files. Back them up before editing, then merge only the required section or guidance.
4. If a `seker_call_me` or `seker-call-me` server already exists in the selected client scope, update it instead of creating a duplicate.
5. Keep the service on a trusted LAN, VPN, or trusted HTTPS reverse proxy. Do not expose ports 3010 or 8080 through a public router.

## 3. Deploy or repair the server Mac

### Check prerequisites

The server must be macOS and have Docker with Compose plus the command-line dependencies below. The optional Qwen3-TTS backend additionally requires Apple Silicon, Git, Make, and Xcode Command Line Tools:

```bash
docker --version
docker compose version
command -v curl jq openssl say afplay perl launchctl plutil
```

For Qwen3-TTS, also verify:

```bash
test "$(uname -m)" = arm64
command -v git make xcrun
xcrun --find clang
```

If a dependency is missing, report it precisely. Install it only when the request authorizes system package changes.

### Inspect before initialization

Use checks that do not reveal secret contents:

```bash
test -f .env && echo "Existing server configuration found."
docker compose ps
launchctl print "gui/$(id -u)/com.seker.callme.voice"
```

The last two commands may fail on a fresh installation. If `.env` exists, preserve it: `make init` reuses it rather than rotating credentials.

### Initialize and install speech

From the repository root:

```bash
make check
make init
make voice-ai-install
make voice-install
```

`make init` creates `.env` when needed, starts the pinned containers, creates the least-privilege ntfy user and topic ACL, writes `runtime/codex-config.toml`, and runs the MCP smoke test. On Apple Silicon, `make voice-ai-install` installs the pinned local Qwen3-TTS backend; it is optional because `make voice-install` always retains macOS `say` as a fallback. The first AI install downloads roughly 2.4 GB. The active model uses about 5.5 GB of resident memory on the reference M4 Pro and exits after 20 idle minutes.

The Qwen service is registered on demand rather than kept alive. A notification wakes it before synthesis; the reference machine takes about four seconds to wake from sleep. `make voice-ai-status` succeeds in both valid states and reports either `running` or `sleeping`.

Do not copy the generated configuration into terminal output. Refer to it by path and handle it as a secret file.

### Verify the server

Run all of the following:

```bash
make status
make check
make smoke
make voice-ai-status
make voice-status
make voice-test
```

Expected results:

- all three Compose services are running and ntfy is healthy;
- static shell and Compose checks pass;
- anonymous ntfy and unauthenticated MCP access are denied;
- the authenticated MCP handshake, tool discovery, publish call, and ntfy readback pass;
- the LaunchAgent is running;
- when awake, Qwen3-TTS is healthy and listens only on loopback; when idle, its status reports that it is installed and sleeping;
- the server Mac audibly speaks the voice test.

`make smoke` and `make voice-test` publish real test notifications. Run them for deployment, repair, or explicit verification, not routine read-only inspection.

## 4. Connect an AI agent client

Read `docs/AGENT_CLIENTS.md`, detect the installed client, and use its native global scope. Do not translate a Codex configuration literally into another client's file format.

Every integration must install both:

1. the authenticated MCP capability, filtered to `ntfy_publish_message` when supported;
2. the shared behavior from `client/AGENTS.notification.md` in the client's persistent global or agent-workspace instructions.

The following subsections are the Codex quick path. Claude Code, OpenClaw, and generic MCP client procedures are in `docs/AGENT_CLIENTS.md`.

The client must be able to reach the server's configured LAN address. Obtain `runtime/codex-config.toml` from the server through a trusted local channel. Never send it through an issue, commit, public paste, or model conversation.

### Merge the MCP configuration

Merge the generated `[mcp_servers.seker_call_me]` table into the client's user-level `~/.codex/config.toml`.

- Preserve every unrelated setting and MCP server.
- Do not copy this configuration into a repository-local `.codex/config.toml`.
- Do not create a second `seker_call_me` table if one already exists.
- Keep `required = false` so a notification outage cannot prevent Codex from starting.
- Keep `enabled_tools = ["ntfy_publish_message"]` so only the required publishing tool is exposed.

The generated file contains authentication material and must remain readable only by the user.

### Install the stable global reminder contract

Merge `client/AGENTS.notification.md` into the client's global `~/.codex/AGENTS.md`.

- Preserve every unrelated global instruction.
- Add the policy once; do not duplicate it on repeated deployments.
- Keep it global because the reminder contract must apply in every repository.
- Do not weaken the one-notification-per-task limit, the explicit-silence override, or the prohibition on speaking secrets.

The installed contract requires:

1. one concise spoken outcome when a task completes;
2. one concrete spoken action when the user must intervene;
3. no spoken intermediate progress or repeated updates;
4. a written final response that begins with the same outcome or action, so failure of the audio path does not hide task state.

Project-level `AGENTS.md` should contain project-specific deployment rules and point to this runbook. The cross-project reminder contract belongs in the user's global `AGENTS.md`; otherwise it disappears as soon as Codex opens another repository.

### Reload and verify Codex

Codex builds its instruction chain and MCP tool catalog when a task or session starts. After changing user-level configuration, start a new Codex task or restart the client.

In the fresh task, verify without revealing credentials:

1. confirm that the `seker_call_me` MCP server is enabled;
2. confirm that `ntfy_publish_message` is discoverable and no other ntfy tools are exposed;
3. confirm that the global reminder contract is loaded exactly once;
4. complete one small test task and confirm that its single-sentence outcome is spoken by the server Mac.

The installing agent may not be able to reload its own active task. In that case, report configuration as complete but identify fresh-task discovery and the audible test as the remaining verification. Do not claim that the active task hot-reloaded.

## 5. Codex guaranteed turn-completion fallback

The MCP call is model-initiated. Global instructions make behavior consistent, but cannot guarantee that a tool call happens after interruption or model failure.

When every completed Codex turn must trigger delivery, install `client/codex-notify.sh` on the client and configure the user-level `notify` setting in `~/.codex/config.toml`:

```toml
notify = ["/absolute/path/to/codex-notify.sh"]
```

The hook needs `SEKER_NTFY_URL`, `SEKER_NTFY_TOPIC`, `SEKER_NTFY_USER`, and `SEKER_NTFY_PASSWORD` in the environment that launches Codex. If a notify command already exists, preserve it with a wrapper that invokes both hooks instead of replacing it.

The hook uses the first non-empty line of `last-assistant-message` as its spoken outcome and deliberately ignores `cwd`. This is why the global contract requires the written final response to begin with a concise, speech-safe result or action. The hook may duplicate a model-initiated MCP announcement; enable it only when guaranteed delivery matters more than strict de-duplication. Keep its credentials out of the repository and committed shell profiles.

## 6. Recovery guide

### Containers are stopped or unhealthy

```bash
make up
make status
make smoke
```

Inspect `make logs` only when necessary. Check logs for credentials and topic names before sharing them.

### The server LAN address changed

Update only `LAN_HOST` in `.env` without printing the rest of the file, then run:

```bash
make up
make client-config
make smoke
```

Securely update every client's existing Let Agent Speak MCP entry with the newly generated configuration and restart or reload those agent clients.

### An agent cannot see the tool or policy

Check, in order:

1. the MCP entry and policy are in the client-specific global locations documented in `docs/AGENT_CLIENTS.md`;
2. there is exactly one active Let Agent Speak MCP definition in the selected scope and one reminder contract;
3. the client can reach the configured LAN address;
4. `make smoke` passes on the server;
5. the client runtime was reloaded or a fresh task was created after the change.

### Notifications arrive but the Mac does not speak

```bash
make voice-status
make voice-ai-status
make voice-install
make voice-test
```

If it still fails, inspect `runtime/voice-subscriber.error.log` locally and verify the configured macOS voice with `say -v '?'`. Do not paste logs until they have been checked for sensitive data.

### The first neural notification is slower

This is expected after 20 idle minutes: Qwen has released its model memory and must reload it. On the reference M4 Pro the wake takes about four seconds; later notifications synthesize faster than real time. If low first-message latency matters more than memory, increase `SEKER_QWEN_TTS_IDLE_SECONDS` and rerun `make voice-ai-install`.

## 7. Acceptance criteria

Deployment is complete only when every applicable item is true.

### Server Mac

- `make check` passes.
- `make smoke` passes.
- all Compose services are running and ntfy is healthy.
- `make voice-status` succeeds.
- when neural speech was installed, `make voice-ai-status` succeeds whether it is awake or sleeping; any active listener is loopback-only.
- `make voice-test` is heard on the server Mac.

### AI agent client

- the correct client adapter and global or agent scope were selected;
- existing user or workspace configuration was preserved;
- the Let Agent Speak MCP server loads in a fresh task;
- only `ntfy_publish_message` is exposed from that server when the client supports filtering;
- the reminder contract is present exactly once in every intended agent scope;
- a completed test task speaks one concise outcome;
- a simulated blocker states the exact user action instead of a vague request for attention.

The completion report must begin with what was completed or the precise action still required. It must state which role and checks were covered, without exposing addresses containing secret paths, topic names, tokens, passwords, or generated configuration contents.

## 8. Source of truth

- `docs/NORTH_STAR.md`: product intent and success definition.
- `docs/ARCHITECTURE.md`: trust boundaries, reminder policy, and reliability model.
- `README.md`: operator-facing setup and daily commands.
- `client/AGENTS.notification.md`: global reminder contract.
- `docs/AGENT_CLIENTS.md`: client selection and adapter-specific integration.
- `scripts/init.sh` and `scripts/smoke-test.sh`: executable initialization and end-to-end validation behavior.

Each client uses different global scopes and configuration schemas. Do not infer one from another; follow the official references collected in `docs/AGENT_CLIENTS.md`.
