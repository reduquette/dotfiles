# ~/.bashrc — sourced by bash for interactive sessions and by .zshrc for shared config.
#
# Claude Code runs bash, so anything needed by shell tools (PATH, SSH agent, jj)
# lives here so it's available in both zsh and bash sessions.

# Homebrew — sets PATH, MANPATH, INFOPATH.
# Handles all install locations: macOS Apple Silicon (/opt/homebrew),
# macOS Intel / Linux user install (~/.linuxbrew), Linux system install (/home/linuxbrew).
if [ -d /opt/homebrew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -d "$HOME/.linuxbrew" ]; then
  eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
elif [ -d /home/linuxbrew/.linuxbrew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Personal scripts and tool symlinks (jj, ddtool, starpls, etc.)
export PATH="$HOME/.local/bin:$PATH"

# SSH agent forwarding — point to the stable symlink maintained by
# ~/.local/bin/update-ssh-agent-socket.sh (watched by watch-ssh-agent-socket.sh).
# Without this, new shells (tmux panes, Claude Code sessions) won't inherit the
# forwarded agent socket from the original SSH session and can't authenticate to GitHub.
export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"

# jj wrapper — runs pre-push checks before `jj git push` to catch issues locally
# before they hit CI (gofmt, gazelle, etc. configured in dd-source git hooks).
jj() {
  if [ "$1/$2" = "git/push" ] && command -v pre-push-checks >/dev/null 2>&1; then
    echo "Running pre-push checks..."
    pre-push-checks || { echo "Pre-push checks failed; push aborted."; return 1; }
  fi
  command jj "$@"
}
