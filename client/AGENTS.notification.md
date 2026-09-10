# Completion notifications

When the requested work is genuinely complete, or when progress is blocked and needs the user's attention, call `ntfy_publish_message` exactly once with a short title, a useful summary, and an appropriate priority. Do not send notifications for routine progress updates.
