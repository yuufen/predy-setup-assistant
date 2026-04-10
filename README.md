# Predy Setup Assistant

## 安装说明（给美术 / 设计同学）

这份说明是给不需要写代码、只想把 Predy 装起来的同学准备的。

你不需要先安装 `predy-skill`，也不需要先 `git clone` 仓库。
只要复制下面对应的一段命令到终端里执行，然后按提示操作就可以。

## 开始前

1. 先确认你正在用哪一个 AI 客户端：
   `Codex`、`Claude`、`Cursor`、`CodeWiz`
2. 打开你电脑上的“终端”应用。
3. 下面每一段命令都建议整段复制，然后一次性回车。

## 如果你用的是 Codex

1. 把下面这两行命令复制到终端里执行：

```bash
curl -L -o /tmp/predy-setup-install.sh https://code.devops.xiaohongshu.com/fe/infra/predy-setup-assistant/-/raw/main/install.sh
bash /tmp/predy-setup-install.sh --codex
```

2. 安装完成后，彻底退出 Codex，再重新打开。
3. 在 Codex 里输入这句话：

```text
$predy-setup-assistant 帮我一步步安装 Predy
```

4. 后面如果 Codex 提示你要安装 Node 或写配置，按提示确认即可。本地证书会在 Predy 安装时自动准备。

## 如果你用的是 Claude

1. 把下面这两行命令复制到终端里执行：

```bash
curl -L -o /tmp/predy-setup-install.sh https://code.devops.xiaohongshu.com/fe/infra/predy-setup-assistant/-/raw/main/install.sh
bash /tmp/predy-setup-install.sh --claude
```

2. 安装完成后，彻底退出 Claude，再重新打开。
3. 在 Claude 里输入这句话：

```text
请使用 predy-setup-assistant 帮我一步步安装 Predy
```

4. 后面如果 Claude 提示你要安装 Node 或写配置，按提示确认即可。本地证书会在 Predy 安装时自动准备。

## 如果你用的是 Cursor

1. 先在终端里进入你当前项目的目录。
   如果你不知道项目目录是什么，先找工程同学确认。
2. 进入项目目录后，执行下面这两行命令：

```bash
curl -L -o /tmp/predy-setup-install.sh https://code.devops.xiaohongshu.com/fe/infra/predy-setup-assistant/-/raw/main/install.sh
bash /tmp/predy-setup-install.sh --cursor --project "$PWD"
```

3. 回到 Cursor，重新打开这个项目。
4. 在聊天框里输入这句话：

```text
帮我一步步安装 Predy
```

5. 后面如果 Cursor 提示你要安装 Node 或写配置，按提示确认即可。本地证书会在 Predy 安装时自动准备。

## 如果你用的是 CodeWiz

1. 先在终端里进入你当前项目的目录。
   如果你不知道项目目录是什么，先找工程同学确认。
2. 进入项目目录后，执行下面这两行命令：

```bash
curl -L -o /tmp/predy-setup-install.sh https://code.devops.xiaohongshu.com/fe/infra/predy-setup-assistant/-/raw/main/install.sh
bash /tmp/predy-setup-install.sh --codewiz --project "$PWD"
```

3. 回到 CodeWiz，重新打开这个项目。
4. 在聊天框里输入这句话：

```text
帮我一步步安装 Predy
```

5. 后面如果 CodeWiz 提示你要安装 Node 或写配置，按提示确认即可。本地证书会在 Predy 安装时自动准备。

## 安装过程中常见情况

1. 如果终端提示你允许下载、允许访问网络、允许写入配置，正常确认即可。
2. 如果系统提示你输入 Mac 登录密码，这通常是正常的，因为它可能在安装基础工具或本地证书。
3. 如果 AI 提示你要安装 Homebrew 或 Node，这是正常步骤，不用自己提前折腾。
4. 本地证书和 `mkcert` 会在 `predy-skill install --codex` 时自动处理，不需要你先手动安装证书工具。
5. 如果浏览器或系统提示你信任本地证书，按提示操作即可。

## 什么情况需要找工程同学

1. 你不知道当前项目目录是什么。
2. 终端提示没有权限，或者公司设备不允许安装工具。
3. 下载地址打不开，或者一直跳转到登录页。
4. 安装到一半，你不确定某个系统弹窗该不该点。

## 一句话总结

先执行一条安装命令，把 `predy-setup-assistant` 放进你的 AI 客户端里；然后直接对 AI 说“帮我一步步安装 Predy”，后面的 Node、Predy、本地证书和 MCP 都会按步骤带你完成。

## 给工程 / 支持同学的补充说明

如果你不是终端新手，或者你是在帮别人排查安装问题，下面这些信息可以直接用。

### 内部包源

- 包源地址：`http://npm.devops.xiaohongshu.com:7001`
- 包名：`@predy-js/skill@beta`

### 实际安装 Predy 的命令

如果机器已经具备基础条件，需要直接走 Predy 的真实安装流程，可以执行：

```bash
env NPM_CONFIG_REGISTRY=http://npm.devops.xiaohongshu.com:7001 \
  npm exec --yes --package=@predy-js/skill@beta -- \
  predy-skill install --codex
```

### 生成 Codex MCP wrapper

仓库里的 wrapper 生成脚本已经默认使用内部包源，所以一般不需要再手动传 `--registry`：

```bash
./scripts/render_predy_mcp_wrapper.sh \
  --output "$HOME/.codex/bin/predy-mcp-beta.sh"
```

如果你想覆盖默认包源，也可以显式传：

```bash
./scripts/render_predy_mcp_wrapper.sh \
  --registry "http://npm.devops.xiaohongshu.com:7001" \
  --package "@predy-js/skill@beta" \
  --output "$HOME/.codex/bin/predy-mcp-beta.sh"
```

### 写入 Codex MCP 配置

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

### 验证

先执行：

```bash
./scripts/predy_setup_doctor.sh
```

重点检查下面几个字段：

- `predy.skill.state=present`
- `predy.cert.state=present`
- `predy.key.state=present`
- `codex.predy_mcp_config=present`

可选的运行时检查：

```bash
lsof -nP -iTCP:17654 -sTCP:LISTEN
```
