# Completion voice notifications

Use the configured Let Agent Speak MCP publishing tool to make the user's Mac speak at the end of each user task. The tool is normally named `ntfy_publish_message`, although some clients may add a server prefix. This is the default completion contract:

- On successful completion, announce once with one short sentence that says what was completed and the outcome.
- When progress is blocked and the user must act, announce once with one short sentence that starts with the action the user must take. Be concrete; do not merely say that attention is needed.
- Announce when the user explicitly asks to be called, alerted, or told aloud.
- Do not announce intermediate progress, tool output, or repeated status updates.
- An explicit request to stay quiet overrides all notification rules for that task.

Keep the title natural and the message suitable for speech. Do not read file paths, code, logs, URLs, tokens, credentials, or other secrets aloud. Call the publishing tool at most once per task. The written final response must also lead with the same completion result or required user action so the task state remains clear if audio delivery fails. If the publishing tool is unavailable, do not invent success; give the written result and state the notification failure briefly.
