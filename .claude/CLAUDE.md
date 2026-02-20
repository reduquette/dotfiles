# Global Development Preferences

## Version Control: Jujutsu (jj)

I use **jujutsu (jj)** instead of git for version control. All repositories are colocated (jj on top of git).

**Always prefer `jj` commands over `git` commands.**

### Command mapping

| Instead of | Use |
|---|---|
| `git status` | `jj status` |
| `git diff` | `jj diff` |
| `git log` | `jj log` |
| `git show <ref>` | `jj show <ref>` |
| `git add` + `git commit -m "…"` | `jj commit -m "…"` (or edit then `jj describe -m "…"`) |
| `git commit --amend` | `jj describe -m "…"` (update current change's description) |
| `git branch` | `jj bookmark list` |
| `git checkout -b <name>` | `jj new` then `jj bookmark set <name>` |
| `git push` | `jj git push` |
| `git fetch` | `jj git fetch` |
| `git rebase` | `jj rebase` |
| `git stash` | Not needed — jj auto-tracks working copy changes |
| `git reset --soft HEAD~1` | `jj squash` (fold into parent) or `jj abandon` |

### Key concepts

- Changes are identified by **change IDs** (short letters like `qpvuntsm`), not SHA hashes. Use change IDs when referring to revisions.
- There is **no staging area**. All file modifications in the working copy are automatically part of the current change.
- Use `jj new` to start a new empty change on top of the current one.
- Use `jj describe -m "message"` to set or update the current change's description.
- Use `jj commit -m "message"` to describe the current change AND create a new empty change on top.
- **Bookmarks** are jj's equivalent of git branches. Use `jj bookmark set <name>` to point a bookmark at the current change.
- Use `jj git push` to push bookmarks to the remote.

### Typical workflow

1. `jj new` — start a new change
2. Edit files (changes are automatically tracked)
3. `jj describe -m "what I did"` — describe the change
4. `jj bookmark set feature-name` — name it
5. `jj git push` — push to remote

### When git is still appropriate

- `gh` CLI for GitHub operations (PRs, issues) — works fine with colocated repos
- `git grep` for searching (or use `rg`/ripgrep instead)
- Reading git-specific metadata when jj doesn't expose it
