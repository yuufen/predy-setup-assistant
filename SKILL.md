---
name: predy-setup-assistant
description: "Help people install Predy and repair local setup on a fresh or half-configured machine. Use when the request is specifically about Predy or Predy MCP setup, for example: 帮我装 Predy, 帮我配 Predy MCP, Predy 装不上因为没有 Node, Predy 证书有问题, 我不是工程师你一步步带我把 Predy 装好. This repo can install setup guidance into Codex, Claude, Cursor, and CodeWiz. It can auto-configure MCP for Codex, Cursor, and CodeWiz, and render a manual MCP-setup prompt fallback for supported clients when needed."
---

# Predy Setup Assistant

Use this skill for Predy installation, first-run setup, and local repair tasks.

## Quick Start

1. Run `scripts/predy_setup_doctor.sh --client <client> [--project /path/to/repo]` first.
2. Read `references/setup-workflow.md` before choosing the next command.
3. Fix the smallest missing prerequisite first.
4. Use the bundled scripts to generate the MCP wrapper for every client, auto-write MCP config for Codex, Cursor, and CodeWiz, and render a manual fallback prompt when needed.

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
- ask which client to install for when run without explicit client flags in an interactive terminal
- install the right client assets for Codex, Claude, Cursor, and CodeWiz

Prefer this over telling non-engineers to `git clone` the repository.

### `scripts/predy_setup_doctor.sh`

Use this for the first pass. It reports:

- OS and architecture
- `node`, `npm`, `npx`, `python3`, `brew`, `mkcert`
- the selected target client and optional project path
- the target-specific Predy skill path and state
- the current target client's MCP config path and state when this repo can auto-configure it
- localhost certificate file state
- whether a global `predy-skill` binary is already visible on PATH
- whether the current target client's Predy MCP entry already exists

Treat `mkcert` as a diagnostic signal, not as a standalone installation step that must happen before `predy-skill install`.
Do not default to a Codex MCP check when the user is configuring another client.
For `cursor` or `codewiz`, pass `--client` and `--project` so `predy.skill.state` and `predy.mcp.config.state` reflect the actual target project.

### `scripts/render_predy_mcp_wrapper.sh`

Use this to create a client-specific idempotent wrapper script that:

- supports `--client codex|claude|cursor|codewiz`
- clears the current Predy MCP listener before startup
- runs the globally installed `predy-skill mcp`
- relies on `predy-skill install` to prepare local certificates automatically when needed

### `scripts/upsert_codex_predy_mcp.py`

Use this to insert or replace a `[mcp_servers.predy]` block in `~/.codex/config.toml` for Codex.

### `scripts/upsert_codewiz_predy_mcp.py`

Use this to insert or replace a `predy-mcp` STDIO server entry in CodeWiz `global_mcp_settings.json`.

It preserves an existing `alwaysAllow` list, or writes the standard Predy `alwaysAllow` tool list for a fresh server entry.

### `scripts/upsert_cursor_predy_mcp.py`

Use this to insert or replace a `predy-mcp` STDIO server entry in Cursor `~/.cursor/mcp.json`.

### `scripts/render_manual_mcp_prompt.py`

Use this as a fallback when automatic MCP writing is unavailable or blocked.

It renders a Chinese prompt that tells the target client to configure a STDIO MCP server with the generated wrapper command.

If `python3` is missing, edit the TOML directly instead of blocking on this script.

## Operating Rules

1. Assume the user may be unfamiliar with Node, shell commands, and certificate trust.
2. Prefer doing the work for the user when local edits are possible.
3. Explain the purpose of each privileged or networked command in plain language before running it.
4. Default to the internal registry `http://npm.devops.xiaohongshu.com:7001`. Only override it if project documentation or the user explicitly asks for another package source.
5. Prefer the beta channel unless the user explicitly asks for stable.
6. Remember that this skill does not bypass Codex permissions. Homebrew install, system trust changes, and protected writes still require normal approval.
7. Treat missing Homebrew on macOS as a hard blocker for the standard Predy install path, but not for installing this setup assistant itself.
8. Prefer the public `install.sh` bootstrap so Homebrew can be attempted before the user reaches the in-agent Predy install steps, but do not block setup-assistant installation if that attempt fails.
9. Stop at hard blockers such as missing Homebrew on macOS for the actual Predy install, missing package source access, or lack of permission to write the target client's config or skill location.
10. If the user needs to install this setup assistant itself, prefer `install.sh` instead of asking them to clone the repo manually.
11. Do not ask the user to install `mkcert` or localhost certificates manually before running `predy-skill install`; that command already prepares the local certificate setup.
12. For client MCP managers, do not point the startup command directly at `npm exec --package=@predy-js/skill@beta -- predy-skill mcp`; use the generated wrapper instead.
13. For a fresh MCP runtime, first install `@predy-js/skill@beta` globally, then run the matching `predy-skill install --<client>` command before wiring the client config.
14. If the current host already reveals the client, do not ask the user to identify it again. Treat `.codewiz/skills/...` as CodeWiz, `.cursor/...` as Cursor, `~/.claude/...` as Claude, and `~/.codex/...` as Codex.
15. Do not tell non-Codex users that writing `~/.codex/config.toml` configures their client. It does not.
16. For Cursor MCP wiring, write `~/.cursor/mcp.json` with `scripts/upsert_cursor_predy_mcp.py`.
17. For CodeWiz MCP wiring, write `global_mcp_settings.json` with `scripts/upsert_codewiz_predy_mcp.py` instead of pointing at Codex config.
18. For Codex, Cursor, or CodeWiz MCP wiring, keep a manual prompt fallback available through `scripts/render_manual_mcp_prompt.py`.
19. For Claude MCP wiring, generate the wrapper first and then render a manual prompt with `scripts/render_manual_mcp_prompt.py`.

## Communication Rules

1. Give one next action at a time for non-engineer users.
2. Prefer outcome-based phrasing such as:
   - 先装 Node，这样安装命令才能跑
   - 再运行 Predy 安装命令，它会把本地证书一起准备好
   - 如果你现在用的是 Codex、Cursor 或 CodeWiz，我先尝试自动把它的 MCP 配好；如果自动写失败，我再给你一条 prompt 兜底
   - 如果你现在用的是 Claude，我给你一条 prompt，让当前客户端自己把 MCP 配好
3. If the environment is blocked, say exactly what is missing instead of dumping a long checklist.

## References

- Install and repair workflow: `references/setup-workflow.md`
