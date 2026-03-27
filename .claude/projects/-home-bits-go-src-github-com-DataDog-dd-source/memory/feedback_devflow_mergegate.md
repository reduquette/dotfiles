---
name: devflow/mergegate is not a real CI gate
description: When babysitting PRs, treat devflow/mergegate as a permanent fixture — if it's the only pending check, CI is effectively green
type: feedback
---

When only `devflow/mergegate` is pending, all real CI checks have passed and the PR is ready for review. Do not wait for `devflow/mergegate` to complete — it runs until the PR merges and will never exit on its own.

**Why:** The poll-ci.sh script treats it as a real pending check and never exits with ALL_PASSING, causing unnecessary waiting and failure to alert the user that the PR is ready.

**How to apply:** When babysitting a PR, periodically read the poller output file and check if the only pending check is `devflow/mergegate`. If so, declare CI green and notify the user that the PR is ready for review.
