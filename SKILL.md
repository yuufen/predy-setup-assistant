---
name: predy-setup-assistant
description: "Help people install Predy and repair local setup on a fresh or half-configured machine. Use when the request is specifically about Predy or Predy MCP setup, for example: 帮我装 Predy, 帮我配 Predy MCP, Predy 装不上因为没有 Node, Predy 证书有问题, 我不是工程师你一步步带我把 Predy 装好. This repo can install setup guidance into Codex, Claude, Cursor, CodeWiz, and Copilot. It can auto-configure MCP for Codex and CodeWiz, and render a manual MCP-setup prompt for Claude, Cursor, and Copilot."
---

# Predy Setup Assistant

Use this skill for Predy installation, first-run setup, and local repair tasks.

## Quick Start

1. Run `scripts/predy_setup_doctor.sh` first.
2. Read `references/setup-workflow.md` before choosing the next command.
3. Fix the smallest missing prerequisite first.
4. Use the bundled scripts to generate the MCP wrapper for every client, auto-write MCP config for Codex and CodeWiz, and render a manual prompt for Claude, Cursor, or Copilot when needed.

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
5. Client-specific MCP bootstrap flow and boundaries
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
- `CODEX_HOME`, `~/.codex/config.toml`, and Predy skill install state when the target is Codex
- CodeWiz global MCP config state under `~/.rcs/storage/default/CodeWiz.codewiz-agent/settings/global_mcp_settings.json`
- localhost certificate file state
- whether a Codex or CodeWiz Predy MCP entry already exists

Treat `mkcert` as a diagnostic signal, not as a standalone installation step that must happen before `predy-skill install`.

### `scripts/render_predy_mcp_wrapper.sh`

Use this to create a client-specific idempotent wrapper script that:

- uses `PREDY_SKILL_PACKAGE` or defaults to `@predy-js/skill@beta`
- defaults to the internal registry `http://npm.devops.xiaohongshu.com:7001`
- still allows overriding the registry through `PREDY_NPM_REGISTRY` or `--registry`
- supports `--client codex|claude|cursor|codewiz|copilot`
- self-heals first-run setup by calling the matching `predy-skill install --<client>` command before `predy-skill mcp`
- relies on that install command to prepare local certificates automatically when needed

### `scripts/upsert_codex_predy_mcp.py`

Use this to insert or replace a `[mcp_servers.predy]` block in `~/.codex/config.toml` for Codex.

### `scripts/upsert_codewiz_predy_mcp.py`

Use this to insert or replace a `predy-mcp` STDIO server entry in CodeWiz `global_mcp_settings.json`.

### `scripts/render_manual_mcp_prompt.py`

Use this for Claude, Cursor, or Copilot when the current client does not have an automatic MCP config writer here yet.

It renders a Chinese prompt that tells the target client to configure a STDIO MCP server with the generated wrapper command.

If `python3` is missing, edit the TOML directly instead of blocking on this script.

## Operating Rules

1. Assume the user may be unfamiliar with Node, shell commands, and certificate trust.
2. Prefer doing the work for the user when local edits are possible.
3. Explain the purpose of each privileged or networked command in plain language before running it.
4. Default to the internal registry `http://npm.devops.xiaohongshu.com:7001`. Only override it if project documentation or the user explicitly asks for another package source.
5. Prefer the beta channel unless the user explicitly asks for stable.
6. Remember that this skill does not bypass Codex permissions. Homebrew install, system trust changes, and protected writes still require normal approval.
7. Stop at hard blockers such as missing Homebrew on macOS, missing package source access, or lack of permission to write the target client's config or skill location.
8. If the user needs to install this setup assistant itself, prefer `install.sh` instead of asking them to clone the repo manually.
9. Do not ask the user to install `mkcert` or localhost certificates manually before running `predy-skill install`; that command already prepares the local certificate setup.
10. Do not tell Claude, Cursor, or Copilot users that writing `~/.codex/config.toml` configures their client. It does not.
11. For CodeWiz MCP wiring, write `global_mcp_settings.json` with `scripts/upsert_codewiz_predy_mcp.py` instead of pointing at Codex config.
12. For Claude, Cursor, or Copilot MCP wiring, generate the wrapper first and then render a manual prompt with `scripts/render_manual_mcp_prompt.py`.

## Communication Rules

1. Give one next action at a time for non-engineer users.
2. Prefer outcome-based phrasing such as:
   - 先装 Node，这样安装命令才能跑
   - 再运行 Predy 安装命令，它会把本地证书一起准备好
   - 如果你现在用的是 Codex 或 CodeWiz，再把它的 MCP 配好，后面就不用重复折腾
   - 如果你现在用的是 Claude、Cursor 或 Copilot，我给你一条 prompt，让当前客户端自己把 MCP 配好
3. If the environment is blocked, say exactly what is missing instead of dumping a long checklist.

## References

- Install and repair workflow: `references/setup-workflow.md`
