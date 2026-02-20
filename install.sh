#!/usr/bin/env bash
set -euo pipefail

DOTFILES_PATH="$HOME/dotfiles"

# Restore SSH agent access when running through sudo/su (which strips
# SSH_AUTH_SOCK). The workspace keeps a stable symlink to the real socket.
if [ -z "${SSH_AUTH_SOCK:-}" ] && [ -S "$HOME/.ssh/ssh_auth_sock" ]; then
  export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"
fi

echo "==> Symlinking dotfiles from $DOTFILES_PATH into $HOME"

# Symlink all dotfiles paths (".*" and ".config/...", etc) into $HOME.
# This is essentially the same idea as the template approach (find + ln -sf).
find "$DOTFILES_PATH" -type f \( -path "$DOTFILES_PATH/.*" -o -path "$DOTFILES_PATH/.config/*" \) \
  ! -path "$DOTFILES_PATH/.git/*" \
  ! -name "install.sh" \
| while read -r df; do
    link="${df/$DOTFILES_PATH/$HOME}"
    mkdir -p "$(dirname "$link")"
    ln -sf "$df" "$link"
  done

echo "==> Installing linuxbrew (if needed) and tools (jj, watchman)"

# The [url "git@github.com:"] insteadOf rewrite in ~/.gitconfig converts
# HTTPS → SSH, which fails when no SSH key is available. The Homebrew
# installer runs `brew update --force` through sudo, stripping env vars
# like GIT_CONFIG_GLOBAL, so we must remove the rewrite from the file
# itself. A trap ensures it's restored even if the script fails midway.
_BREW_HAD_INSTEADOF=""
if git config --global --get 'url.git@github.com:.insteadOf' &>/dev/null; then
  _BREW_HAD_INSTEADOF=1
  git config --global --unset-all 'url.git@github.com:.insteadOf'
fi
_restore_git_insteadof() {
  if [ -n "$_BREW_HAD_INSTEADOF" ]; then
    git config --global 'url.git@github.com:.insteadOf' 'https://github.com/'
  fi
}
trap _restore_git_insteadof EXIT

export HOMEBREW_INSTALL_FROM_API=1
export HOMEBREW_NO_AUTO_UPDATE=1

if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Ensure brew is on PATH for this session (try common locations)
if ! command -v brew >/dev/null 2>&1; then
  test -d /opt/homebrew && eval "$(/opt/homebrew/bin/brew shellenv)"
  test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
  test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Add brew to shell configs
if command -v brew >/dev/null 2>&1; then
  BREW_INIT="eval \"\$($(brew --prefix)/bin/brew shellenv)\""
  grep -qxF "$BREW_INIT" ~/.zshrc 2>/dev/null || echo "$BREW_INIT" >> ~/.zshrc
  grep -qxF "$BREW_INIT" ~/.bashrc 2>/dev/null || echo "$BREW_INIT" >> ~/.bashrc
fi

# Ensure ~/.bash_profile sources ~/.bashrc (macOS bash login shells skip .bashrc)
BASH_SOURCE_BLOCK='
# Source .bashrc if it exists (for macOS login shells)
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
'
if ! grep -Fq '. ~/.bashrc' ~/.bash_profile 2>/dev/null; then
  printf "\n%s\n" "$BASH_SOURCE_BLOCK" >> ~/.bash_profile
  echo "   Added .bashrc sourcing to ~/.bash_profile"
else
  echo "   ~/.bash_profile already sources ~/.bashrc"
fi

# Install common dev tools
brew install jj watchman tmux fzf

echo "==> Configuring fzf shell integration"

FZF_ZSH_INIT='source <(fzf --zsh)'
FZF_BASH_INIT='eval "$(fzf --bash)"'
grep -qxF "$FZF_ZSH_INIT" ~/.zshrc 2>/dev/null || echo "$FZF_ZSH_INIT" >> ~/.zshrc
grep -qxF "$FZF_BASH_INIT" ~/.bashrc 2>/dev/null || echo "$FZF_BASH_INIT" >> ~/.bashrc

