#!/usr/bin/env python3

import argparse
import json


CLIENT_LABELS = {
    "claude": "Claude",
    "cursor": "Cursor",
    "copilot": "Copilot",
}


def main() -> None:
    parser = argparse.ArgumentParser(description="Render a prompt for clients that need manual MCP configuration.")
    parser.add_argument("--client", choices=sorted(CLIENT_LABELS.keys()), required=True, help="Target client")
    parser.add_argument("--command", required=True, help="Startup command for the STDIO MCP server")
    parser.add_argument("--name", default="predy-mcp", help="MCP server name")
    parser.add_argument("--arg", dest="args", action="append", default=[], help="Argument to include in args[]")
    args = parser.parse_args()

    command = args.command
    arg_list = json.dumps(args.args, ensure_ascii=False)
    client_label = CLIENT_LABELS[args.client]

    prompt = (
        f"请帮我在 {client_label} 里配置一个 STDIO MCP Server。\n"
        f"名称：{args.name}\n"
        f"启动命令：{command}\n"
        f"参数：{arg_list}\n"
        "如果已经存在同名 server，请更新为这套配置，不要保留重复项。"
    )
    print(prompt)


if __name__ == "__main__":
    main()
