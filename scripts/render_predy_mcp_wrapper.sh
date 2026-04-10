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

REGISTRY="$REGISTRY"
PACKAGE="$PACKAGE"
CLIENT="$CLIENT"
PREDY_HOME="\${PREDY_HOME:-$PREDY_HOME}"
CODEX_HOME="\${CODEX_HOME:-$CODEX_HOME}"
CLAUDE_HOME="\${CLAUDE_HOME:-$CLAUDE_HOME}"
PROJECT_DIR="\${PREDY_MCP_PROJECT_DIR:-$PROJECT_DIR}"
PORT="\${PREDY_MCP_PORT:-17654}"
CERT="\$PREDY_HOME/certs/localhost.pem"
KEY="\$PREDY_HOME/certs/localhost-key.pem"

case "\$CLIENT" in
  codex)
    SKILL_PATH="\$CODEX_HOME/skills/predy-code-assistant"
    ;;
  claude)
    SKILL_PATH="\$CLAUDE_HOME/skills/predy-code-assistant"
    ;;
  cursor)
    SKILL_PATH="\$PROJECT_DIR/.cursor/rules/predy-code-assistant.mdc"
    ;;
  codewiz)
    SKILL_PATH="\$PROJECT_DIR/.codewiz/skills/predy-code-assistant"
    ;;
  copilot)
    SKILL_PATH="\$PROJECT_DIR/.github/skills/predy-code-assistant"
    ;;
  *)
    printf 'Unknown client in wrapper: %s\n' "\$CLIENT" >&2
    exit 1
    ;;
esac

run_install() {
  if [ -n "\$REGISTRY" ]; then
    case "\$CLIENT" in
      codex)
        env NPM_CONFIG_REGISTRY="\$REGISTRY" \\
          npm exec --yes --package="\$PACKAGE" -- \\
          predy-skill install --codex
        ;;
      claude)
        env NPM_CONFIG_REGISTRY="\$REGISTRY" \\
          npm exec --yes --package="\$PACKAGE" -- \\
          predy-skill install --claude
        ;;
      cursor)
        env NPM_CONFIG_REGISTRY="\$REGISTRY" \\
          npm exec --yes --package="\$PACKAGE" -- \\
          predy-skill install --cursor --project "\$PROJECT_DIR"
        ;;
      codewiz)
        env NPM_CONFIG_REGISTRY="\$REGISTRY" \\
          npm exec --yes --package="\$PACKAGE" -- \\
          predy-skill install --codewiz --project "\$PROJECT_DIR"
        ;;
      copilot)
        env NPM_CONFIG_REGISTRY="\$REGISTRY" \\
          npm exec --yes --package="\$PACKAGE" -- \\
          predy-skill install --copilot --project "\$PROJECT_DIR"
        ;;
    esac
  else
    case "\$CLIENT" in
      codex)
        npm exec --yes --package="\$PACKAGE" -- \\
          predy-skill install --codex
        ;;
      claude)
        npm exec --yes --package="\$PACKAGE" -- \\
          predy-skill install --claude
        ;;
      cursor)
        npm exec --yes --package="\$PACKAGE" -- \\
          predy-skill install --cursor --project "\$PROJECT_DIR"
        ;;
      codewiz)
        npm exec --yes --package="\$PACKAGE" -- \\
          predy-skill install --codewiz --project "\$PROJECT_DIR"
        ;;
      copilot)
        npm exec --yes --package="\$PACKAGE" -- \\
          predy-skill install --copilot --project "\$PROJECT_DIR"
        ;;
    esac
  fi
}

find_listener_pids() {
  if ! command -v lsof >/dev/null 2>&1; then
    return 0
  fi

  lsof -nP -t -iTCP:"\$PORT" -sTCP:LISTEN 2>/dev/null || true
}

cleanup_stale_listener() {
  stale_pids="\$(find_listener_pids)"
  [ -n "\$stale_pids" ] || return 0

  printf 'Predy MCP wrapper: stopping stale listener on port %s: %s\n' "\$PORT" "\$stale_pids" >&2

  for pid in \$stale_pids; do
    [ "\$pid" = "\$\$" ] && continue
    kill "\$pid" 2>/dev/null || true
  done

  sleep 1
  stale_pids="\$(find_listener_pids)"
  [ -n "\$stale_pids" ] || return 0

  printf 'Predy MCP wrapper: force killing remaining listener on port %s: %s\n' "\$PORT" "\$stale_pids" >&2

  for pid in \$stale_pids; do
    [ "\$pid" = "\$\$" ] && continue
    kill -9 "\$pid" 2>/dev/null || true
  done
}

needs_init=0
[ -f "\$CERT" ] || needs_init=1
[ -f "\$KEY" ] || needs_init=1
[ -e "\$SKILL_PATH" ] || needs_init=1

if [ "\$needs_init" -eq 1 ]; then
  run_install
fi

cleanup_stale_listener

if [ -n "\$REGISTRY" ]; then
  exec env NPM_CONFIG_REGISTRY="\$REGISTRY" \\
    npm exec --yes --package="\$PACKAGE" -- \\
    predy-skill mcp
else
  exec npm exec --yes --package="\$PACKAGE" -- \\
    predy-skill mcp
fi
EOF

chmod +x "$OUTPUT"
printf '%s\n' "$OUTPUT"
