---
name: Confirm before pushing to remote
description: User expects to be asked for confirmation before any git push or jj git push, even when they phrase the request as "commit and push" in one breath.
type: feedback
---

# Confirm Before Pushing

The user wants to be asked for explicit confirmation before pushing to any remote repository.

This applies even when the user says something like "commit and push" in a single request — treat the push step as requiring a separate confirmation before executing it.

- `git push` — always confirm first
- `jj git push` — always confirm first
- Force pushes (`git push --force`, etc.) — always confirm first (with extra caution)

Do not skip or combine the confirmation into the commit step. After committing successfully, pause and ask the user if they'd like to proceed with the push.
