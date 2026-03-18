#!/usr/bin/env bash
# Refresh ddtool credentials once per day.
# Sourced from ~/.zprofile on SSH login (login shell).
# Safe to run manually too: ~/dotfiles/daily-auth.sh

_daily_auth() {
  local STAMP_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/daily-auth/last-run"
  local TODAY
  TODAY=$(date +%Y-%m-%d)

  # Already ran today — skip silently
  if [ -f "$STAMP_FILE" ] && [ "$(cat "$STAMP_FILE")" = "$TODAY" ]; then
    return 0
  fi

  if ! command -v ddtool >/dev/null 2>&1; then
    return 0
  fi

  mkdir -p "$(dirname "$STAMP_FILE")"

  echo "[daily-auth] Refreshing ddtool credentials..."

  # Use DDTOOL_DATACENTER env var to override, defaulting to us1.ddbuild.io.
  # 'auto' mode: silently refreshes if the token is still renewable;
  # falls back to device flow (prints a URL + code) if a full re-auth is needed.
  local dc="${DDTOOL_DATACENTER:-us1.ddbuild.io}"
  if ddtool auth login --mode auto --datacenter "$dc"; then
    echo "$TODAY" > "$STAMP_FILE"
    echo "[daily-auth] Done."
  else
    echo "[daily-auth] Warning: auth refresh failed. Run manually:"
    echo "  ddtool auth login --datacenter $dc"
  fi
}

_daily_auth
unset -f _daily_auth
