# Predy Setup Workflow

## Contents

1. Goal
2. First Pass
3. Package Source And Version Rules
4. Target Compatibility
5. macOS Repair Order
6. Predy Install Flow
7. Client MCP Bootstrap
8. Verification
9. Stop Conditions
10. Phrasing For Non-Engineers

## Goal

Use this workflow when the user wants Predy installed or repaired on a machine that may not already have Node, npm, mkcert, or a working client-specific Predy setup.

This guide is especially for users who are new to the command line or just want someone to "帮我装好".

This skill improves guidance and execution order. It does not bypass Codex sandbox or approval rules.

This repo is internal. Use the default internal registry unless project documentation or the user explicitly asks for another package source.

## First Pass

Run:

- `scripts/predy_setup_doctor.sh --client <client> [--project /path/to/repo]`

If the current host already reveals the client, use that host as the default target and do not ask the user to identify it again. For example:

- `.codewiz/skills/...` means CodeWiz
- `.cursor/...` means Cursor
- `~/.claude/...` means Claude
- `~/.codex/...` means Codex

If you genuinely do not know the target client yet, you may run `scripts/predy_setup_doctor.sh` without `--client` for generic environment and certificate checks only. Do not treat that generic run as a Codex MCP diagnosis.

Use its output to classify the machine into one of these states:

1. Missing package manager prerequisites
2. Missing Node/npm
3. Missing Predy install or localhost certs
4. Missing MCP config only, for a client that this repo can configure directly
5. Fully installed but broken at runtime

Fix the earliest missing prerequisite first.

## Package Source And Version Rules

1. Default registry: `http://npm.devops.xiaohongshu.com:7001`
2. Prefer `@predy-js/skill@beta` unless the user explicitly asks for stable.
3. For one-shot Predy install or repair, prefer `npm exec --package=@predy-js/skill@beta -- predy-skill ...`.
4. For a long-running client MCP startup command, do not point the client directly at `npm exec`. Generate a wrapper and use a globally installed `predy-skill` runtime.
5. If another registry is required, override the default through `PREDY_NPM_REGISTRY`, `NPM_CONFIG_REGISTRY`, or `--registry`.
6. Prefer the target-specific install command from the Predy Install Flow section. If the target is Codex, for example:

```bash
env NPM_CONFIG_REGISTRY=http://npm.devops.xiaohongshu.com:7001 \
  npm exec --yes --package=@predy-js/skill@beta -- \
  predy-skill install --codex
```

If another registry is required, adapt it to:

```bash
env NPM_CONFIG_REGISTRY=<your-registry> \
  npm exec --yes --package=@predy-js/skill@beta -- \
  predy-skill install --codex
```

## Target Compatibility

This repo is designed to cover multiple assistants:

1. Codex reads the root `SKILL.md` and `agents/openai.yaml`.
2. Claude uses `claude/predy-setup-assistant.md`.
3. Cursor uses `cursor/predy-setup-assistant.mdc`.
4. CodeWiz can consume the root skill folder as a copied skill payload.

Important boundary:

- This repo can auto-configure MCP for Codex, Cursor, and CodeWiz.
- Do not write `~/.codex/config.toml` and claim that non-Codex clients are now configured for MCP.
- Keep a manual MCP-setup prompt fallback for Codex, Cursor, and CodeWiz.
- For Claude, render a manual MCP-setup prompt after the wrapper is ready.

For user distribution, prefer `install.sh` so the user does not need to `git clone` the repo first.
If the user runs `install.sh` without client flags in a normal terminal, it will ask which client to install for and, for Cursor or CodeWiz, prompt for a project path when needed.

Use `scripts/install_targets.sh` only when you already have a local copy of the repo and want a direct local install.

This repo is expected to live at:

```text
https://github.com/yuufen/predy-setup-assistant
git@github.com:yuufen/predy-setup-assistant.git
```

Bootstrap examples after the repo is available:

```bash
curl -L -o /tmp/predy-setup-install.sh https://raw.githubusercontent.com/yuufen/predy-setup-assistant/main/install.sh && bash /tmp/predy-setup-install.sh
```

That single command is the preferred user-facing entrypoint. Keep the explicit `--codex` / `--claude` / `--cursor --project ...` flags only for support or automation cases.

Local repo examples:

Examples:

```bash
scripts/install_targets.sh --codex
scripts/install_targets.sh --claude
scripts/install_targets.sh --cursor --project /path/to/repo
scripts/install_targets.sh --codewiz --project /path/to/repo
```

## macOS Repair Order

### If `brew` is missing