echo "==> Configuring dd-source repository (if present)"

# Apply dd-source-specific config to ~/dd/dd-source
DD_SOURCE_PATH="$HOME/dd/dd-source"
if [ -d "$DD_SOURCE_PATH/.git" ]; then
  # Initialize jj if not already colocated with git
  if [ ! -d "$DD_SOURCE_PATH/.jj" ]; then
    echo "   Initializing jj in dd-source repository"
    (cd "$DD_SOURCE_PATH" && jj git init --colocate)
  else
    echo "   jj already initialized in dd-source"
  fi

  # Apply dd-source-specific jj config
  DD_SOURCE_CONFIG="$DD_SOURCE_PATH/.jj/repo/config.toml"
  mkdir -p "$(dirname "$DD_SOURCE_CONFIG")"

  if [ -f "$DOTFILES_PATH/.config/jj/dd-source-config.toml" ]; then
    cp "$DOTFILES_PATH/.config/jj/dd-source-config.toml" "$DD_SOURCE_CONFIG"
    echo "   Applied dd-source jj config to $DD_SOURCE_CONFIG"
  else
    echo "   Warning: dd-source-config.toml not found in dotfiles"
  fi

  # Configure dd-source git hooks
  echo "   Configuring dd-source git hooks"
  (cd "$DD_SOURCE_PATH" && git config --local --add ddsource.hooks.pre-push.gazelle true)
  (cd "$DD_SOURCE_PATH" && git config --local --add ddsource.hooks.pre-push.gofmt true)

  # Fetch and track personal bookmarks (requires SSH key, which may not
  # be available yet during initial provisioning)
  JJ_USER_PREFIX="rachel.duquette"
  echo "   Fetching and tracking bookmarks for $JJ_USER_PREFIX"
  if (cd "$DD_SOURCE_PATH" && jj git fetch --bookmark "$JJ_USER_PREFIX/*" 2>&1); then
    (cd "$DD_SOURCE_PATH" && jj git import)
    (cd "$DD_SOURCE_PATH" && jj bookmark track "glob:$JJ_USER_PREFIX/**@origin" 2>/dev/null || true)
  else
    echo "   Skipped: SSH key not available yet. Run this later to fetch bookmarks:"
    echo "     cd $DD_SOURCE_PATH && jj git fetch --bookmark '$JJ_USER_PREFIX/*' && jj git import"
  fi
else
  echo "   dd-source repository not found at $DD_SOURCE_PATH (skipping)"
fi

echo "==> Deploying Cursor rules to project directories"

deploy_cursor_rules() {
  local project_dir="$1"
  if [ -d "$project_dir" ]; then
    local rules_dir="$project_dir/.cursor/rules"
    mkdir -p "$rules_dir"
    for rule in "$DOTFILES_PATH/.cursor/rules/"*.mdc; do
      [ -f "$rule" ] || continue
      cp "$rule" "$rules_dir/$(basename "$rule")"
    done
    echo "   Deployed Cursor rules to $rules_dir"
  fi
}

deploy_cursor_rules "$DD_SOURCE_PATH"

echo "==> Configuring tmux auto-attach for SSH sessions"

# Add tmux auto-attach to a shell config file if not already present
add_tmux_block() {
  local rc_file="$1"
  local TMUX_BLOCK='
# Auto-start/attach tmux for interactive SSH sessions
if [ -n "$SSH_CONNECTION" ] && [ -z "$TMUX" ] && [ -z "$NO_TMUX" ]; then
  exec tmux new-session -A -s work
fi
'
  if ! grep -Fq 'exec tmux new-session -A -s work' "$rc_file" 2>/dev/null; then
    printf "\n%s\n" "$TMUX_BLOCK" >> "$rc_file"
    echo "   Added tmux auto-attach block to $rc_file"
  else
    echo "   tmux auto-attach block already present in $rc_file"
  fi
}

add_tmux_block "$HOME/.zshrc"
add_tmux_block "$HOME/.bashrc"

echo "==> Done. You may need to restart your shell/terminal for PATH changes to take effect."
