#!/usr/bin/env bash
set -euo pipefail

DOTFILES_PATH="$HOME/dotfiles"
OS="$(uname)"
ARCH="$(uname -m)"


# Symlink dotfiles into $HOME (only files whose paths start with ".")
find "$DOTFILES_PATH" -type f -path "$DOTFILES_PATH/.*" \
  -not -path "$DOTFILES_PATH/.git/*" \
  -not -path "$DOTFILES_PATH/.jj/*" \
  -not -path "$DOTFILES_PATH/.claude/*" \
  -not -name .DS_Store \
  -not -name .gitignore |
while read -r df; do
  link=${df/$DOTFILES_PATH/$HOME}
  mkdir -p "$(dirname "$link")"
  ln -sf "$df" "$link"
done

mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"


# ---------------------------------------------------------------------------
# Tool installation
# ---------------------------------------------------------------------------

# starpls: Starlark LSP (not available via Homebrew)
install_starpls() {
  if command -v starpls >/dev/null 2>&1; then
    echo "   starpls already installed"
    return
  fi
  echo "   Installing starpls from GitHub releases"
  case "$OS-$ARCH" in
    Darwin-arm64)   _STARPLS_ASSET="starpls-darwin-arm64" ;;
    Darwin-x86_64)  _STARPLS_ASSET="starpls-darwin-amd64" ;;
    Linux-x86_64)   _STARPLS_ASSET="starpls-linux-amd64" ;;
    Linux-aarch64)  _STARPLS_ASSET="starpls-linux-aarch64" ;;
    *)              _STARPLS_ASSET="" ;;
  esac
  if [ -z "$_STARPLS_ASSET" ]; then
    echo "   Warning: unsupported platform $OS-$ARCH for starpls"
    return
  fi
  _STARPLS_TAG=$(curl -fsSI "https://github.com/withered-magic/starpls/releases/latest" 2>/dev/null \
    | grep -i '^location:' | sed 's|.*/||' | tr -d '\r\n')
  if [ -n "$_STARPLS_TAG" ]; then
    curl -fsSL "https://github.com/withered-magic/starpls/releases/download/${_STARPLS_TAG}/${_STARPLS_ASSET}.tar.gz" \
      | tar xz -C "$HOME/.local/bin" starpls 2>/dev/null \
      && chmod +x "$HOME/.local/bin/starpls" \
      && echo "   Installed starpls ${_STARPLS_TAG}" \
      || echo "   Warning: failed to download starpls"
  else
    echo "   Warning: could not determine latest starpls release"
  fi
}

# Platform-specific

install_tools_macos() {
  echo "==> Installing tools via Homebrew (macOS)"

  export HOMEBREW_INSTALL_FROM_API=1
  export HOMEBREW_NO_AUTO_UPDATE=1

  if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  if ! command -v brew >/dev/null 2>&1; then
    test -d /opt/homebrew && eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  brew tap datadog/tap git@github.com:DataDog/homebrew-tap 2>/dev/null || brew tap datadog/tap 2>/dev/null || true
  brew update
  brew bundle --no-lock --file="$DOTFILES_PATH/Brewfile" || true

  # Symlink brew tools into ~/.local/bin so they're available in
  # non-interactive shells (e.g. Cursor extension host, agent shell).
  for tool in jj watchman tmux fzf orgstore ddtool atlas buildifier bzl; do
    tool_path="$(brew --prefix)/bin/$tool"
    if [ -x "$tool_path" ] && [ ! -e "$HOME/.local/bin/$tool" ]; then
      ln -sf "$tool_path" "$HOME/.local/bin/$tool"
      echo "   Symlinked $tool into ~/.local/bin"
    fi
  done
}

