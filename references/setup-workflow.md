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

Use this workflow when the user wants Predy installed or repaired on a machine that may not already have Node, npm, mkcert, or a working client-specific Predy setup.

This guide is especially for users who are new to the command line or just want someone to "帮我装好".

This skill improves guidance and execution order. It does not bypass Codex sandbox or approval rules.

This repo is internal. Use the default internal registry unless project documentation or the user explicitly asks for another package source.

## First Pass

Run:

- `scripts/predy_setup_doctor.sh`

Use its output to classify the machine into one of these states:

1. Missing package manager prerequisites
2. Missing Node/npm
3. Missing Predy install or localhost certs
4. Missing Codex MCP config only, when the target client is Codex
5. Fully installed but broken at runtime

Fix the earliest missing prerequisite first.

## Package Source And Version Rules

1. Default registry: `http://npm.devops.xiaohongshu.com:7001`
2. Prefer `@predy-js/skill@beta` unless the user explicitly asks for stable.
3. Do not ask the user to install a global `predy-skill` binary unless they specifically want a global command.
4. If another registry is required, override the default through `PREDY_NPM_REGISTRY`, `NPM_CONFIG_REGISTRY`, or `--registry`.
5. Prefer the target-specific install command from the Predy Install Flow section. If the target is Codex, for example:

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
4. Copilot and CodeWiz can consume the root skill folder as a copied skill payload.

Important boundary:

- The bundled MCP bootstrap scripts in this repo are Codex-only.
- Do not write `~/.codex/config.toml` and claim that Cursor, CodeWiz, Claude, or Copilot are now configured for MCP.
- For non-Codex clients, this repo currently installs setup guidance and target-specific skill assets; their MCP client wiring must follow that client's own config location and rules.

For user distribution, prefer `install.sh` so the user does not need to `git clone` the repo first.

Use `scripts/install_targets.sh` only when you already have a local copy of the repo and want a direct local install.

This repo is expected to live at:

```text
https://code.devops.xiaohongshu.com/fe/infra/predy-setup-assistant
git@code.devops.xiaohongshu.com:fe/infra/predy-setup-assistant.git
```

Bootstrap examples after the repo is available:

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

1. Explain that Homebrew is the simplest path to install Node on macOS, and `predy-skill install` may also rely on it for certificate tooling.
2. Explain the result in plain language: "先装一个基础工具管理器，后面 Node 和 Predy 安装都靠它装。"
3. Ask before running the official Homebrew install command.
4. After Homebrew is available, continue with Node, then run the Predy install command.

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

`Copilot`

```bash
env NPM_CONFIG_REGISTRY=http://npm.devops.xiaohongshu.com:7001 \
  npm exec --yes --package=@predy-js/skill@beta -- \
  predy-skill install --copilot --project /path/to/repo
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
- `<project>/.github/skills/predy-code-assistant` for Copilot
- `~/.predy-skill/certs/localhost.pem`
- `~/.predy-skill/certs/localhost-key.pem`

## Codex MCP Bootstrap

This section is Codex-only.

Do not run this section for Cursor, CodeWiz, Claude, or Copilot unless the user explicitly also wants Codex configured on the same machine.

Prefer a wrapper script over a raw `npx` entry so that each launch follows the current beta tag and can self-heal first-run setup.

Explain it in user language as: "给 Codex 放一个启动脚本，以后它每次都能自己把 Predy 拉起来。"

Generate the wrapper with:

```bash
scripts/render_predy_mcp_wrapper.sh --output "$HOME/.codex/bin/predy-mcp-beta.sh"
```

That script already defaults to the internal registry.

If you need another registry in a special environment, also pass:

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

After Codex MCP setup, confirm:

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
3. the agent cannot write the target skill location, or `~/.codex` / `~/.predy-skill` for Codex bootstrap
4. a managed device or local policy blocks certificate trust changes

## Phrasing For Non-Engineers

Prefer short explanations like:

- "先补 Node，这样 npm 命令才能跑。"
- "然后运行 Predy 安装，它会把本地证书和当前客户端需要的 Predy 资产一起准备好。"
- "如果你现在用的是 Codex，最后再写一条 Codex MCP 配置，让它以后自己能拉起 Predy 服务。"
- "如果你现在不是 Codex，就不要去改 `~/.codex/config.toml`，那不会帮当前客户端生效。"
