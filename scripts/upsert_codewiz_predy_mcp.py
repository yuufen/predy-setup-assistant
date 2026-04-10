#!/usr/bin/env python3

import argparse
import json
import os
from pathlib import Path
from typing import Any, Dict, List, Optional


DEFAULT_CONFIG = "~/.rcs/storage/default/CodeWiz.codewiz-agent/settings/global_mcp_settings.json"


def load_config(path: Path) -> Dict[str, Any]:
    if not path.exists():
        return {}

    content = path.read_text(encoding="utf-8").strip()
    if not content:
        return {}

    data = json.loads(content)
    if not isinstance(data, dict):
        raise ValueError("CodeWiz MCP config must be a JSON object.")
    return data


def build_server(
    command: str,
    args: List[str],
    existing: Optional[Dict[str, Any]],
    always_allow: Optional[List[str]],
) -> Dict[str, Any]:
    server: Dict[str, Any] = dict(existing or {})
    server["type"] = "stdio"
    server["command"] = command
    server["args"] = args

    if always_allow is not None:
        server["alwaysAllow"] = always_allow

    return server


def main() -> None:
    parser = argparse.ArgumentParser(description="Insert or replace a CodeWiz Predy MCP server entry.")
    parser.add_argument("--config", default=DEFAULT_CONFIG, help=f"Path to global_mcp_settings.json (default: {DEFAULT_CONFIG})")
    parser.add_argument("--command", required=True, help="Absolute path to the wrapper script or command")
    parser.add_argument("--name", default="predy-mcp", help="MCP server name")
    parser.add_argument("--arg", dest="args", action="append", default=[], help="Argument to include in args[]")
    parser.add_argument(
        "--always-allow",
        dest="always_allow",
        action="append",
        default=None,
        help="Tool name to add to alwaysAllow[]; repeat to add multiple tools",
    )
    args = parser.parse_args()

    config_path = Path(os.path.expanduser(args.config))
    command_path = os.path.expanduser(args.command)

    config_path.parent.mkdir(parents=True, exist_ok=True)
    data = load_config(config_path)

    mcp_servers = data.get("mcpServers")
    if not isinstance(mcp_servers, dict):
        mcp_servers = {}

    existing = mcp_servers.get(args.name)
    if existing is not None and not isinstance(existing, dict):
        raise ValueError(f"Existing mcpServers.{args.name} entry is not an object.")

    mcp_servers[args.name] = build_server(command_path, args.args, existing, args.always_allow)
    data["mcpServers"] = mcp_servers

    config_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
