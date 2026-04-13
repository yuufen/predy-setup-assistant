# Predy Setup Assistant

## 安装说明

你不需要先安装 `predy-skill`，也不需要先 `git clone` 仓库。
只要复制下面的一段命令到终端里执行，然后按提示操作就可以。

## 开始前

1. 打开你电脑上的“终端”应用。
2. 把下面这条命令整段复制进去，然后一次性回车：

```bash
curl -L -o /tmp/predy-setup-install.sh https://raw.githubusercontent.com/yuufen/predy-setup-assistant/main/install.sh && bash /tmp/predy-setup-install.sh
```

3. 脚本会自己问你当前用的是哪个客户端：
   `Codex`、`Claude`、`Cursor`、`CodeWiz`
4. 如果你选的是 `Cursor` 或 `CodeWiz`，脚本还会继续问你的项目目录；你可以直接输入项目路径，或者在项目目录里执行这条命令后直接回车。
5. 在 macOS 上，脚本开头会先检查 `Homebrew`。如果机器还没有，它会先尝试拉起官方 Homebrew 安装程序；如果没装成功，setup assistant 仍然会先装好，后面真正安装 Predy 时再继续提示你处理。

## 安装完成后怎么说

安装完成后，彻底退出当前 AI 客户端，再重新打开，然后在聊天框里输入：

```text
$predy-setup-assistant 帮我一步步安装 Predy
```

后面如果 AI 提示你要安装 Node、写配置、或者准备本地证书，按提示确认即可。
其中 `Cursor` 安装完成后，项目里会多出一个 `./.cursor/` helper 目录；`CodeWiz` 则会在项目里多出 `./.codewiz/`。

## 安装过程中常见情况

1. 如果终端提示你允许下载、允许访问网络、允许写入配置，正常确认即可。
2. 如果系统提示你输入 Mac 登录密码，这通常是正常的，因为它可能在安装基础工具或本地证书。
3. 如果第一条安装命令先要求安装 `Homebrew`，这是正常步骤，因为 macOS 下后面的 Predy 安装通常会依赖它。
4. 本地证书和 `mkcert` 会在 `predy-skill install` 时自动处理，不需要你先手动安装证书工具。
5. 如果浏览器或系统提示你信任本地证书，按提示操作即可。

## 什么情况需要找工程同学

1. 你不知道当前项目目录是什么。
2. 终端提示没有权限。
3. 下载地址打不开，或者一直跳转到登录页。
4. 安装到一半，你不确定某个系统弹窗该不该点。

## 一句话总结

先执行一条安装命令，把 `predy-setup-assistant` 放进你的 AI 客户端里；然后直接对 AI 说“帮我一步步安装 Predy”，后面的 Node、Predy 和本地证书都会按步骤带你完成。`Codex`、`Cursor`、`CodeWiz` 还可以继续自动配置 MCP；`Claude` 会收到一条配置 prompt。前面三者如果自动写失败，也有 prompt 兜底。

## 给工程 / 支持同学的补充说明

如果你不是终端新手，或者你是在帮别人排查安装问题，下面这些信息可以直接用。

### 内部包源

- 包源地址：`http://npm.devops.xiaohongshu.com:7001`
- 包名：`@predy-js/skill@beta`

### 实际安装 Predy 的命令

按客户端分别用：

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

这些命令都会走同一套 `install` 主流程，也都会准备本地证书。

### 生成 Predy MCP wrapper

不同客户端都可以复用同一个 wrapper 生成脚本，区别只在 `--client` 和是否需要 `--project`。

这里生成出来的 wrapper 才是推荐交给客户端 MCP 管理器的启动命令。
不要把 `npm exec --package=@predy-js/skill@beta -- predy-skill mcp` 直接写进 MCP 配置里，因为那样会把更新、联网和启动都混在一次启动流程里，容易造成断连。

`Codex`

```bash
./scripts/render_predy_mcp_wrapper.sh \
  --client codex \
  --output "$HOME/.codex/bin/predy-mcp-beta.sh"
```

`CodeWiz`

```bash
./scripts/render_predy_mcp_wrapper.sh \
  --client codewiz \
  --project /path/to/repo \
  --output "$HOME/.predy-skill/bin/predy-mcp-codewiz-beta.sh"
```

`Claude`

```bash
./scripts/render_predy_mcp_wrapper.sh \
  --client claude \
  --output "$HOME/.predy-skill/bin/predy-mcp-claude-beta.sh"
```

`Cursor`

```bash
./scripts/render_predy_mcp_wrapper.sh \
  --client cursor \
  --project /path/to/repo \
  --output "$HOME/.predy-skill/bin/predy-mcp-cursor-beta.sh"
```

MCP 管理器真正启动时，只需要执行 wrapper 本身，不带额外参数。
这个 wrapper 只负责解析全局 `predy-skill` 路径并 `exec predy-skill mcp`，不会在启动前主动清理端口。

### 初始化或更新 Predy MCP runtime

第一次接 MCP 前，先手动做一次全局安装和客户端安装。以后要更新 beta，也重复同一套命令。

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

做完这一步之后，客户端 MCP 管理器再去调用 wrapper。

### 自动写入 Codex MCP 配置

这一步只在 `Codex` 场景需要。

```bash
python3 ./scripts/upsert_codex_predy_mcp.py \
  --config "$HOME/.codex/config.toml" \
  --command "$HOME/.codex/bin/predy-mcp-beta.sh"
```

期望写入的配置块如下：

```toml
[mcp_servers.predy]
command = "/absolute/path/to/.codex/bin/predy-mcp-beta.sh"
args = []
```

