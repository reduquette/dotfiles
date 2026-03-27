---
name: Avoid 2>&1 | head -N on read-only commands
description: Using 2>&1 | head -N on innocuous commands like jj log triggered a user approval prompt
type: feedback
---

Do not append `2>&1 | head -N` to read-only informational commands (e.g. `jj log`, `jj diff --stat`). It triggered a hardcoded security approval prompt.

**Why:** The pipe+redirect combination is flagged by the permission heuristics, even on benign commands.

**How to apply:** Omit `| head -N` from read-only commands; Claude Code already truncates long tool output. If truncation is needed, rely on the built-in `head_limit` parameter of the Grep tool, or accept full output.
