# North Star

SekerCallMe gives every Codex host on a trusted local network one small, consistent way to notify its operator when work finishes or needs attention.

The system should be:

- simple to deploy on one always-on LAN machine;
- usable from Codex Desktop, CLI, and IDE clients through Streamable HTTP MCP;
- private by default, with no credentials committed to Git;
- dependable enough that a failed or forgotten model tool call has a separate completion-hook fallback;
- built from replaceable components instead of coupling Codex directly to one phone platform.

Success means a new Codex host can be connected using a generated configuration snippet, send a test notification, and receive it in the ntfy web or mobile client.
