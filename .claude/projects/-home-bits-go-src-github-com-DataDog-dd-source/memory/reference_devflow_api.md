---
name: Devflow API authenticated access
description: How to authenticate to devflow-api from CLI to inspect executed commands and feedbacks (integration failures, etc.)
type: reference
originSessionId: 9548e76e-d673-42f0-8c73-3ffcaac2cd27
---
## Authenticated access to devflow-api

Devflow's UI pages at `https://mosaic.us1.ddbuild.io/devflow/history/<command_id>` are backed by the `devflow-api` REST service. Hitting it from CLI requires a JWT with an accepted audience.

### Accepted JWT audiences (from domains/devex/devflow/apps/apis/devflow-api/main.go)

- Production: `sdm`, `rapid-devex-devflow`, `rapid-frontend-devx`
- Staging: `sdm-staging`, `rapid-devex-devflow`

`rapid-devex-devflow` works for both and is the easiest to use with `ddtool`.

### Hosts

- Prod: `https://devflow-api.us1.ddbuild.io`
- Staging: `https://devflow-api.us1.staging.dog`

### Curl recipe

```
ddtool auth token rapid-devex-devflow --datacenter us1.ddbuild.io --http-header > /tmp/auth_hdr.txt
curl -sS -H "@/tmp/auth_hdr.txt" -H "Accept: application/json" \
  "https://devflow-api.us1.ddbuild.io/internal/api/v2/devflow/executed-commands?command_id__in=<UUID>"
curl -sS -H "@/tmp/auth_hdr.txt" -H "Accept: application/json" \
  "https://devflow-api.us1.ddbuild.io/internal/api/v2/devflow/executed-commands/<UUID>/feedbacks"
```

### Useful endpoints for debugging

- `GET /internal/api/v2/devflow/executed-commands?command_id__in=<UUID>` — command metadata: action_name, action_args (JSON with PR/target/deploy/etc.), created_at, done_at, computed_status, ctx_triggered_by, gateway_feedback_workflow_id.
- `GET /internal/api/v2/devflow/executed-commands/<UUID>/feedbacks` — ordered list of feedback payloads (INFO progression + ERROR with `title`, `message`, `details`, `details_url`) showing exactly why a command failed.
- `GET /internal/api/v2/devflow/state/<workflow_id>` — state from Temporal workflow id.
- `GET /internal/api/v2/integrations-branches` — integration branch listing.

### Why service tokens fail with 401

`ddtool auth token mosaic`, `ddtool auth token devflow`, `ddtool auth token devflow-api`, and `sycamore/devflow-api` all return 401 from devflow-api. The middleware only allows the three audiences above plus issuers `vault.us1.ddbuild.io`, `vault.us1.prod.dog`, and the Ticino/maple issuer.

### Mosaic UI shell vs API

Requests to `mosaic.us1.ddbuild.io/internal/api/…` return the SPA HTML shell — the API is *not* proxied through the mosaic hostname. Go directly to `devflow-api.us1.ddbuild.io` or `devflow-api.us1.staging.dog`.
