#!/bin/sh
set -eu

DEFAULT_REGISTRY="http://npm.devops.xiaohongshu.com:7001"
REGISTRY="${PREDY_NPM_REGISTRY-$DEFAULT_REGISTRY}"
PACKAGE="${PREDY_SKILL_PACKAGE:-@predy-js/skill@beta}"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
OUTPUT=""

while [ "$#" -gt 0 ]; do
  case "$1" in
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
    --codex-home)
      CODEX_HOME="${2:?missing value for --codex-home}"
      shift 2
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

if [ -z "$OUTPUT" ]; then
  OUTPUT="$CODEX_HOME/bin/predy-mcp-beta.sh"
fi

OUTPUT_DIR="$(dirname "$OUTPUT")"
mkdir -p "$OUTPUT_DIR"

cat > "$OUTPUT" <<EOF
#!/bin/sh
set -eu

REGISTRY="$REGISTRY"
PACKAGE="$PACKAGE"
CODEX_HOME="\${CODEX_HOME:-$CODEX_HOME}"
CERT="\$HOME/.predy-skill/certs/localhost.pem"
KEY="\$HOME/.predy-skill/certs/localhost-key.pem"
SKILL_DIR="\$CODEX_HOME/skills/predy-code-assistant"

needs_init=0
[ -f "\$CERT" ] || needs_init=1
[ -f "\$KEY" ] || needs_init=1
[ -d "\$SKILL_DIR" ] || needs_init=1

if [ "\$needs_init" -eq 1 ]; then
  if [ -n "\$REGISTRY" ]; then
    env NPM_CONFIG_REGISTRY="\$REGISTRY" \\
      npm exec --yes --package="\$PACKAGE" -- \\
      predy-skill install --codex
  else
    npm exec --yes --package="\$PACKAGE" -- \\
      predy-skill install --codex
  fi
fi

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
