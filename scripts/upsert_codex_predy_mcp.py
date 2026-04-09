#!/usr/bin/env python3

import argparse
import os
from pathlib import Path
from typing import List


def escape_toml(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def render_block(name: str, command: str, args: List[str]) -> str:
    rendered_args = ", ".join(f'"{escape_toml(arg)}"' for arg in args)
    return (
        f"[mcp_servers.{name}]\n"
        f'command = "{escape_toml(command)}"\n'
        f"args = [{rendered_args}]\n"
    )


def upsert_block(content: str, block_name: str, block: str) -> str:
    lines = content.splitlines(keepends=True)
    start = None

    for index, line in enumerate(lines):
        if line.strip() == f"[mcp_servers.{block_name}]":
            start = index
            break

    if start is None:
        if content and not content.endswith("\n"):
            content += "\n"
        if content and not content.endswith("\n\n"):
            content += "\n"
        return content + block

    end = len(lines)
    for index in range(start + 1, len(lines)):
        stripped = lines[index].strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            end = index
            break

    replacement = block if block.endswith("\n") else block + "\n"
    updated = "".join(lines[:start]) + replacement + "".join(lines[end:])
    return updated


def main() -> None:
    parser = argparse.ArgumentParser(description="Insert or replace a Codex Predy MCP block.")
    parser.add_argument("--config", required=True, help="Path to config.toml")
    parser.add_argument("--command", required=True, help="Absolute path to the wrapper script")
    parser.add_argument("--name", default="predy", help="MCP server name")
    parser.add_argument("--arg", dest="args", action="append", default=[], help="Argument to include in args[]")
    args = parser.parse_args()

    config_path = Path(os.path.expanduser(args.config))
    command_path = os.path.expanduser(args.command)

    config_path.parent.mkdir(parents=True, exist_ok=True)
    original = config_path.read_text(encoding="utf-8") if config_path.exists() else ""
    updated = upsert_block(original, args.name, render_block(args.name, command_path, args.args))
    config_path.write_text(updated, encoding="utf-8")


if __name__ == "__main__":
    main()