1. Treat this as a hard blocker for the full Predy install path on macOS, but not for installing this setup assistant itself.
2. Prefer the public `install.sh` bootstrap command first, because it now attempts the official Homebrew installer before the setup assistant when Homebrew is missing.
3. Explain the result in plain language: "先尝试装一个基础工具管理器，后面 Node 和 Predy 安装都靠它装。"
4. If that Homebrew install attempt fails, continue installing the setup assistant and let the later Predy install flow stop on the real blocker with a clearer message.

### If `node` or `npm` is missing

Run:

```bash
brew install node
```

Then verify:

```bash
node -v
npm -v
npx --version
```

### If `mkcert` is missing

Do not treat this as a standalone prerequisite.

After `node` and `npm` are available, run the target-specific `predy-skill install` command first. That command already prepares local certificates and installs certificate tooling when needed.

## Predy Install Flow

Choose the install command based on the current client:

`Codex`

```bash
env NPM_CONFIG_REGISTRY=http://npm.devops.xiaohongshu.com:7001 \
  npm exec --yes --package=@predy-js/skill@beta -- \
  predy-skill install --codex
```

`Claude`

```bash
env NPM_CONFIG_REGISTRY=http://npm.devops.xiaohongshu.com:7001 \
  npm exec --yes --package=@predy-js/skill@beta -- \
  predy-skill install --claude
```

`Cursor`

```bash
env NPM_CONFIG_REGISTRY=http://npm.devops.xiaohongshu.com:7001 \
  npm exec --yes --package=@predy-js/skill@beta -- \
  predy-skill install --cursor --project /path/to/repo
```

`CodeWiz`

```bash
env NPM_CONFIG_REGISTRY=http://npm.devops.xiaohongshu.com:7001 \
  npm exec --yes --package=@predy-js/skill@beta -- \
  predy-skill install --codewiz --project /path/to/repo
```

All of these go through the same `install` command and therefore:

1. Install the selected client's skill asset
2. Build or use the bundled MCP server assets
3. Install or reuse certificate tooling when needed
4. Prepare localhost certificates under `~/.predy-skill/certs`

After install, verify the target-specific skill asset plus the shared certificate output:

- `~/.codex/skills/predy-code-assistant` for Codex
- `~/.claude/skills/predy-code-assistant` and `~/.claude/agents/predy-code-assistant.md` for Claude
- `<project>/.cursor/rules/predy-code-assistant.mdc` for Cursor
- `<project>/.codewiz/skills/predy-code-assistant` for CodeWiz
- `~/.predy-skill/certs/localhost.pem`
- `~/.predy-skill/certs/localhost-key.pem`

## Client MCP Bootstrap

Generate a wrapper first. The wrapper is the stable local startup command that the client MCP manager should execute.

Explain it in user language as: "给客户端放一个稳定启动脚本，以后客户端只跑这一个本地脚本，不再在启动时临时联网安装。"

`Codex`

```bash
scripts/render_predy_mcp_wrapper.sh \
  --client codex \
  --output "$HOME/.codex/bin/predy-mcp-beta.sh"
```

`CodeWiz`

```bash
scripts/render_predy_mcp_wrapper.sh \
  --client codewiz \
  --project /path/to/repo \
  --output "$HOME/.predy-skill/bin/predy-mcp-codewiz-beta.sh"
```

`Claude`

```bash
scripts/render_predy_mcp_wrapper.sh \
  --client claude \
  --output "$HOME/.predy-skill/bin/predy-mcp-claude-beta.sh"
```

`Cursor`

```bash
scripts/render_predy_mcp_wrapper.sh \
  --client cursor \
  --project /path/to/repo \
  --output "$HOME/.predy-skill/bin/predy-mcp-cursor-beta.sh"
```

That script writes a shell wrapper which:

1. starts the globally installed `predy-skill mcp`
2. uses `exec` so the client talks directly to the MCP process
3. keeps the client MCP manager on one stable local command path

After the wrapper exists, initialize the runtime once with a global install plus the target-specific `predy-skill install`:

`Codex`

```bash
env NPM_CONFIG_REGISTRY=http://npm.devops.xiaohongshu.com:7001 npm i -g @predy-js/skill@beta
predy-skill install --codex
```

`CodeWiz`

```bash
env NPM_CONFIG_REGISTRY=http://npm.devops.xiaohongshu.com:7001 npm i -g @predy-js/skill@beta
predy-skill install --codewiz --project /path/to/repo
```

`Claude`

```bash
env NPM_CONFIG_REGISTRY=http://npm.devops.xiaohongshu.com:7001 npm i -g @predy-js/skill@beta
predy-skill install --claude
```

