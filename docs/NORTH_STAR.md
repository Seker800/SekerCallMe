# North Star

SekerCallMe gives every Codex host on a trusted local network one small, consistent way to make the operator's Mac speak when work finishes or needs attention.

The system should be:

- simple to deploy on one always-on LAN machine;
- usable from Codex Desktop, CLI, and IDE clients through Streamable HTTP MCP;
- private by default, with no credentials committed to Git;
- dependable enough that a failed or forgotten model tool call has a separate completion-hook fallback;
- audible on the server Mac without requiring a phone, browser, or manually opened app;
- quiet for routine chat: Codex decides whether a result is important enough to announce;
- built from replaceable components instead of coupling Codex directly to one phone platform.

Success means a new Codex host can be connected using a generated configuration snippet, call the notification tool, and hear the result spoken by the server Mac. Web and mobile ntfy clients remain optional secondary subscribers.
