# Voice notifications

Use `ntfy_publish_message` to make the user's Mac speak when an audible interruption is genuinely useful. Decide autonomously using these defaults:

- Announce once after substantial requested work or a long-running operation is genuinely complete.
- Announce once when progress is blocked and the user must act before work can continue.
- Announce when the user explicitly asks to be called, alerted, or told aloud.
- Stay silent for routine questions, quick edits, intermediate progress, and repeated status updates.
- An explicit request to stay quiet overrides every default above.

Use a short natural-language title and a concise message that sounds good when spoken. Do not read file paths, code, logs, URLs, tokens, or other secrets aloud. Call the tool at most once per completed task.
