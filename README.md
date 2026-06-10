# ddev-claude-code

[![tests](https://github.com/vanWittlaer/ddev-claude-code/actions/workflows/tests.yml/badge.svg)](https://github.com/vanWittlaer/ddev-claude-code/actions/workflows/tests.yml)

Run [Claude Code](https://claude.com/claude-code) **inside** your [DDEV](https://ddev.com) web container, so it shares the project's PHP, Node, Composer, and database — the same environment as `ddev exec`, with no host-side toolchain drift.

## Install

```bash
ddev add-on get vanWittlaer/ddev-claude-code
ddev restart
```

The `ddev restart` is required: this add-on extends the web image, so the container has to rebuild before the `claude` binary exists.

## Use

```bash
ddev claude          # launch Claude Code inside the web container
```

First run is an interactive setup (login, model, defaults).

Inside an in-container session, project tooling runs **directly** — `bin/console`, `composer`, `npm`, `mysql` — with no `ddev exec` prefix.

PhpStorm users with the Claude Code plugin can point its Claude command at `ddev claude`.

## What it installs

| File | Purpose |
|------|---------|
| `.ddev/web-build/Dockerfile.claude` | Installs the Claude Code CLI into the web image for the DDEV web user. |
| `.ddev/commands/web/claude` | The `ddev claude` wrapper command. |
| `.ddev/config.claude.yaml` | `post-start` hook that symlinks `~/.claude` and `~/.claude.json` into DDEV's global cache volume. |

These are copied into your project's `.ddev/` directory. Commit them so teammates get the same `ddev claude` command and a consistent CLI baseline.

## How auth persists

Claude's credentials and state live in DDEV's global cache volume at `/mnt/ddev-global-cache/claude-code/<project>`, keyed per project. That location survives `ddev restart`, `ddev rebuild`, `ddev poweroff`, and even `ddev delete`, stays out of Mutagen sync, and keeps credentials out of git — so you log in once and it sticks across rebuilds, with no per-project `.claude` files to `.gitignore`.

## Remove

```bash
ddev add-on remove claude-code
ddev restart
```

This deletes the three generated files (they carry a `#ddev-generated` marker). Your stored Claude auth in the global cache volume is left untouched; remove it manually with `rm -rf /mnt/ddev-global-cache/claude-code` from inside the container if you want it gone.

## Credits

Based on the [Running Claude Code in DDEV](https://notebook.vanwittlaer.de/ddev-for-shopware/running-claude-code-in-ddev) guide.

**Maintained by [@vanWittlaer](https://github.com/vanWittlaer)**
