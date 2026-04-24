# Memory Index

This directory contains persistent memory files for the dd-source project context.

## Files

- [feedback_pushing.md](./feedback_pushing.md) — User expects confirmation before any git/jj push to remote, even when "commit and push" is requested together.
- [feedback_slack_channel_search.md](./feedback_slack_channel_search.md) — Always include private channels when searching Slack channels.
- [feedback_bash_command_substitution.md](./feedback_bash_command_substitution.md) — Never use $() in Bash commands; split into sequential calls instead.
- [feedback_bash_pipe_head.md](./feedback_bash_pipe_head.md) — Avoid `2>&1 | head -N` on read-only commands; triggers approval prompt.
- [user_environment.md](./user_environment.md) — Claude Code runs on a remote Linux workspace, not the user's local machine; `bypassPermissions` is safe here.
- [feedback_devflow_mergegate.md](./feedback_devflow_mergegate.md) — `devflow/mergegate` is permanent and never completes; if it's the only pending check, CI is green and PR is ready for review.
- [reference_devflow_api.md](./reference_devflow_api.md) — Use `ddtool auth token rapid-devex-devflow --datacenter us1.ddbuild.io` to curl `devflow-api.us1.ddbuild.io` for executed-commands and feedbacks (debug integration failures).
