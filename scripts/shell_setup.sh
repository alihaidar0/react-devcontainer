#!/usr/bin/env bash
# ============================================================
#  scripts/shell_setup.sh
#  Runs during Docker image build.
#  Installs: Starship prompt + shell aliases
# ============================================================
set -euo pipefail

# Install Starship prompt
curl -sS https://starship.rs/install.sh | sh -s -- --yes

# ── Starship configuration ────────────────────────────────────
mkdir -p /root/.config
cat > /root/.config/starship.toml << 'STARSHIP'
format = """
[╭─](bold cyan)$directory$git_branch$git_status$nodejs$package
[╰─❯](bold cyan) """

[directory]
style = "bold blue"
truncation_length = 4
truncate_to_repo = true

[git_branch]
symbol = " "
style = "bold purple"

[git_status]
style = "bold red"

[nodejs]
symbol = " "
style = "bold green"
format = "[$symbol$version]($style) "

[package]
symbol = "📦 "
style = "bold yellow"
format = "[$symbol$version]($style) "
STARSHIP

# ── Bash configuration ────────────────────────────────────────
cat >> /root/.bashrc << 'BASHRC'
# Starship prompt
eval "$(starship init bash)"

# ── Shell history ─────────────────────────────────────────────
export HISTFILE=/root/.shell_history/.bash_history
export HISTSIZE=50000
export HISTFILESIZE=50000
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend

# ── pnpm aliases ──────────────────────────────────────────────
alias pi="pnpm install"
alias pa="pnpm add"
alias pad="pnpm add -D"
alias prm="pnpm remove"
alias pr="pnpm run"
alias pd="pnpm dev"
alias pb="pnpm build"
alias pt="pnpm test"
alias ptw="pnpm test --watch"
alias pte="pnpm test:e2e"
alias pl="pnpm lint"
alias plf="pnpm lint:fix"
alias pf="pnpm format"
alias ptype="pnpm typecheck"
alias pup="pnpm update --interactive"
alias pls="pnpm list"
alias pstore="pnpm store prune"

# ── Vite aliases ──────────────────────────────────────────────
alias vd="pnpm vite --host 0.0.0.0"
alias vb="pnpm vite build"
alias vp="pnpm vite preview"

# ── Git aliases ───────────────────────────────────────────────
alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gl="git log --oneline --graph --decorate"
alias gco="git checkout"
alias gb="git branch"

# ── Utility aliases ───────────────────────────────────────────
alias ll="ls -alFh --color=auto"
alias la="ls -A --color=auto"
alias cls="clear"

# ── Environment ───────────────────────────────────────────────
export TERM=xterm-256color
export CLICOLOR=1
export PNPM_HOME="/root/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
BASHRC

# Persist shell history across container restarts
mkdir -p /root/.shell_history

echo "✅ Shell setup complete"