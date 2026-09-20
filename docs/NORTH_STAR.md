# North Star

Let Agent Speak gives AI agent hosts on a trusted local network one small, consistent way to make the operator's Mac speak when work finishes or needs attention.

The system should be:

- simple to deploy on one always-on LAN machine;
- usable from Codex, Claude Code, OpenClaw, and other Streamable HTTP MCP clients;
- private by default, with no credentials committed to Git;
- adaptable to each agent's global instruction and lifecycle-hook mechanisms without coupling the server to one client;
- audible directly on the server Mac through a local speech backend with a native system fallback;
- predictable: every completed user task gets one concise spoken outcome unless the user explicitly asks for silence;
- built from replaceable components instead of coupling one agent directly to the speech backend.

Success means a supported agent can select its native global MCP and instruction mechanisms, install the shared reminder contract, call the notification tool once per completed task, and hear a concise outcome or required action spoken by the server Mac. Client-specific completion hooks remain an optional secondary path.
