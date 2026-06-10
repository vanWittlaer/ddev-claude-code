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
| `.ddev/config.git-signing.yaml` | Opt-in `post-start` hook for SSH commit signing inside the container — inert unless `GIT_SIGNING_KEY` is set (see [Verified git commits](#verified-git-commits-from-inside-the-container)). |

These are copied into your project's `.ddev/` directory. Commit them so teammates get the same `ddev claude` command and a consistent CLI baseline.

## How auth persists

Claude's credentials and state live in DDEV's global cache volume at `/mnt/ddev-global-cache/claude-code/<project>`, keyed per project. That location survives `ddev restart`, `ddev rebuild`, `ddev poweroff`, and even `ddev delete`, stays out of Mutagen sync, and keeps credentials out of git — so you log in once and it sticks across rebuilds, with no per-project `.claude` files to `.gitignore`.

## Verified git commits from inside the container

This add-on ships `.ddev/config.git-signing.yaml`, a post-start hook that lets git
**inside the web container** sign commits and authenticate to your git host as you —
so commits made in here (including by Claude) show up **Verified**.

It is **opt-in and inert by default**: the hook does nothing unless you set
`GIT_SIGNING_KEY`. If you don't, your git config and SSH are left completely untouched.

### How it works

When activated it configures SSH commit signing (`gpg.format=ssh`), pins your git
host to a single forwarded key (so the shared DDEV ssh-agent's other keys don't cause
`Too many authentication failures`), and wraps git's SSH so a missing key fails with a
clear hint instead of a confusing `UNPROTECTED PRIVATE KEY` error. **No private key is
ever stored in the container** — only your *public* key is referenced; the private key
stays in your host ssh-agent.

### Setup

1. **Create a gitignored local config** with your identity and public key. Any DDEV env
   mechanism works (`web_environment`, `.ddev/.env`); a `config.git-signing.local.yaml`
   is matched by DDEV's default `.gitignore`:

   ```yaml
   # .ddev/config.git-signing.local.yaml  (gitignored)
   web_environment:
       - GIT_AUTHOR_NAME=Your Name
       - GIT_AUTHOR_EMAIL=you@example.com
       - GIT_COMMITTER_NAME=Your Name
       - GIT_COMMITTER_EMAIL=you@example.com
       - GIT_SIGNING_KEY_FILE=~/.ssh/id_ed25519        # optional, for an exact hint
       # - GIT_SIGNING_HOST=bitbucket.org              # optional, default github.com
       - GIT_SIGNING_KEY=ssh-ed25519 AAAA... you@example.com
   ```

2. **Forward the matching private key** from your host (re-run after each host login or
   `ddev poweroff`):

   ```bash
   ddev auth ssh -f ~/.ssh/id_ed25519
   ```

3. **Register the public key on your git host** as **both** an *authentication* and a
   *signing* key, and make sure your commit email is **verified** on that account.
   (GitHub/GitLab keep auth and signing keys separate — add it as both.)

4. `ddev restart`.

Verify with `git log --show-signature`, or push a commit and check the **Verified** badge.

### Environment variables

| Variable | Required | Purpose |
|---|---|---|
| `GIT_SIGNING_KEY` | ✅ | Your SSH **public** key (one line). Setting it activates the hook. |
| `GIT_AUTHOR_*` / `GIT_COMMITTER_*` | recommended | Commit identity. Email must be verified on the host. |
| `GIT_SIGNING_HOST` | optional | Git host to pin & sign for. Default `github.com`. |
| `GIT_SIGNING_KEY_FILE` | optional | Host path of the key — only used to make the missing-key hint exact. |

### Notes & gotchas

- **Use a software key, not a hardware/FIDO key.** YubiKey-style keys (`sk-ssh-…`) can't
  satisfy their touch requirement over DDEV's forwarded agent (`agent refused operation`),
  so they can't sign or auth in the container. Keep the hardware key for interactive use
  and forward a dedicated software key here.
- **The DDEV ssh-agent is global** across all your projects, so it often holds many keys.
  The hook pins your host to just your signing key by fingerprint, so the others don't
  interfere.
- **After `ddev poweroff` / a host reboot** the forwarded key is gone. A git op will then
  print a one-line reminder to re-run `ddev auth ssh -f …`. Nothing else needs redoing.
- **Non-GitHub hosts:** set `GIT_SIGNING_HOST`. Signing itself is host-agnostic; the
  **Verified** badge depends on the host supporting SSH-signature verification (GitHub &
  GitLab do; Bitbucket's support is more limited).
- **To disable:** unset `GIT_SIGNING_KEY` and `ddev restart`.

## Remove

```bash
ddev add-on remove claude-code
ddev restart
```

This deletes the generated files (they carry a `#ddev-generated` marker). Your stored Claude auth in the global cache volume is left untouched; remove it manually with `rm -rf /mnt/ddev-global-cache/claude-code` from inside the container if you want it gone.

## Credits

Based on the [Running Claude Code in DDEV](https://notebook.vanwittlaer.de/ddev-for-shopware/running-claude-code-in-ddev) guide.

**Maintained by [@vanWittlaer](https://github.com/vanWittlaer)**
