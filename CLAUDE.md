# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A **DDEV add-on** that installs the Claude Code CLI **inside** a project's DDEV web
container, so Claude shares the project's PHP, Node, Composer, and database — the same
environment as `ddev exec`. There is **no application code** here: the repo is shell
scripts, Dockerfile fragments, and DDEV YAML config. There is **no build step** — the
source files *are* the add-on.

## How a DDEV add-on works (the mental model)

On `ddev add-on get vanWittlaer/ddev-claude-code`, DDEV reads `install.yaml` and copies
the files listed under `project_files` into the **consuming project's `.ddev/`**
directory, where they are committed so teammates share them. So the files in this repo
are templates that land in *someone else's* `.ddev/`, not things that run here.

- Every copied file carries a `#ddev-generated` marker. That marker is load-bearing:
  it lets `ddev add-on remove` delete the files automatically (hence empty
  `removal_actions`) and lets a later `ddev add-on get` overwrite them **only if
  unmodified**. **Never remove or alter that marker line.**
- `install.yaml` is the manifest: `project_files` (what gets copied),
  `ddev_version_constraint`, and `post_install_actions` (chmod the command, print the
  "run `ddev restart`" reminder). The restart is required because the add-on extends the
  web image via a `web-build` Dockerfile, so the container must rebuild before the
  `claude` binary exists.

## File-by-file (and the invariants to preserve)

| File | Lands at | Role |
|---|---|---|
| `web-build/Dockerfile.claude` | `.ddev/web-build/` | Installs the Claude CLI for the web user. Uses `${username}` — a build arg **DDEV injects** into web-build Dockerfiles; don't hardcode a user. |
| `commands/web/claude` | `.ddev/commands/web/` | The `ddev claude` host command — a thin wrapper that execs `claude "$@"` inside the web container. |
| `config.claude.yaml` | `.ddev/` | `post-start` hook: **auth persistence** (see below). |
| `config.git-signing.yaml` | `.ddev/` | `post-start` hook: **opt-in git commit signing** (see below). |

Two design invariants matter more than anything else here:

- **Auth persistence** (`config.claude.yaml`): the hook symlinks `~/.claude` and
  `~/.claude.json` to DDEV's global cache volume
  (`/mnt/ddev-global-cache/claude-code/${DDEV_PROJECT}`, keyed per project). This is why
  login survives `ddev restart`/`rebuild`/`poweroff`/`delete`, stays out of Mutagen sync,
  and keeps credentials out of git. Keep state in the global cache — never write Claude
  auth into the project tree.

- **Git signing** (`config.git-signing.yaml`): lets in-container git commit/push **as the
  user with verified signatures**. It is **opt-in and inert by default** — the hook
  exits early unless `GIT_SIGNING_KEY` is set, leaving git/SSH untouched. The committed
  file must contain **logic only, no personal data** (users put identity + public key in
  a gitignored `config.git-signing.local.yaml`). The **private key is never stored** in
  the container — only the *public* key is referenced; the private key is forwarded from
  the host ssh-agent via `ddev auth ssh -f`. It pins the git host to one key by
  fingerprint to avoid `Too many authentication failures` from the shared global
  ssh-agent. Preserve all of these properties when editing.

## Testing

Tests are **Bats** integration tests (`tests/test.bats`) that stand up a real throwaway
DDEV project, install the add-on (once from this directory, once from the published
release), restart, and assert the CLI is present (`ddev exec "claude --version"` and the
`ddev claude` wrapper is wired). They run **on the host** and require `ddev` +
`bats-core` installed — they do **not** run inside a Claude container.

```bash
bats ./tests/test.bats                  # run all
bats -f "from directory" ./tests/test.bats   # single test by name filter
```

CI (`.github/workflows/tests.yml`) installs DDEV + bats and runs the same suite on
push to `main`, on PRs, weekly (Mon 06:01), and via manual dispatch.

## Editing notes

- After changing any committed shell/command file, keep it executable
  (`post_install_actions` chmods `commands/web/claude`; mirror that for new commands).
- The README is the user-facing docs and is detailed — when you change install steps,
  the git-signing setup, or env vars, update `README.md` to match.
- This repo is its own git remote (`vanWittlaer/ddev-claude-code`); commit and push from
  within this directory.
