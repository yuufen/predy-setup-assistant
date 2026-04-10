#!/bin/sh
set -eu

CLIENT="${PREDY_SETUP_CLIENT:-}"
PROJECT_DIR="${PREDY_SETUP_PROJECT_DIR:-}"

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

usage() {
  cat <<'EOF'
Usage:
  ./scripts/predy_setup_doctor.sh [--client codex|claude|cursor|codewiz|copilot] [--project /path/to/repo]

Notes:
  - Pass --client to check the target client's skill and MCP state.
  - Without --client, the script only reports generic environment and certificate state.
  - --project is required for cursor, codewiz, and copilot if you want target-specific skill state.
EOF
}

state_from_path() {
  kind="$1"
  target_path="$2"

  if [ -z "$target_path" ]; then
    printf '%s' 'project_required'
    return
  fi

  case "$kind" in
    file)
      file_state "$target_path"
      ;;
    dir)
      dir_state "$target_path"
      ;;
    *)
      printf '%s' 'unknown'
      ;;
  esac
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --client)
      CLIENT="${2:?missing value for --client}"
      shift 2
      ;;
    --project)
      PROJECT_DIR="${2:?missing value for --project}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

OS_NAME="$(uname -s 2>/dev/null || printf '%s' unknown)"
ARCH_NAME="$(uname -m 2>/dev/null || printf '%s' unknown)"
HOME_DIR="${HOME:-}"
CODEX_HOME_DIR="${CODEX_HOME:-$HOME_DIR/.codex}"
CLAUDE_HOME_DIR="${CLAUDE_HOME:-$HOME_DIR/.claude}"
CODEX_CONFIG_PATH="$CODEX_HOME_DIR/config.toml"
CODEX_BIN_DIR="$CODEX_HOME_DIR/bin"
CODEWIZ_MCP_CONFIG_PATH="${CODEWIZ_MCP_CONFIG_PATH:-$HOME_DIR/.rcs/storage/default/CodeWiz.codewiz-agent/settings/global_mcp_settings.json}"
PREDY_CERT_DIR="$HOME_DIR/.predy-skill/certs"
PREDY_CERT_PATH="$PREDY_CERT_DIR/localhost.pem"
PREDY_KEY_PATH="$PREDY_CERT_DIR/localhost-key.pem"
PREDY_SKILL_DIR=""
PREDY_SKILL_STATE="client_required"
TARGET_CONFIG_PATH=""
TARGET_CONFIG_STATE="client_required"
PREDY_MCP_CONFIG_PATH=""
PREDY_MCP_CONFIG_MODE="client_required"
PREDY_MCP_CONFIG_STATE="client_required"

case "$CLIENT" in
  "")
    CLIENT="unspecified"
    ;;
  codex)
    PREDY_SKILL_DIR="$CODEX_HOME_DIR/skills/predy-code-assistant"
    PREDY_SKILL_STATE="$(state_from_path dir "$PREDY_SKILL_DIR")"
    TARGET_CONFIG_PATH="$CODEX_CONFIG_PATH"
    TARGET_CONFIG_STATE="$(file_state "$TARGET_CONFIG_PATH")"
    PREDY_MCP_CONFIG_PATH="$CODEX_CONFIG_PATH"
    PREDY_MCP_CONFIG_MODE="auto"
    if [ -f "$CODEX_CONFIG_PATH" ] && grep -Eq '^\[mcp_servers\.predy\]' "$CODEX_CONFIG_PATH"; then
      PREDY_MCP_CONFIG_STATE="present"
    else
      PREDY_MCP_CONFIG_STATE="missing"
    fi
    ;;
  claude)
    PREDY_SKILL_DIR="$CLAUDE_HOME_DIR/skills/predy-code-assistant"
    PREDY_SKILL_STATE="$(state_from_path dir "$PREDY_SKILL_DIR")"
    TARGET_CONFIG_STATE="manual_required"
    PREDY_MCP_CONFIG_MODE="manual_prompt"
    PREDY_MCP_CONFIG_STATE="manual_required"
    ;;
  cursor)
    if [ -n "$PROJECT_DIR" ]; then
      PREDY_SKILL_DIR="$PROJECT_DIR/.cursor/rules/predy-code-assistant.mdc"
      PREDY_MCP_CONFIG_STATE="manual_required"
    else
      PREDY_SKILL_DIR=""
      PREDY_MCP_CONFIG_STATE="project_required"
    fi
    PREDY_SKILL_STATE="$(state_from_path file "$PREDY_SKILL_DIR")"
    TARGET_CONFIG_STATE="$PREDY_MCP_CONFIG_STATE"
    PREDY_MCP_CONFIG_MODE="manual_prompt"
    ;;
  codewiz)
    if [ -n "$PROJECT_DIR" ]; then
      PREDY_SKILL_DIR="$PROJECT_DIR/.codewiz/skills/predy-code-assistant"
      PREDY_MCP_CONFIG_STATE="missing"
    else
      PREDY_SKILL_DIR=""
      PREDY_MCP_CONFIG_STATE="project_required"
    fi
    PREDY_SKILL_STATE="$(state_from_path dir "$PREDY_SKILL_DIR")"
    TARGET_CONFIG_PATH="$CODEWIZ_MCP_CONFIG_PATH"
    TARGET_CONFIG_STATE="$(file_state "$TARGET_CONFIG_PATH")"
    PREDY_MCP_CONFIG_PATH="$CODEWIZ_MCP_CONFIG_PATH"
    PREDY_MCP_CONFIG_MODE="auto"
    if [ "$PREDY_MCP_CONFIG_STATE" != "project_required" ] &&
      [ -f "$CODEWIZ_MCP_CONFIG_PATH" ] &&
      grep -Eq '"(predy-mcp|predy-skill)"[[:space:]]*:' "$CODEWIZ_MCP_CONFIG_PATH"; then
      PREDY_MCP_CONFIG_STATE="present"
    fi
    ;;
  copilot)
    if [ -n "$PROJECT_DIR" ]; then
      PREDY_SKILL_DIR="$PROJECT_DIR/.github/skills/predy-code-assistant"
      PREDY_MCP_CONFIG_STATE="manual_required"
    else
      PREDY_SKILL_DIR=""
      PREDY_MCP_CONFIG_STATE="project_required"
    fi
    PREDY_SKILL_STATE="$(state_from_path dir "$PREDY_SKILL_DIR")"
    TARGET_CONFIG_STATE="$PREDY_MCP_CONFIG_STATE"
    PREDY_MCP_CONFIG_MODE="manual_prompt"
    ;;
  *)
    printf 'Unknown client: %s\n' "$CLIENT" >&2
    exit 1
    ;;
esac

print_kv "os.name" "$OS_NAME"
print_kv "os.arch" "$ARCH_NAME"
print_kv "home.dir" "$HOME_DIR"
print_kv "target.client" "$CLIENT"
print_kv "target.project" "${PROJECT_DIR:-}"
print_kv "target.config.path" "$TARGET_CONFIG_PATH"
print_kv "target.config.state" "$TARGET_CONFIG_STATE"
print_kv "predy.skill.dir" "$PREDY_SKILL_DIR"
print_kv "predy.skill.state" "$PREDY_SKILL_STATE"
print_kv "predy.mcp.config.path" "$PREDY_MCP_CONFIG_PATH"
print_kv "predy.mcp.config.mode" "$PREDY_MCP_CONFIG_MODE"
print_kv "predy.mcp.config.state" "$PREDY_MCP_CONFIG_STATE"
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
