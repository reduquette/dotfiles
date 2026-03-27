---
name: No $() command substitution in Bash
description: Never use $() in Bash commands — split into sequential calls instead
type: feedback
---

Never use `$()` command substitution in a single Bash command.

**Why:** Claude Code has a hardcoded security check that prompts the user for confirmation whenever a command contains `$()`. This cannot be disabled via settings or allow rules.

**How to apply:** Break the command into sequential Bash calls. Use the output of the first call to construct the argument for the second. For example, instead of `jj git push $(jj bookmark list ...)`, run `jj bookmark list ...` first, then use the result in a separate `jj git push` call.