install_tools_linux() {
  echo "==> Installing tools (Linux)"

  # System packages via apt
  if command -v apt-get >/dev/null 2>&1; then
    local apt_pkgs=()
    command -v tmux  >/dev/null 2>&1 || apt_pkgs+=(tmux)
    command -v node  >/dev/null 2>&1 || apt_pkgs+=(nodejs npm)

    if [ ${#apt_pkgs[@]} -gt 0 ]; then
      echo "   Installing via apt: ${apt_pkgs[*]}"
      sudo apt-get update -qq 2>/dev/null || true
      sudo apt-get install -y -qq "${apt_pkgs[@]}" 2>/dev/null || echo "   Warning: apt install failed for some packages"
    fi
  fi

  # fzf: direct binary from GitHub releases (apt version on Ubuntu 22.04 is too old)
  if ! command -v fzf >/dev/null 2>&1; then
    echo "   Installing fzf from GitHub releases"
    case "$ARCH" in
      x86_64)  _FZF_ARCH="linux_amd64" ;;
      aarch64) _FZF_ARCH="linux_arm64" ;;
      *)       _FZF_ARCH="" ;;
    esac
    if [ -n "$_FZF_ARCH" ]; then
      _FZF_TAG=$(curl -fsSI "https://github.com/junegunn/fzf/releases/latest" 2>/dev/null \
        | grep -i '^location:' | sed 's|.*/||' | tr -d '\r\n')
      if [ -n "$_FZF_TAG" ]; then
        _FZF_VER="${_FZF_TAG#v}"
        curl -fsSL "https://github.com/junegunn/fzf/releases/download/${_FZF_TAG}/fzf-${_FZF_VER}-${_FZF_ARCH}.tar.gz" \
          | tar xz -C "$HOME/.local/bin" fzf \
          && echo "   Installed fzf ${_FZF_TAG}" \
          || echo "   Warning: failed to download fzf"
      else
        echo "   Warning: could not determine latest fzf release"
      fi
    else
      echo "   Warning: unsupported architecture $ARCH for fzf"
    fi
  else
    echo "   fzf already installed"
  fi

  # jj: direct binary from GitHub releases
  if ! command -v jj >/dev/null 2>&1; then
    echo "   Installing jj from GitHub releases"
    case "$ARCH" in
      x86_64)  _JJ_ARCH="x86_64-unknown-linux-musl" ;;
      aarch64) _JJ_ARCH="aarch64-unknown-linux-musl" ;;
      *)       _JJ_ARCH="" ;;
    esac
    if [ -n "$_JJ_ARCH" ]; then
      _JJ_TAG=$(curl -fsSI "https://github.com/jj-vcs/jj/releases/latest" 2>/dev/null \
        | grep -i '^location:' | sed 's|.*/||' | tr -d '\r\n')
      if [ -n "$_JJ_TAG" ]; then
        curl -fsSL "https://github.com/jj-vcs/jj/releases/download/${_JJ_TAG}/jj-${_JJ_TAG}-${_JJ_ARCH}.tar.gz" \
          | tar xz -C "$HOME/.local/bin" ./jj \
          && echo "   Installed jj ${_JJ_TAG}" \
          || echo "   Warning: failed to download jj"
      else
        echo "   Warning: could not determine latest jj release"
      fi
    else
      echo "   Warning: unsupported architecture $ARCH for jj"
    fi
  else
    echo "   jj already installed"
  fi

  # watchman: try apt, otherwise warn (needed for jj fsmonitor in large repos)
  if ! command -v watchman >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get install -y -qq watchman 2>/dev/null || true
    fi
    if ! command -v watchman >/dev/null 2>&1; then
      echo "   Warning: watchman not available (jj fsmonitor will be slower in large repos)"
    fi
  fi

  # DD tools (orgstore, ddtool, atlas): only available via Homebrew.
  # On BITS workspaces these are typically pre-provisioned. To install
  # manually: https://brew.sh then brew install datadog/tap/ddtool
  # if command -v brew >/dev/null 2>&1; then
  #   echo "   Installing DD tools via Homebrew"
  #   export HOMEBREW_NO_AUTO_UPDATE=1
  #   brew tap datadog/tap git@github.com:DataDog/homebrew-tap 2>/dev/null || brew tap datadog/tap 2>/dev/null || true
  #   for pkg in orgstore datadog/tap/ddtool datadog/tap/atlas; do
  #     brew install "$pkg" 2>/dev/null || echo "   Warning: failed to install $pkg"
  #   done
  #   for tool in orgstore ddtool atlas buildifier bzl starpls; do
  #     tool_path="$(brew --prefix)/bin/$tool"
  #     if [ -x "$tool_path" ] && [ ! -e "$HOME/.local/bin/$tool" ]; then
  #       ln -sf "$tool_path" "$HOME/.local/bin/$tool"
  #     fi
  #   done
  # fi
}

if [[ "$OS" == "Darwin" ]]; then
  install_tools_macos
else
  install_tools_linux
fi

install_starpls


echo "==> Configuring shell init"

# .zshrc and .bashrc are managed as dotfiles and symlinked by the loop above.
# Ensure ~/.bash_profile sources ~/.bashrc for macOS login shells (which read
# .bash_profile instead of .bashrc, so without this bash login shells would
# miss PATH, SSH agent, etc.).
if ! grep -Fq '. ~/.bashrc' ~/.bash_profile 2>/dev/null; then
  printf '\n# Source .bashrc if it exists (for macOS login shells)\nif [ -f ~/.bashrc ]; then\n  . ~/.bashrc\nfi\n' >> ~/.bash_profile
  echo "   Added .bashrc sourcing to ~/.bash_profile"
else
  echo "   ~/.bash_profile already sources ~/.bashrc"
fi


echo "==> Configuring ddtool"

_DDTOOL_BIN="$(command -v ddtool 2>/dev/null || true)"
if [ -x "${_DDTOOL_BIN}" ]; then
  "${_DDTOOL_BIN}" auth helpers install 2>/dev/null || echo "   Skipped ddtool auth helpers (may need VPN/AppGate)"
  "${_DDTOOL_BIN}" clusters context install-dctx 2>/dev/null || echo "   Skipped ddtool install-dctx (may need VPN/AppGate)"
else
  echo "   ddtool not found (skipping credential helpers)"
fi


echo "==> Configuring dd-source repository (if present)"

