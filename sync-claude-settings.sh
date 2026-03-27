#!/usr/bin/env bash
set -euo pipefail

DOTFILES_PATH="${DOTFILES_PATH:-$HOME/dotfiles}"

echo "==> Merging Claude Code user settings"

_CLAUDE_USER_SETTINGS="$HOME/.claude/settings.json"
_DOTFILES_CLAUDE_SETTINGS="$DOTFILES_PATH/.claude/settings.json"
if [ -f "$_DOTFILES_CLAUDE_SETTINGS" ]; then
  if [ ! -f "$_CLAUDE_USER_SETTINGS" ]; then
    mkdir -p "$HOME/.claude"
    cp "$_DOTFILES_CLAUDE_SETTINGS" "$_CLAUDE_USER_SETTINGS"
    echo "   Created $_CLAUDE_USER_SETTINGS from dotfiles"
  elif command -v jq >/dev/null 2>&1; then
    jq --slurpfile user "$_DOTFILES_CLAUDE_SETTINGS" '
      . + {
        permissions: (
          ($user[0].permissions // {}) + (.permissions // {}) +
          {
            allow: (((.permissions.allow // []) + ($user[0].permissions.allow // [])) | unique),
            deny:  (((.permissions.deny  // []) + ($user[0].permissions.deny  // [])) | unique)
          }
        ),
        enabledPlugins: ((.enabledPlugins // {}) + ($user[0].enabledPlugins // {})),
        env: ((.env // {}) + ($user[0].env // {})),
        hooks: ($user[0].hooks // {})
      }
    ' "$_CLAUDE_USER_SETTINGS" > "$_CLAUDE_USER_SETTINGS.tmp" \
      && mv "$_CLAUDE_USER_SETTINGS.tmp" "$_CLAUDE_USER_SETTINGS" \
      && echo "   Merged Claude Code permissions into $_CLAUDE_USER_SETTINGS" \
      || echo "   Warning: jq merge failed — $_CLAUDE_USER_SETTINGS unchanged"
  else
    echo "   Warning: jq not found — skipping Claude Code settings merge"
  fi
fi