`Cursor`

```bash
env NPM_CONFIG_REGISTRY=http://npm.devops.xiaohongshu.com:7001 npm i -g @predy-js/skill@beta
predy-skill install --cursor --project /path/to/repo
```

From that point on:

1. the client MCP manager should execute the wrapper itself with no extra args
2. updates should happen out-of-band by repeating the same global install plus `predy-skill install` commands
3. stale-port recovery should happen out-of-band with `predy-skill kill-mcp --force`, then the client should re-run the same wrapper startup command

### Codex auto-config

After the wrapper exists, upsert the Codex config with:

```bash
python3 scripts/upsert_codex_predy_mcp.py \
  --config "$HOME/.codex/config.toml" \
  --command "$HOME/.codex/bin/predy-mcp-beta.sh"
```

If `python3` is unavailable, patch `~/.codex/config.toml` directly to contain:

```toml
[mcp_servers.predy]
command = "/absolute/path/to/.codex/bin/predy-mcp-beta.sh"
args = []
```

### CodeWiz auto-config

After the wrapper exists, upsert the CodeWiz config with:

```bash
python3 scripts/upsert_codewiz_predy_mcp.py \
  --config "$HOME/.rcs/storage/default/CodeWiz.codewiz-agent/settings/global_mcp_settings.json" \
  --command "$HOME/.predy-skill/bin/predy-mcp-codewiz-beta.sh"
```

By default this preserves an existing `alwaysAllow` list, or writes the standard Predy `alwaysAllow` tool list for a fresh server entry.

### Cursor auto-config

After the wrapper exists, upsert the Cursor config with:

```bash
python3 scripts/upsert_cursor_predy_mcp.py \
  --config "$HOME/.cursor/mcp.json" \
  --command "$HOME/.predy-skill/bin/predy-mcp-cursor-beta.sh"
```

### Manual prompt fallback

Use this when automatic MCP writing is unavailable, blocked, or the current client only supports the prompt path here.

`Codex`

```bash
python3 scripts/render_manual_mcp_prompt.py \
  --client codex \
  --command "$HOME/.codex/bin/predy-mcp-beta.sh"
```

`CodeWiz`

```bash
python3 scripts/render_manual_mcp_prompt.py \
  --client codewiz \
  --command "$HOME/.predy-skill/bin/predy-mcp-codewiz-beta.sh"
```

`Claude`

```bash
python3 scripts/render_manual_mcp_prompt.py \
  --client claude \
  --command "$HOME/.predy-skill/bin/predy-mcp-claude-beta.sh"
```

`Cursor`

```bash
python3 scripts/render_manual_mcp_prompt.py \
  --client cursor \
  --command "$HOME/.predy-skill/bin/predy-mcp-cursor-beta.sh"
```

Give the rendered prompt to the current client and let its agent finish the MCP configuration there.

## Verification

After MCP setup, confirm:

1. `scripts/predy_setup_doctor.sh --client <client> [--project /path/to/repo]` shows `present` for localhost certificates, the target-specific skill path, and `predy.mcp.config.state=present` when the selected client supports auto-config here
2. the wrapper script exists and is executable
3. the client-specific config points at the expected absolute path when that client supports auto-config here

If the user wants a live runtime check, start the wrapper script and verify:

```bash
lsof -nP -iTCP:17654 -sTCP:LISTEN
```

If startup fails because the WebSocket port is still occupied by an old `predy-mcp` process, use this explicit recovery step:

```bash
predy-skill kill-mcp --force
```

Then let the client MCP manager start the same wrapper again.

If the browser still rejects `wss://localhost:17654`, explain the likely local trust issue:

1. Chrome may still need a full restart
2. the mkcert development CA may need trust in Keychain Access on macOS

## Stop Conditions

Stop and explain the blocker if any of these are true:

1. the machine cannot reach the required package source or registry
2. Homebrew installation is required but the user does not approve it
3. the agent cannot write the target skill location, or the relevant MCP config path for Codex / Cursor / CodeWiz bootstrap
4. a managed device or local policy blocks certificate trust changes

## Phrasing For Non-Engineers

Prefer short explanations like:

- "先补 Node，这样 npm 命令才能跑。"
- "然后运行 Predy 安装，它会把本地证书和当前客户端需要的 Predy 资产一起准备好。"
- "如果你现在用的是 Codex、Cursor 或 CodeWiz，我先尝试自动把它的 MCP 配好；如果自动写失败，我再给你一条 prompt 兜底。"
- "如果你现在用的是 Claude，我给你一条 prompt，让当前客户端自己把 MCP 配好。"
