# react-devcontainer

> Blank-canvas base Docker image for VS Code Dev Containers.
> One image, shared across all your React projects.

**Node.js 24 LTS · pnpm 10 · Bun · TypeScript · GitHub CLI · Starship**

[![Docker Build](https://github.com/alihaidar0/react-devcontainer/actions/workflows/docker.yml/badge.svg)](https://github.com/alihaidar0/react-devcontainer/actions/workflows/docker.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/alihaidar0/react-devcontainer)](https://hub.docker.com/r/alihaidar0/react-devcontainer)
[![Image Size](https://img.shields.io/docker/image-size/alihaidar0/react-devcontainer/latest)](https://hub.docker.com/r/alihaidar0/react-devcontainer)

```bash
docker pull alihaidar0/react-devcontainer:latest
```

---

## Overview

Every React project needs the same developer tooling: Node.js, a package manager, a type checker, Git, and a productive terminal. Configuring this from scratch on every machine wastes time and produces inconsistent environments.

This repository solves that problem with a single shared base image. Push a change here and all your React projects get the upgrade on the next `docker pull` — without touching any project code.

**This repo has one job:** build and publish the base development Docker image to Docker Hub.

It contains no React files, no project-specific configuration, and no application code. React itself, Vite, Tailwind, TanStack Query, and every other project-level package are installed per project with `pnpm add` after the container starts.

---

## Architecture

This image is one half of a two-repo system.

| Repo | Responsibility |
|---|---|
| `react-devcontainer` ← **you are here** | Build and publish the base dev image |
| `react-template` | GitHub Template — the starting point for every new React project |

When you open a React project that uses this image, the container starts via Docker Compose with your project folder mounted at `/workspace` and your Git identity and SSH keys available for pushing to GitHub.

---

## What's Inside

| Category | Tool | Version | Purpose |
|---|---|---|---|
| **Runtime** | Node.js | 24 LTS (`bookworm-slim`) | Language runtime — pinned Debian release for reproducible builds |
| **Package manager** | pnpm | 10.33.0 | Fast, disk-efficient package manager — pinned, Dependabot-tracked |
| **Runtime / Bundler** | Bun | 1.3.11 | Ultra-fast JS runtime and bundler — copied from official image |
| **Version control** | Git + GitHub CLI | latest | Source control and GitHub operations from the terminal |
| **SSH** | openssh-client | — | Enables `git push` via SSH from inside the container |
| **Code quality** | TypeScript (`tsc`) | latest | Global type compiler |
| **Code quality** | tsx | latest | Run TypeScript files directly without a compile step |
| **Dependency management** | npm-check-updates | latest | Interactive dependency upgrade tool — project-agnostic |
| **Shell** | Starship | latest | Terminal prompt showing git branch, Node version, git status |
| **Utilities** | curl, wget, jq, vim, nano, htop, tree | — | Shell and network utilities |
| **Build tools** | build-essential, python3 | — | Required by node-gyp for native Node modules |

### What is NOT inside

These are intentionally absent. Install them per project with `pnpm add`:

```
React / ReactDOM        →  pnpm add react react-dom
Vite                    →  pnpm create vite@latest . --template react-ts
Next.js                 →  pnpm create next-app@latest .
Tailwind CSS            →  pnpm add -D tailwindcss
TanStack Query          →  pnpm add @tanstack/react-query
Zustand                 →  pnpm add zustand
React Router            →  pnpm add react-router-dom
Vitest / Playwright     →  pnpm add -D vitest @playwright/test
Biome / ESLint          →  pnpm add -D @biomejs/biome
knip                    →  pnpm add -D knip
```

---

## Repository Structure

```
react-devcontainer/
├── .github/
│   ├── CODEOWNERS                        ← Auto-requests reviewer on every PR
│   ├── dependabot.yml                    ← Weekly auto-updates for Actions + Docker base images
│   ├── labels.yml                        ← Label definitions — name, color, description
│   └── workflows/
│       ├── docker.yml                    ← Builds + pushes image on push/PR to main
│       ├── dockerhub-description.yml     ← Syncs README.md to Docker Hub on push to main
│       └── labels.yml                    ← Syncs labels.yml to GitHub labels
├── docker/
│   └── Dockerfile.dev                    ← The image recipe ← MAIN FILE
├── scripts/
│   └── shell_setup.sh                    ← Installs Starship + bakes aliases into the image
├── .dockerignore                         ← Excludes unnecessary files from the build context
├── .gitignore                            ← Ensures secrets are never committed
└── README.md                             ← This file — also synced to Docker Hub
```

---

## GitHub Automation

Five files under `.github/` handle everything automatically.

### Workflow trigger summary

| File | Trigger | What happens |
|---|---|---|
| `workflows/docker.yml` | Push to `main` (`docker/`, `scripts/` changed) | Builds + pushes `:latest` + `:sha-xxx` to Docker Hub |
| `workflows/docker.yml` | PR targeting `main` (same path filter) | Builds only — validates Dockerfile, never pushes |
| `workflows/docker.yml` | Manual dispatch | Builds + pushes, with force-rebuild and push toggle |
| `workflows/dockerhub-description.yml` | Push to `main` (`README.md` changed) | Updates Docker Hub description |
| `workflows/dockerhub-description.yml` | PR targeting `main` (`README.md` changed) | Runs but skips update until merged |
| `workflows/dockerhub-description.yml` | Manual dispatch | Forces immediate Docker Hub sync |
| `workflows/labels.yml` | Push to `main` (`.github/labels.yml` changed) | Syncs all labels to GitHub |
| `workflows/labels.yml` | Manual dispatch | Bootstrap all labels in one go |
| `dependabot.yml` | Every Monday 09:00 UTC | Scans Actions + Docker, opens PRs against `main` |

### `workflows/docker.yml`

Builds the multi-platform Docker image (`linux/amd64` + `linux/arm64`) and pushes it to Docker Hub. Path-filtered so a README change never triggers an unnecessary rebuild. PR builds validate the Dockerfile without pushing — only merged pushes publish to Docker Hub. Generates SBOM and provenance attestations on every build.

> **Note:** On `pull_request` events (including Dependabot PRs), GitHub withholds repository secrets by design. The workflow handles this correctly — login and push are both skipped on PRs, so the build validates the Dockerfile without needing credentials.

### `workflows/dockerhub-description.yml`

Syncs `README.md` to the Docker Hub repository description page on every `README.md` change merged to `main`. PRs trigger the workflow for the GitHub check but skip the actual Docker Hub update until merged.

### `workflows/labels.yml`

Keeps GitHub repository labels in sync with `.github/labels.yml`. Labels are version-controlled — add or rename a label in the file, push, and GitHub reflects the change automatically. Supports manual dispatch for first-time bootstrapping.

### `dependabot.yml`

Automatically monitors two ecosystems and opens PRs when updates are found: all GitHub Actions versions used in workflows, and both Docker base images in `Dockerfile.dev` (`node:24-bookworm-slim` and `oven/bun:1.3.11-slim`). Runs every Monday at 09:00 UTC.

---

## How the Build Works

```
Push to main (Dockerfile or scripts changed)
  → GitHub Actions detects the change
  → Builds linux/amd64 + linux/arm64 in parallel using layer cache
  → Pushes :latest and :sha-<commit> to Docker Hub
  → Syncs README to Docker Hub description
  → Job summary written to Actions log

PR targeting main (Dockerfile or scripts changed)
  → GitHub Actions detects the change
  → Builds linux/amd64 + linux/arm64 to validate
  → Does NOT push — PR check goes green or red
  → Merge when green
```

The first build takes ~6 minutes (no cache). Subsequent builds complete in 1–2 minutes thanks to GitHub Actions layer caching.

---

## Platforms

| Platform | Architecture |
|---|---|
| Windows · Linux · GCP | `linux/amd64` |
| Apple Silicon Mac | `linux/arm64` |

Docker pulls the correct platform automatically.

---

## Tags

| Tag | Published when |
|---|---|
| `latest` | Every push to `main` |
| `sha-xxxxxxx` | Every build — pin to this for rollback |

---

## Shell Aliases

All aliases are defined in `scripts/shell_setup.sh` and baked into the image.

### pnpm

| Alias | Expands to | Notes |
|---|---|---|
| `pi` | `pnpm install` | Install all dependencies |
| `pa` | `pnpm add` | Add a package |
| `pad` | `pnpm add -D` | Add a dev dependency |
| `prm` | `pnpm remove` | Remove a package |
| `pr` | `pnpm run` | Run a script |
| `pd` | `pnpm dev` | Start Vite dev server |
| `pb` | `pnpm build` | Production build |
| `pt` | `pnpm test` | Run Vitest |
| `ptw` | `pnpm test --watch` | Run Vitest in watch mode |
| `pte` | `pnpm test:e2e` | Run Playwright e2e tests |
| `pl` | `pnpm lint` | Biome lint |
| `plf` | `pnpm lint:fix` | Biome lint + auto-fix |
| `pf` | `pnpm format` | Biome format |
| `ptype` | `pnpm typecheck` | TypeScript check |
| `pup` | `pnpm update --interactive` | Interactive dependency updater |
| `pls` | `pnpm list` | List installed packages |
| `pstore` | `pnpm store prune` | Clean pnpm content-addressable store |

### Vite

| Alias | Expands to |
|---|---|
| `vd` | `pnpm vite --host 0.0.0.0` |
| `vb` | `pnpm vite build` |
| `vp` | `pnpm vite preview` |

### Git

| Alias | Expands to |
|---|---|
| `gs` | `git status` |
| `ga` | `git add` |
| `gc` | `git commit -m` |
| `gp` | `git push` |
| `gl` | `git log --oneline --graph --decorate` |
| `gco` | `git checkout` |
| `gb` | `git branch` |

### Utilities

| Alias | Expands to |
|---|---|
| `ll` | `ls -alFh --color=auto` |
| `la` | `ls -A --color=auto` |
| `cls` | `clear` |

---

## Updating the Image

### Upgrading Node.js

Edit `ARG NODE_VERSION` in `docker/Dockerfile.dev`. The `ARG` is declared in global scope (before the first `FROM`) so it applies to the `FROM node:...` line correctly across the multi-stage build.

```dockerfile
ARG NODE_VERSION=26
```

Verify the tag exists at [hub.docker.com/_/node/tags](https://hub.docker.com/_/node/tags) first. Commit, push to a branch, open a PR against `main`. The PR build validates the new version. Merge when green — image publishes automatically.

### Upgrading pnpm

Update `ENV PNPM_VERSION` in `docker/Dockerfile.dev`:

```dockerfile
ENV PNPM_VERSION=10.34.0
```

Dependabot will raise this PR automatically every Monday.

### Upgrading Bun

Update the `FROM oven/bun` line in `docker/Dockerfile.dev`:

```dockerfile
FROM oven/bun:1.3.12-slim AS bun-binary
```

Dependabot tracks this `FROM` line and will raise a PR automatically.

### Adding a system package

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
    your-new-tool \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
```

### Adding a global Node tool

Only add tools here that are genuinely project-agnostic (no project config, no version sensitivity). If the tool has native binaries built by post-install scripts, approve it explicitly:

```dockerfile
RUN pnpm add -g \
    typescript \
    tsx \
    npm-check-updates \
    your-new-tool \
    && pnpm approve-builds -g esbuild your-new-tool-if-needed
```

---

## Troubleshooting

### Build fails — authentication error

**Symptom:** `denied: requested access to the resource is denied`

1. Go to **Settings → Secrets and variables → Actions**
2. Confirm both `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` are present
3. Confirm the token has **Read, Write & Delete** scope — Read-only tokens cannot push
4. If expired: Docker Hub → **Account Settings → Personal access tokens** → delete → create new → update secret
5. Re-run from the **Actions** tab

### Build fails — invalid image tag on pull_request

**Symptom:** `ERROR: failed to build: invalid tag "/react-devcontainer:sha-xxxxxxx": invalid reference format`

**Cause:** On `pull_request` events, GitHub withholds all repository secrets by design — including `DOCKERHUB_USERNAME`. If the image name is built from that secret it resolves to an empty string, producing a leading `/` in the tag.

**Fix:** The `IMAGE_NAME` env var in `docker.yml` is hardcoded directly:

```yaml
env:
  IMAGE_NAME: alihaidar0/react-devcontainer
```

The Docker Hub username is not sensitive — hardcoding it removes the dependency on secrets for the image name entirely. The `DOCKERHUB_TOKEN` secret is still used for login, but that step is already gated with `if: github.event_name != 'pull_request'` and is never reached during PR builds.

### Build fails — NODE_VERSION empty, invalid stage name

**Symptom:** `failed to parse stage name "node:-bookworm-slim": invalid reference format`

**Cause:** In a multi-stage Dockerfile, `ARG` declarations are scoped to the stage they appear in. If `ARG NODE_VERSION` is declared after the first `FROM`, it is inside that stage's scope and is not visible to subsequent `FROM` lines.

**Fix:** `ARG NODE_VERSION` is declared before the first `FROM` (global scope), then re-declared inside Stage 2 for use within that stage's instructions:

```dockerfile
ARG NODE_VERSION=24          # global — visible to all FROM lines

FROM oven/bun:1.3.11-slim AS bun-binary

ARG NODE_VERSION             # re-declare inside Stage 2 (no default needed)
FROM node:${NODE_VERSION}-bookworm-slim AS base
```

### Build fails — Node image not found

**Symptom:** `manifest unknown` for `node:XX-bookworm-slim`

Check [hub.docker.com/_/node/tags](https://hub.docker.com/_/node/tags) and update `ARG NODE_VERSION` to an existing tag.

### `git push` fails — permission denied (publickey)

```bash
ssh-add -l                                         # check loaded keys
ssh-add "%USERPROFILE%\.ssh\id_ed25519"            # Windows — load key
ssh-add ~/.ssh/id_ed25519                          # macOS / Linux
ssh -T git@github.com                              # verify auth
git remote set-url origin git@github.com:YOUR_USERNAME/react-devcontainer.git
```

**On Windows after restart:**
```cmd
sc config ssh-agent start= auto
net start ssh-agent
```

### Docker Desktop — cannot connect

1. Wait for the taskbar whale icon to stop animating
2. Right-click whale → **Restart Docker Desktop**
3. Task Manager → end all `Docker Desktop` processes → reopen

---

## Related Repositories

| Repo | Purpose |
|---|---|
| [`react-devcontainer`](https://github.com/alihaidar0/react-devcontainer) | ← You are here — builds the Docker image |
| [`react-template`](https://github.com/alihaidar0/react-template) | React project template — pulls this image for development |

---

*Node.js 24 LTS · pnpm 10.33.0 · Bun 1.3.11 · Debian 12 Bookworm · 2026*
