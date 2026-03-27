---
name: Confirm before pushing to remote
description: User expects confirmation before any git/jj push to remote. Also prefers not to be prompted for non-push decisions when the path forward is clear.
type: feedback
---

# Confirm Before Pushing

Always ask for explicit confirmation before pushing to any remote repository, even when the user says "commit and push" in a single request. Treat the push step as requiring a separate confirmation.

- `git push` — always confirm first
- `jj git push` — always confirm first
- Force pushes — always confirm first (with extra caution)

Do not skip or combine the confirmation into the commit step. After committing successfully, pause and ask the user if they'd like to proceed with the push.

**Why:** User explicitly set this boundary to maintain control over what reaches the remote.

**How to apply:** After committing, state that the commit is ready and ask if they want to push — but don't ask about anything else unless truly ambiguous. Don't prompt for intermediate decisions where the path forward is clear.
