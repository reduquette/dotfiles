---
name: slack_channel_search_private
description: Always include private channels when searching Slack channels
type: feedback
---

Always pass `channel_types: "public_channel,private_channel"` when calling `slack_search_channels`.

**Why:** Many of the user's relevant channels are private, and the default (public only) silently misses them, leading to wrong channel matches.

**How to apply:** Every time `slack_search_channels` is called, include private channels.