# Find dd-source: check DD_SOURCE_PATH env var, then common locations
for _candidate in "${DD_SOURCE_PATH:-}" "$HOME/dd/dd-source" "$HOME/go/src/github.com/DataDog/dd-source"; do
  [ -n "$_candidate" ] && [ -d "$_candidate/.git" ] && DD_SOURCE_PATH="$_candidate" && break
done
unset _candidate 2>/dev/null || true

if [ -n "${DD_SOURCE_PATH:-}" ] && [ -d "$DD_SOURCE_PATH/.git" ]; then
  # Initialize jj if not already colocated with git
  if [ ! -d "$DD_SOURCE_PATH/.jj" ]; then
    echo "   Initializing jj in dd-source repository"
    (cd "$DD_SOURCE_PATH" && jj git init --colocate)
  else
    echo "   jj already initialized in dd-source"
  fi

  # Apply dd-source-specific jj config to the path jj actually uses
  if [ -f "$DOTFILES_PATH/.config/jj/dd-source-config.toml" ]; then
    JJ_REPO_CONFIG="$(cd "$DD_SOURCE_PATH" && jj config path --repo 2>/dev/null)"
    if [ -n "$JJ_REPO_CONFIG" ]; then
      mkdir -p "$(dirname "$JJ_REPO_CONFIG")"
      cp "$DOTFILES_PATH/.config/jj/dd-source-config.toml" "$JJ_REPO_CONFIG"
      echo "   Applied dd-source jj config to $JJ_REPO_CONFIG"
    else
      echo "   Warning: could not determine jj repo config path (jj config path --repo failed)"
    fi
  else
    echo "   Warning: dd-source-config.toml not found in dotfiles"
  fi

  # Configure dd-source git hooks
  echo "   Configuring dd-source git hooks"
  (cd "$DD_SOURCE_PATH" && git config --local ddsource.hooks.pre-push.gazelle true)
  (cd "$DD_SOURCE_PATH" && git config --local ddsource.hooks.pre-push.gofmt true)
  # Wire up local pre-push hook (called by run-local-hooks in the global pre-push hook)
  mkdir -p "$DD_SOURCE_PATH/.git/hooks"
  ln -sf "$HOME/.local/bin/dd-source-gofmt-hook" "$DD_SOURCE_PATH/.git/hooks/pre-push"
  echo "   Linked dd-source-gofmt-hook as .git/hooks/pre-push"

  echo "   Skipping bookmark fetch (SSH not available during provisioning; run ~/dotfiles/setup-ssh.sh after first login)"
else
  echo "   dd-source repository not found (skipping; set DD_SOURCE_PATH or use ~/dd/dd-source or ~/go/src/github.com/DataDog/dd-source)"
fi


echo "==> Deploying Cursor rules to project directories"

deploy_cursor_rules() {
  local project_dir="$1"
  if [ -d "$project_dir" ]; then
    local rules_dir="$project_dir/.cursor/rules"
    mkdir -p "$rules_dir"
    for rule in "$DOTFILES_PATH/.config/cursor/rules/"*.mdc; do
      [ -f "$rule" ] || continue
      cp "$rule" "$rules_dir/$(basename "$rule")"
    done
    echo "   Deployed Cursor rules to $rules_dir"
  fi
}

deploy_cursor_rules "${DD_SOURCE_PATH:-}"
# Add more project directories here as needed:
# deploy_cursor_rules "$HOME/other-project"


echo "==> Deploying Claude Code global config"

mkdir -p "$HOME/.claude"
ln -sf "$DOTFILES_PATH/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
echo "   Symlinked CLAUDE.md -> ~/.claude/CLAUDE.md"


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


echo "==> Deploying Claude Code memory for dd-source"

_CLAUDE_MEMORY_SRC="$DOTFILES_PATH/.config/claude/dd-source-memory"
_CLAUDE_MEMORY_DEST="$HOME/.claude/projects/-home-bits-go-src-github-com-DataDog-dd-source/memory"
if [ -d "$_CLAUDE_MEMORY_SRC" ]; then
  mkdir -p "$(dirname "$_CLAUDE_MEMORY_DEST")"
  if [ -L "$_CLAUDE_MEMORY_DEST" ]; then
    echo "   Claude memory already symlinked"
  elif [ -d "$_CLAUDE_MEMORY_DEST" ] && [ ! -L "$_CLAUDE_MEMORY_DEST" ]; then
    echo "   Warning: $_CLAUDE_MEMORY_DEST exists as a real directory — skipping symlink"
    echo "   To fix: rm -rf $_CLAUDE_MEMORY_DEST && run install.sh again"
  else
    ln -s "$_CLAUDE_MEMORY_SRC" "$_CLAUDE_MEMORY_DEST"
    echo "   Symlinked Claude memory -> $_CLAUDE_MEMORY_DEST"
  fi
fi


echo "==> Done"
echo ""
echo "   SSH-dependent setup was skipped (not available during provisioning)."
echo "   After your first SSH login, run:  ~/dotfiles/setup-ssh.sh"
echo "   This will configure the git HTTPS→SSH rewrite and fetch your personal jj bookmarks."
