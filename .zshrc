# ~/.zshrc — interactive zsh config.
#
# Shared tool config (PATH, Homebrew, SSH agent, jj) lives in .bashrc so that
# Claude Code's bash sessions get it too. Source it first so everything defined
# there is available here.
source "$HOME/.bashrc"

# Oh My Zsh — theme and plugin framework.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source "$ZSH/oh-my-zsh.sh"

# fzf — fuzzy finder for history (ctrl-r), files (ctrl-t), and cd (alt-c).
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# Auto-start/attach tmux on SSH login — keeps the session alive across reconnects
# and makes it easy to resume work. Set NO_TMUX=1 to skip (e.g. for one-off
# commands or when connecting from an IDE terminal that handles its own sessions).
if [ -n "$SSH_CONNECTION" ] && [ -z "$TMUX" ] && [ -z "$NO_TMUX" ] && command -v tmux >/dev/null 2>&1; then
  exec tmux new-session -A -s work
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
