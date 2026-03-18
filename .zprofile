# Runs once on SSH login (login shell). Not sourced for each tmux pane.

# Refresh ddtool credentials once per day
[ -f "$HOME/dotfiles/daily-auth.sh" ] && . "$HOME/dotfiles/daily-auth.sh"
