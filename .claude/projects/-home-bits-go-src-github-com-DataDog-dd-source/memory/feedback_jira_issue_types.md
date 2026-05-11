---
name: Jira issue type preference for AGV
description: In the AGV (AAA Governance) Jira project, prefer Task over Story when creating children of an epic.
type: feedback
originSessionId: ac7ef812-d5c7-4c84-bdc2-d5bb7b281c7e
---
When creating child tickets under an epic in the AGV project, use issue type **Task**, not Story — even for feature work.

**Why:** User course-corrected after I created two Stories under AGV-1127; they said "They should be tasks, not stories." Likely a team convention for how engineering work is tracked under epics.

**How to apply:** Default to `issueTypeName: "Task"` for AGV children-of-epic. If unsure for a different project, ask before creating. Story points field for AGV is `customfield_10024` (company-managed project, simplified: false).
