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

# Install linuxbrew if missing (pattern used in internal Workspaces docs) :contentReference[oaicite:5]{index=5}
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
  test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.bashrc
fi

# Ensure brew is on PATH for this session
eval "$("$(brew --prefix)"/bin/brew shellenv)"

brew install jj watchman

echo "==> Configuring dd-source repository (if present)"

# Apply dd-source-specific jj config to ~/dd/dd-source
DD_SOURCE_PATH="$HOME/dd/dd-source"
if [ -d "$DD_SOURCE_PATH/.git" ]; then
  # Initialize jj if not already colocated with git
  if [ ! -d "$DD_SOURCE_PATH/.jj" ]; then
    echo "   Initializing jj in dd-source repository"
    (cd "$DD_SOURCE_PATH" && jj git init --colocate)
  else
    echo "   jj already initialized in dd-source"
  fi

  # Apply dd-source-specific config
  DD_SOURCE_CONFIG="$DD_SOURCE_PATH/.jj/repo/config.toml"
  mkdir -p "$(dirname "$DD_SOURCE_CONFIG")"

  if [ -f "$DOTFILES_PATH/.config/jj/dd-source-config.toml" ]; then
    cp "$DOTFILES_PATH/.config/jj/dd-source-config.toml" "$DD_SOURCE_CONFIG"
    echo "   Applied dd-source jj config to $DD_SOURCE_CONFIG"
  else
    echo "   Warning: dd-source-config.toml not found in dotfiles"
  fi
else
  echo "   dd-source repository not found at $DD_SOURCE_PATH (skipping)"
fi

echo "==> Done. You may need to restart your shell/terminal for PATH changes to take effect." :contentReference[oaicite:6]{index=6}
