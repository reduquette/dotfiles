#!/usr/bin/env bash
# Run this after your first SSH login (with ForwardAgent yes) to complete workspace setup.
# It configures the git HTTPS→SSH rewrite for GitHub and fetches your personal jj bookmarks.
set -euo pipefail

DOTFILES_PATH="$HOME/dotfiles"

# Find dd-source
for _candidate in "${DD_SOURCE_PATH:-}" "$HOME/dd/dd-source" "$HOME/go/src/github.com/DataDog/dd-source"; do
  [ -n "$_candidate" ] && [ -d "$_candidate/.git" ] && DD_SOURCE_PATH="$_candidate" && break
done
unset _candidate 2>/dev/null || true


echo "==> Configuring git SSH rewrite"

if ! { ssh -T git@github.com 2>&1 || true; } | grep -qi "successfully authenticated"; then
  echo "   SSH to GitHub not available. Make sure you connected with ForwardAgent yes and try again."
  exit 1
fi

git config --global 'url.git@github.com:.insteadOf' 'https://github.com/'
echo "   Enabled HTTPS → SSH rewrite for github.com"

# Fix the dotfiles repo remote if it was cloned via HTTPS (common during initial provisioning)
_DOTFILES_REMOTE=$(git -C "$DOTFILES_PATH" remote get-url origin 2>/dev/null || true)
if echo "$_DOTFILES_REMOTE" | grep -q '^https://github.com/'; then
  _DOTFILES_SSH_URL="git@github.com:${_DOTFILES_REMOTE#https://github.com/}"
  git -C "$DOTFILES_PATH" remote set-url origin "$_DOTFILES_SSH_URL"
  echo "   Updated dotfiles remote: $_DOTFILES_REMOTE -> $_DOTFILES_SSH_URL"
fi


echo "==> Fetching personal jj bookmarks in dd-source"

if [ -n "${DD_SOURCE_PATH:-}" ] && [ -d "$DD_SOURCE_PATH/.jj" ]; then
  JJ_USER_PREFIX="$(git config --global user.email | cut -d@ -f1)"
  echo "   Fetching and tracking bookmarks for $JJ_USER_PREFIX"
  (cd "$DD_SOURCE_PATH" && jj git fetch --bookmark "$JJ_USER_PREFIX/*")
  (cd "$DD_SOURCE_PATH" && jj git import)
  (cd "$DD_SOURCE_PATH" && jj bookmark track "glob:$JJ_USER_PREFIX/**@origin" 2>/dev/null || true)
else
  echo "   dd-source not found or not initialized with jj, skipping"
fi


echo "==> Done"
