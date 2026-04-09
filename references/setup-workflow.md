# Predy Setup Workflow

## Contents

1. Goal
2. First Pass
3. Package Source And Version Rules
4. Target Compatibility
5. macOS Repair Order
6. Predy Install Flow
7. Codex MCP Bootstrap
8. Verification
9. Stop Conditions
10. Phrasing For Non-Engineers

## Goal

Use this workflow when the user wants Predy installed or repaired on a machine that may not already have Node, npm, mkcert, or a working Codex MCP config.

This guide is especially for users who are new to the command line or just want someone to "帮我装好".

This skill improves guidance and execution order. It does not bypass Codex sandbox or approval rules.

This skill is public and should not hardcode a private registry.

If Predy is published to a private registry in your environment, get that registry from project documentation or the user before running install commands.

## First Pass

Run:

- `scripts/predy_setup_doctor.sh`

Use its output to classify the machine into one of these states:

1. Missing package manager prerequisites
2. Missing Node/npm
3. Missing mkcert
4. Missing Predy install or localhost certs
5. Missing Codex MCP config only
6. Fully installed but broken at runtime

Fix the earliest missing prerequisite first.

## Package Source And Version Rules

1. Do not hardcode a private registry in the public skill.
2. Prefer `@predy-js/skill@beta` unless the user explicitly asks for stable.
3. Do not ask the user to install a global `predy-skill` binary unless they specifically want a global command.
4. If a private registry is required, get it from project documentation or the user, then pass it through `PREDY_NPM_REGISTRY`, `NPM_CONFIG_REGISTRY`, or `--registry`.
5. Prefer:

```bash
npm exec --yes --package=@predy-js/skill@beta -- \
  predy-skill install --codex
```

If a private registry is required, adapt it to:

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
4. Copilot and CodeWiz can consume the root skill folder as a copied skill payload.

For public distribution, prefer `install.sh` so the user does not need to `git clone` the repo first.

Use `scripts/install_targets.sh` only when you already have a local copy of the repo and want a direct local install.

This repo is expected to live at:

```text
https://code.devops.xiaohongshu.com/fe/infra/predy-setup-assistant
git@code.devops.xiaohongshu.com:fe/infra/predy-setup-assistant.git
```

Public bootstrap examples after the repo is available:

```bash
curl -L -o /tmp/predy-setup-install.sh https://code.devops.xiaohongshu.com/fe/infra/predy-setup-assistant/-/raw/main/install.sh
bash /tmp/predy-setup-install.sh --codex

curl -L -o /tmp/predy-setup-install.sh https://code.devops.xiaohongshu.com/fe/infra/predy-setup-assistant/-/raw/main/install.sh
bash /tmp/predy-setup-install.sh --claude

curl -L -o /tmp/predy-setup-install.sh https://code.devops.xiaohongshu.com/fe/infra/predy-setup-assistant/-/raw/main/install.sh
bash /tmp/predy-setup-install.sh --cursor --project /path/to/repo
```

Local repo examples:

Examples:

```bash
scripts/install_targets.sh --codex
scripts/install_targets.sh --claude
scripts/install_targets.sh --cursor --project /path/to/repo
scripts/install_targets.sh --codewiz --project /path/to/repo
scripts/install_targets.sh --copilot --project /path/to/repo
```

## macOS Repair Order

### If `brew` is missing

1. Explain that Homebrew is the simplest path to install Node and mkcert.
2. Explain the result in plain language: "先装一个基础工具管理器，后面 Node 和证书工具都靠它装。"
3. Ask before running the official Homebrew install command.
4. After Homebrew is available, continue with Node and mkcert.

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

Run:

```bash
brew install mkcert
```

Do not call `mkcert -install` manually first if the next step is `predy-skill install --codex`, because that command already prepares local certificates.

## Predy Install Flow

For Codex-only onboarding, use:

```bash
npm exec --yes --package=@predy-js/skill@beta -- \
  predy-skill install --codex
```

This should:

1. Install the Codex skill payload
2. Build or use the bundled MCP server assets
3. Prepare localhost certificates under `~/.predy-skill/certs`

After install, verify:

- `~/.codex/skills/predy-code-assistant`
- `~/.predy-skill/certs/localhost.pem`
- `~/.predy-skill/certs/localhost-key.pem`

## Codex MCP Bootstrap

Prefer a wrapper script over a raw `npx` entry so that each launch follows the current beta tag and can self-heal first-run setup.

Explain it in user language as: "给 Codex 放一个启动脚本，以后它每次都能自己把 Predy 拉起来。"

Generate the wrapper with:

```bash
scripts/render_predy_mcp_wrapper.sh --output "$HOME/.codex/bin/predy-mcp-beta.sh"
```

If a private registry is required in your environment, also pass:

```bash
scripts/render_predy_mcp_wrapper.sh \
  --registry "<your-registry>" \
  --output "$HOME/.codex/bin/predy-mcp-beta.sh"
```

That script writes a shell wrapper which:

1. checks for the Predy Codex skill and localhost certificates
2. runs `predy-skill install --codex` if first-run setup is still missing
3. starts `predy-skill mcp`

Then upsert the Codex config with:

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

## Verification

After setup, confirm:

1. `scripts/predy_setup_doctor.sh` shows `present` for the Predy skill, certificates, and MCP block
2. the wrapper script exists and is executable
3. `~/.codex/config.toml` points at the expected absolute path

If the user wants a live runtime check, start the wrapper script and verify:

```bash
lsof -nP -iTCP:17654 -sTCP:LISTEN
```

If the browser still rejects `wss://localhost:17654`, explain the likely local trust issue:

1. Chrome may still need a full restart
2. the mkcert development CA may need trust in Keychain Access on macOS

## Stop Conditions

Stop and explain the blocker if any of these are true:

1. the machine cannot reach the required package source or registry
2. Homebrew installation is required but the user does not approve it
3. the agent cannot write `~/.codex` or `~/.predy-skill`
4. a managed device or local policy blocks certificate trust changes

## Phrasing For Non-Engineers

Prefer short explanations like:

- "先补 Node，这样 npm 命令才能跑。"
- "再补证书工具，这样浏览器才能信任本地 `wss://localhost`。"
- "然后安装 Predy，把证书和 Codex skill 一起准备好。"
- "最后写一条 Codex MCP 配置，让它以后自己能拉起 Predy 服务。"
