# Managed shell init — sourced from .zshrc and .bashrc
# Installed by dotfiles/install.sh

# Homebrew
if [ -d /opt/homebrew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -d "$HOME/.linuxbrew" ]; then
  eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
elif [ -d /home/linuxbrew/.linuxbrew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

# fzf shell integration
if command -v fzf >/dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    source <(fzf --zsh)
  elif [ -n "$BASH_VERSION" ]; then
    eval "$(fzf --bash)"
  fi
fi

# Wrap jj to run pre-push checks before pushing
jj() {
  if [ "$1/$2" = "git/push" ] && command -v pre-push-checks >/dev/null 2>&1; then
    echo "Running pre-push checks..."
    pre-push-checks || { echo "Pre-push checks failed; push aborted."; return 1; }
  fi
  command jj "$@"
}

# Use the stable SSH agent symlink maintained by update-ssh-agent-socket.sh
# so new shells (tmux panes, etc.) don't lose agent forwarding
export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"

# Auto-start/attach tmux for interactive SSH sessions
if [ -n "$SSH_CONNECTION" ] && [ -z "$TMUX" ] && [ -z "$NO_TMUX" ] && command -v tmux >/dev/null 2>&1; then
  exec tmux new-session -A -s work
fi
