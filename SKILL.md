---
name: predy-setup-assistant
description: "Help people get Predy running in Codex on a fresh or half-configured machine. Use when the request is specifically about Predy or the Predy MCP setup, for example: 帮我装 Predy, 帮我配 Predy MCP, Predy 装不上因为没有 Node, Predy 证书有问题, 我不是工程师你一步步带我把 Predy 装好, or when Predy beta, localhost certificates, or the `~/.codex/config.toml` Predy MCP entry need to be installed or repaired."
---

# Predy Setup Assistant

Use this skill for Predy installation, first-run setup, and local repair tasks.

## Quick Start

1. Run `scripts/predy_setup_doctor.sh` first.
2. Read `references/setup-workflow.md` before choosing the next command.
3. Fix the smallest missing prerequisite first.
4. Use the bundled scripts to generate the MCP wrapper and update `config.toml` instead of asking the user to hand-edit files.

## Common User Requests

Trigger this skill for requests like:

- "帮我把 Predy 装起来"
- "帮我把 Predy MCP 配好"
- "Predy 装不上，我电脑上没有 Node"
- "Predy 的 localhost 证书不对"
- "我不是程序员，你一步步帮我把 Predy 装好"
- "帮我修一下 Predy 起不来"

## Default Workflow

For any install, bootstrap, or repair task, read `references/setup-workflow.md` first.

Treat that file as the single source for:

1. Diagnosis order
2. Package source and beta-channel rules
3. macOS prerequisite repair
4. `@predy-js/skill@beta` install flow
5. Codex MCP bootstrap flow
6. Verification and stop conditions

## Bundled Scripts

### `install.sh`

Use this as the preferred public bootstrap entrypoint when the user does not already have a local copy of the repo.

It can:

- download the skill repo from its default repository URL or an overridden `--repo-url`
- reuse a local checkout when run inside the repo
- install the right client assets for Codex, Claude, Cursor, Copilot, or CodeWiz

Prefer this over telling non-engineers to `git clone` the repository.

### `scripts/predy_setup_doctor.sh`

Use this for the first pass. It reports:

- OS and architecture
- `node`, `npm`, `npx`, `python3`, `brew`, `mkcert`
- `CODEX_HOME`, `~/.codex/config.toml`, and Predy skill install state
- localhost certificate file state
- whether a `[mcp_servers.predy]` block already exists

Treat `mkcert` as a diagnostic signal, not as a standalone installation step that must happen before `predy-skill install --codex`.

### `scripts/render_predy_mcp_wrapper.sh`

Use this to create an idempotent wrapper script that:

- uses `PREDY_SKILL_PACKAGE` or defaults to `@predy-js/skill@beta`
- defaults to the internal registry `http://npm.devops.xiaohongshu.com:7001`
- still allows overriding the registry through `PREDY_NPM_REGISTRY` or `--registry`
- self-heals first-run setup by calling `predy-skill install --codex` before `predy-skill mcp`
- relies on that install command to prepare local certificates automatically when needed

### `scripts/upsert_codex_predy_mcp.py`

Use this to insert or replace a `[mcp_servers.predy]` block in `~/.codex/config.toml`.

If `python3` is missing, edit the TOML directly instead of blocking on this script.

## Operating Rules

1. Assume the user may be unfamiliar with Node, shell commands, and certificate trust.
2. Prefer doing the work for the user when local edits are possible.
3. Explain the purpose of each privileged or networked command in plain language before running it.
4. Default to the internal registry `http://npm.devops.xiaohongshu.com:7001`. Only override it if project documentation or the user explicitly asks for another package source.
5. Prefer the beta channel unless the user explicitly asks for stable.
6. Remember that this skill does not bypass Codex permissions. Homebrew install, system trust changes, and protected writes still require normal approval.
7. Stop at hard blockers such as missing Homebrew on macOS, missing package source access, or lack of permission to write `~/.codex`.
8. If the user needs to install this setup assistant itself, prefer `install.sh` instead of asking them to clone the repo manually.
9. Do not ask the user to install `mkcert` or localhost certificates manually before running `predy-skill install --codex`; that command already prepares the local certificate setup.

## Communication Rules

1. Give one next action at a time for non-engineer users.
2. Prefer outcome-based phrasing such as:
   - 先装 Node，这样安装命令才能跑
   - 再运行 Predy 安装命令，它会把本地证书一起准备好
   - 再把 MCP 配好，后面就不用重复折腾
3. If the environment is blocked, say exactly what is missing instead of dumping a long checklist.

## References

- Install and repair workflow: `references/setup-workflow.md`
