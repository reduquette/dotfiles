# Dotfiles

Personal development environment configuration.

## What's included

- **Shell** — `.zshrc` (zsh: brew, fzf, PATH, SSH agent, tmux auto-attach) and `.bashrc` (shared: brew, PATH, SSH agent, jj wrapper — also sourced by `.zshrc` so Claude Code's bash sessions get the same tools)
- **Git** — `.gitconfig` with commit signing, global ignore
- **Jujutsu (jj)** — config for jj version control, including dd-source-specific settings
- **tmux** — mouse support, scrollback, SSH agent forwarding
- **Cursor** — editor settings and rules (jujutsu workflow)
- **Claude Code** — `CLAUDE.md` preferences, plugin config
- **Tools** — `Brewfile` for declarative dev tool installation

## Setup

```sh
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
bash install.sh
```

The install script:

1. Symlinks all dotfiles into `$HOME`
2. Installs Homebrew and dev tools (from `Brewfile`)
3. Symlinks `.zshrc` and `.bashrc` (shell config is in the dotfiles, no separate init layer)
4. Sets up ddtool credential helpers
5. Initializes jj in dd-source (if present)
6. Deploys Cursor rules to project directories