### 自动写入 CodeWiz MCP 配置

这一步只在 `CodeWiz` 场景需要。

```bash
python3 ./scripts/upsert_codewiz_predy_mcp.py \
  --config "$HOME/.rcs/storage/default/CodeWiz.codewiz-agent/settings/global_mcp_settings.json" \
  --command "$HOME/.predy-skill/bin/predy-mcp-codewiz-beta.sh"
```

默认会写入一组 Predy 常用工具的 `alwaysAllow` 白名单；如果配置里已经存在同名 server 且已有 `alwaysAllow`，脚本会保留原值。

期望写入的配置块大致如下：

```json
{
  "mcpServers": {
    "predy-mcp": {
      "alwaysAllow": [
        "list_predy_tabs_and_compositions",
        "get_predy_scene_json",
        "save_project_zip",
        "load_project_zip",
        "publish_composition",
        "snapshot_at_time",
        "save_project",
        "duplicate_project",
        "create_composition_from_image",
        "create_composition_set_from_folder"
      ],
      "type": "stdio",
      "command": "/absolute/path/to/.predy-skill/bin/predy-mcp-codewiz-beta.sh",
      "args": []
    }
  }
}
```

### 自动写入 Cursor MCP 配置

这一步只在 `Cursor` 场景需要。

```bash
python3 ./scripts/upsert_cursor_predy_mcp.py \
  --config "$HOME/.cursor/mcp.json" \
  --command "$HOME/.predy-skill/bin/predy-mcp-cursor-beta.sh"
```

期望写入的配置块大致如下：

```json
{
  "mcpServers": {
    "predy-mcp": {
      "command": "/absolute/path/to/.predy-skill/bin/predy-mcp-cursor-beta.sh",
      "args": []
    }
  }
}
```

### 生成 MCP 配置 prompt 兜底

这一步是兜底方式：

- `Claude` 目前主要靠它来配置
- `Codex`、`Cursor`、`CodeWiz` 自动写失败时，也可以用它兜底

`Codex`

```bash
python3 ./scripts/render_manual_mcp_prompt.py \
  --client codex \
  --command "$HOME/.codex/bin/predy-mcp-beta.sh"
```

`Claude`

```bash
python3 ./scripts/render_manual_mcp_prompt.py \
  --client claude \
  --command "$HOME/.predy-skill/bin/predy-mcp-claude-beta.sh"
```

`Cursor`

```bash
python3 ./scripts/render_manual_mcp_prompt.py \
  --client cursor \
  --command "$HOME/.predy-skill/bin/predy-mcp-cursor-beta.sh"
```

`CodeWiz`

```bash
python3 ./scripts/render_manual_mcp_prompt.py \
  --client codewiz \
  --command "$HOME/.predy-skill/bin/predy-mcp-codewiz-beta.sh"
```

运行后会输出一条中文 prompt。把那条 prompt 直接发给对应客户端里的 agent，让它自己去完成 MCP 配置。

### 端口占用和重新拉起

推荐把“更新”和“启动”拆开：

- 日常启动：由客户端 MCP 管理器直接调用 wrapper
- 更新 beta：手动重新执行上一节那套 `npm i -g ...` + `predy-skill install ...`
- 端口被旧进程占用：单独执行恢复命令，再让客户端重新拉起同一条 wrapper 启动命令

推荐的恢复命令是：

```bash
predy-skill kill-mcp --force
```

`predy-skill mcp` 现在已经补了 `stdin end/close` 和 `stdout EPIPE` 的优雅退出路径，所以正常情况下客户端断开后，旧进程会更容易自己释放 `17654`。如果还是碰到残留进程，再手动执行上面的恢复命令。

注意：

- 浏览器侧如果连着 `ws://127.0.0.1:17654` 或 `wss://localhost:17654`，手动执行 `kill-mcp` 时这条连接会断开，然后依赖页面自己的自动重连
- 客户端自己重复拉起 wrapper 不会主动清旧端口；如果此时 `17654` 还被旧进程占着，启动会失败
- 默认端口是 `17654`，也可以通过 `PREDY_MCP_PORT` 覆盖

### 验证

先执行：

```bash
./scripts/predy_setup_doctor.sh --client codex
./scripts/predy_setup_doctor.sh --client cursor --project /path/to/repo
./scripts/predy_setup_doctor.sh --client codewiz --project /path/to/repo
```

如果你还没确定当前要配哪个客户端，也可以先直接运行：

```bash
./scripts/predy_setup_doctor.sh
```

但这只会检查通用环境和证书，不会默认把结果当成 Codex MCP 状态。

重点检查下面几个字段：

- `target.client` 是你当前要排查的客户端
- `target.config.state` 是当前客户端配置文件的状态；对 Claude 会显示 `manual_required`
- `tool.predy-skill.path` 在跑过 wrapper `update` 之后应该不再是 `MISSING`
- `predy.skill.state=present`
- `predy.mcp.config.mode=auto`（Codex / Cursor / CodeWiz）或 `manual_prompt`（Claude）
- `predy.mcp.config.state=present`（如果当前目标是 Codex / Cursor / CodeWiz）
- `predy.cert.state=present`
- `predy.key.state=present`

常见的配置文件路径是：

- `Codex`: `~/.codex/config.toml`
- `Cursor`: `~/.cursor/mcp.json`
- `CodeWiz`: `~/.rcs/storage/default/CodeWiz.codewiz-agent/settings/global_mcp_settings.json`

可选的运行时检查：

```bash
lsof -nP -iTCP:17654 -sTCP:LISTEN
```
