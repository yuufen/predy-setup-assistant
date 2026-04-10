#!/usr/bin/env python3

import argparse
import json


CLIENT_LABELS = {
    "codex": "Codex",
    "claude": "Claude",
    "cursor": "Cursor",
    "codewiz": "CodeWiz",
    "copilot": "Copilot",
}

DEFAULT_SERVER_NAMES = {
    "codex": "predy",
    "claude": "predy-mcp",
    "cursor": "predy-mcp",
    "codewiz": "predy-mcp",
    "copilot": "predy-mcp",
}

CONFIG_HINTS = {
    "codex": "~/.codex/config.toml",
    "cursor": "~/.cursor/mcp.json",
    "codewiz": "~/.rcs/storage/default/CodeWiz.codewiz-agent/settings/global_mcp_settings.json",
}


def main() -> None:
    parser = argparse.ArgumentParser(description="Render a fallback prompt for manual MCP configuration.")
    parser.add_argument("--client", choices=sorted(CLIENT_LABELS.keys()), required=True, help="Target client")
    parser.add_argument("--command", required=True, help="Startup command for the STDIO MCP server")
    parser.add_argument("--name", help="MCP server name")
    parser.add_argument("--arg", dest="args", action="append", default=[], help="Argument to include in args[]")
    args = parser.parse_args()

    command = args.command
    arg_list = json.dumps(args.args, ensure_ascii=False)
    client_label = CLIENT_LABELS[args.client]
    server_name = args.name or DEFAULT_SERVER_NAMES[args.client]
    config_hint = CONFIG_HINTS.get(args.client)

    prompt = (
        f"请帮我在 {client_label} 里配置一个 STDIO MCP Server。\n"
        f"名称：{server_name}\n"
        f"启动命令：{command}\n"
        f"参数：{arg_list}\n"
        "如果已经存在同名 server，请更新为这套配置，不要保留重复项。"
    )
    if config_hint:
        prompt += f"\n如果当前客户端支持直接编辑配置文件，请把它写到：{config_hint}"
    print(prompt)


if __name__ == "__main__":
    main()
