#!/bin/sh
set -eu

print_kv() {
  printf '%s=%s\n' "$1" "$2"
}

tool_path() {
  if command -v "$1" >/dev/null 2>&1; then
    command -v "$1"
  else
    printf '%s' 'MISSING'
  fi
}

tool_version() {
  if command -v "$1" >/dev/null 2>&1; then
    "$@" 2>/dev/null | head -n 1
  else
    printf '%s' 'MISSING'
  fi
}

file_state() {
  if [ -e "$1" ]; then
    printf '%s' 'present'
  else
    printf '%s' 'missing'
  fi
}

dir_state() {
  if [ -d "$1" ]; then
    printf '%s' 'present'
  else
    printf '%s' 'missing'
  fi
}

OS_NAME="$(uname -s 2>/dev/null || printf '%s' unknown)"
ARCH_NAME="$(uname -m 2>/dev/null || printf '%s' unknown)"
HOME_DIR="${HOME:-}"
CODEX_HOME_DIR="${CODEX_HOME:-$HOME_DIR/.codex}"
CODEX_CONFIG_PATH="$CODEX_HOME_DIR/config.toml"
CODEX_BIN_DIR="$CODEX_HOME_DIR/bin"
CODEWIZ_MCP_CONFIG_PATH="${CODEWIZ_MCP_CONFIG_PATH:-$HOME_DIR/.rcs/storage/default/CodeWiz.codewiz-agent/settings/global_mcp_settings.json}"
PREDY_SKILL_DIR="$CODEX_HOME_DIR/skills/predy-code-assistant"
PREDY_CERT_DIR="$HOME_DIR/.predy-skill/certs"
PREDY_CERT_PATH="$PREDY_CERT_DIR/localhost.pem"
PREDY_KEY_PATH="$PREDY_CERT_DIR/localhost-key.pem"

print_kv "os.name" "$OS_NAME"
print_kv "os.arch" "$ARCH_NAME"
print_kv "home.dir" "$HOME_DIR"
print_kv "codex.home" "$CODEX_HOME_DIR"
print_kv "codex.config" "$CODEX_CONFIG_PATH"
print_kv "codex.config.state" "$(file_state "$CODEX_CONFIG_PATH")"
print_kv "codex.bin.dir" "$CODEX_BIN_DIR"
print_kv "codex.bin.state" "$(dir_state "$CODEX_BIN_DIR")"
print_kv "codewiz.mcp.config" "$CODEWIZ_MCP_CONFIG_PATH"
print_kv "codewiz.mcp.config.state" "$(file_state "$CODEWIZ_MCP_CONFIG_PATH")"
print_kv "predy.skill.dir" "$PREDY_SKILL_DIR"
print_kv "predy.skill.state" "$(dir_state "$PREDY_SKILL_DIR")"
print_kv "predy.cert.path" "$PREDY_CERT_PATH"
print_kv "predy.cert.state" "$(file_state "$PREDY_CERT_PATH")"
print_kv "predy.key.path" "$PREDY_KEY_PATH"
print_kv "predy.key.state" "$(file_state "$PREDY_KEY_PATH")"

print_kv "tool.node.path" "$(tool_path node)"
print_kv "tool.node.version" "$(tool_version node -v)"
print_kv "tool.npm.path" "$(tool_path npm)"
print_kv "tool.npm.version" "$(tool_version npm -v)"
print_kv "tool.npx.path" "$(tool_path npx)"
print_kv "tool.npx.version" "$(tool_version npx --version)"
print_kv "tool.python3.path" "$(tool_path python3)"
print_kv "tool.python3.version" "$(tool_version python3 --version)"
print_kv "tool.brew.path" "$(tool_path brew)"
print_kv "tool.brew.version" "$(tool_version brew --version)"
print_kv "tool.mkcert.path" "$(tool_path mkcert)"
print_kv "tool.mkcert.version" "$(tool_version mkcert -version)"

if [ -f "$CODEX_CONFIG_PATH" ] && grep -Eq '^\[mcp_servers\.predy\]' "$CODEX_CONFIG_PATH"; then
  print_kv "codex.predy_mcp_config" "present"
else
  print_kv "codex.predy_mcp_config" "missing"
fi

if [ -f "$CODEWIZ_MCP_CONFIG_PATH" ] && grep -Eq '"(predy-mcp|predy-skill)"[[:space:]]*:' "$CODEWIZ_MCP_CONFIG_PATH"; then
  print_kv "codewiz.predy_mcp_config" "present"
else
  print_kv "codewiz.predy_mcp_config" "missing"
fi
