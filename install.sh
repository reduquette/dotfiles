#!/usr/bin/env bash
set -euo pipefail

DOTFILES_PATH="$HOME/dotfiles"

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

# Install linuxbrew if missing
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Ensure brew is on PATH for this session (try common locations)
if ! command -v brew >/dev/null 2>&1; then
  test -d /opt/homebrew && eval "$(/opt/homebrew/bin/brew shellenv)"
  test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
  test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Add brew to shell config for zsh
if command -v brew >/dev/null 2>&1; then
  BREW_INIT="eval \"\$($(brew --prefix)/bin/brew shellenv)\""
  grep -qxF "$BREW_INIT" ~/.zshrc 2>/dev/null || echo "$BREW_INIT" >> ~/.zshrc
fi

# Install common dev tools
brew install jj watchman tmux

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
else
  echo "   dd-source repository not found at $DD_SOURCE_PATH (skipping)"
fi

echo "==> Configuring tmux auto-attach for SSH sessions"

# Add tmux auto-attach to .zshrc
ZSHRC="$HOME/.zshrc"
TMUX_BLOCK='
# Auto-start/attach tmux for interactive SSH sessions
if [ -n "$SSH_CONNECTION" ] && [ -z "$TMUX" ] && [ -z "$NO_TMUX" ]; then
 exec tmux new-session -A -s work
fi
'

if ! grep -Fq 'exec tmux new-session -A -s work' "$ZSHRC" 2>/dev/null; then
  printf "\n%s\n" "$TMUX_BLOCK" >> "$ZSHRC"
  echo "   Added tmux auto-attach block to $ZSHRC"
else
  echo "   tmux auto-attach block already present in $ZSHRC"
fi

echo "==> Done. You may need to restart your shell/terminal for PATH changes to take effect." :contentReference[oaicite:6]{index=6}
