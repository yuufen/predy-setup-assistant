#!/bin/sh
set -eu

DEFAULT_REGISTRY="http://npm.devops.xiaohongshu.com:7001"
REGISTRY="${PREDY_NPM_REGISTRY-$DEFAULT_REGISTRY}"
PACKAGE="${PREDY_SKILL_PACKAGE:-@predy-js/skill@beta}"
PREDY_HOME="${PREDY_HOME:-$HOME/.predy-skill}"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
CLIENT="codex"
PROJECT_DIR=""
OUTPUT=""

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
    --output)
      OUTPUT="${2:?missing value for --output}"
      shift 2
      ;;
    --registry)
      REGISTRY="${2:?missing value for --registry}"
      shift 2
      ;;
    --package)
      PACKAGE="${2:?missing value for --package}"
      shift 2
      ;;
    --predy-home)
      PREDY_HOME="${2:?missing value for --predy-home}"
      shift 2
      ;;
    --codex-home)
      CODEX_HOME="${2:?missing value for --codex-home}"
      shift 2
      ;;
    --claude-home)
      CLAUDE_HOME="${2:?missing value for --claude-home}"
      shift 2
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

case "$CLIENT" in
  codex)
    DEFAULT_OUTPUT="$CODEX_HOME/bin/predy-mcp-beta.sh"
    ;;
  claude)
    DEFAULT_OUTPUT="$PREDY_HOME/bin/predy-mcp-claude-beta.sh"
    ;;
  cursor)
    [ -n "$PROJECT_DIR" ] || {
      printf '%s\n' '--project is required for --client cursor' >&2
      exit 1
    }
    DEFAULT_OUTPUT="$PREDY_HOME/bin/predy-mcp-cursor-beta.sh"
    ;;
  codewiz)
    [ -n "$PROJECT_DIR" ] || {
      printf '%s\n' '--project is required for --client codewiz' >&2
      exit 1
    }
    DEFAULT_OUTPUT="$PREDY_HOME/bin/predy-mcp-codewiz-beta.sh"
    ;;
  copilot)
    [ -n "$PROJECT_DIR" ] || {
      printf '%s\n' '--project is required for --client copilot' >&2
      exit 1
    }
    DEFAULT_OUTPUT="$PREDY_HOME/bin/predy-mcp-copilot-beta.sh"
    ;;
  *)
    printf 'Unknown client: %s\n' "$CLIENT" >&2
    exit 1
    ;;
esac

if [ -z "$OUTPUT" ]; then
  OUTPUT="$DEFAULT_OUTPUT"
fi

OUTPUT_DIR="$(dirname "$OUTPUT")"
mkdir -p "$OUTPUT_DIR"

cat > "$OUTPUT" <<EOF
#!/bin/sh
set -eu

CLIENT="$CLIENT"
PREDY_HOME="\${PREDY_HOME:-$PREDY_HOME}"
CODEX_HOME="\${CODEX_HOME:-$CODEX_HOME}"
CLAUDE_HOME="\${CLAUDE_HOME:-$CLAUDE_HOME}"
PROJECT_DIR="\${PREDY_MCP_PROJECT_DIR:-$PROJECT_DIR}"
PORT="\${PREDY_MCP_PORT:-17654}"

fail() {
  printf '%s\n' "\$1" >&2
  exit 1
}

print_install_hint() {
  if [ -n "$REGISTRY" ]; then
    printf 'env NPM_CONFIG_REGISTRY=%s npm i -g %s\n' "$REGISTRY" "$PACKAGE" >&2
  else
    printf 'npm i -g %s\n' "$PACKAGE" >&2
  fi

  case "\$CLIENT" in
    codex)
      printf 'predy-skill install --codex\n' >&2
      ;;
    claude)
      printf 'predy-skill install --claude\n' >&2
      ;;
    cursor)
      printf 'predy-skill install --cursor --project %s\n' "\$PROJECT_DIR" >&2
      ;;
    codewiz)
      printf 'predy-skill install --codewiz --project %s\n' "\$PROJECT_DIR" >&2
      ;;
    copilot)
      printf 'predy-skill install --copilot --project %s\n' "\$PROJECT_DIR" >&2
      ;;
  esac
}

resolve_predy_skill_bin() {
  if [ -n "\${PREDY_SKILL_BIN:-}" ] && [ -x "\$PREDY_SKILL_BIN" ]; then
    printf '%s\n' "\$PREDY_SKILL_BIN"
    return 0
  fi

  if command -v npm >/dev/null 2>&1; then
    npm_prefix="\$(npm prefix -g 2>/dev/null || npm config get prefix 2>/dev/null || true)"
    if [ -n "\$npm_prefix" ] && [ -x "\$npm_prefix/bin/predy-skill" ]; then
      printf '%s\n' "\$npm_prefix/bin/predy-skill"
      return 0
    fi
  fi

  if command -v predy-skill >/dev/null 2>&1; then
    command -v predy-skill
    return 0
  fi

  return 1
}

require_predy_skill_bin() {
  predy_skill_bin="\$(resolve_predy_skill_bin || true)"
  if [ -z "\$predy_skill_bin" ]; then
    printf '%s\n' 'predy-skill is not installed globally yet. Run these commands first:' >&2
    print_install_hint
    exit 1
  fi
  printf '%s\n' "\$predy_skill_bin"
}

find_listener_pids() {
  if ! command -v lsof >/dev/null 2>&1; then
    return 0
  fi

  lsof -nP -t -iTCP:"\$PORT" -sTCP:LISTEN 2>/dev/null || true
}

stop_existing_listener() {
  predy_skill_bin="\$(resolve_predy_skill_bin || true)"
  if [ -n "\$predy_skill_bin" ]; then
    "\$predy_skill_bin" kill-mcp --port "\$PORT" >/dev/null 2>&1 || \\
      "\$predy_skill_bin" kill-mcp --port "\$PORT" --force >/dev/null 2>&1 || true
  fi

  stale_pids="\$(find_listener_pids)"
  [ -n "\$stale_pids" ] || return 0

  printf 'Predy MCP wrapper: force killing remaining listener on port %s: %s\n' "\$PORT" "\$stale_pids" >&2

  for pid in \$stale_pids; do
    [ "\$pid" = "\$\$" ] && continue
    kill -9 "\$pid" 2>/dev/null || true
  done
}

predy_skill_bin="\$(require_predy_skill_bin)"
stop_existing_listener
exec env PREDY_MCP_WS_PORT="\$PORT" "\$predy_skill_bin" mcp
EOF

chmod +x "$OUTPUT"
printf '%s\n' "$OUTPUT"
