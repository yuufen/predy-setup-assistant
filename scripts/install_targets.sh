#!/bin/sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
SKILL_NAME="predy-setup-assistant"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CLAUDE_HOME="$HOME/.claude"
PROJECT_DIR=""
INSTALL_CODEX=0
INSTALL_CLAUDE=0
INSTALL_CURSOR=0
INSTALL_CODEWIZ=0
INSTALL_COPILOT=0

copy_dir() {
  src="$1"
  dst="$2"
  mkdir -p "$(dirname "$dst")"
  rsync -a --delete \
    --exclude ".git" \
    --exclude ".DS_Store" \
    --exclude "__pycache__" \
    "$src/" "$dst/"
}

copy_file() {
  src="$1"
  dst="$2"
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --codex)
      INSTALL_CODEX=1
      shift
      ;;
    --claude)
      INSTALL_CLAUDE=1
      shift
      ;;
    --cursor)
      INSTALL_CURSOR=1
      shift
      ;;
    --codewiz)
      INSTALL_CODEWIZ=1
      shift
      ;;
    --copilot)
      INSTALL_COPILOT=1
      shift
      ;;
    --project)
      PROJECT_DIR="${2:?missing value for --project}"
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
      printf '未知参数：%s\n' "$1" >&2
      exit 1
      ;;
  esac
done

if [ "$INSTALL_CODEX" -eq 0 ] && [ "$INSTALL_CLAUDE" -eq 0 ] && [ "$INSTALL_CURSOR" -eq 0 ] && [ "$INSTALL_CODEWIZ" -eq 0 ] && [ "$INSTALL_COPILOT" -eq 0 ]; then
  INSTALL_CODEX=1
  INSTALL_CLAUDE=1
  INSTALL_CURSOR=1
  INSTALL_CODEWIZ=1
  INSTALL_COPILOT=1
fi

if { [ "$INSTALL_CURSOR" -eq 1 ] || [ "$INSTALL_CODEWIZ" -eq 1 ] || [ "$INSTALL_COPILOT" -eq 1 ]; } && [ -z "$PROJECT_DIR" ]; then
  printf '%s\n' '项目型安装必须传 --project' >&2
  exit 1
fi

if [ "$INSTALL_CODEX" -eq 1 ]; then
  copy_dir "$ROOT_DIR" "$CODEX_HOME/skills/$SKILL_NAME"
  printf 'Codex 安装完成：%s\n' "$CODEX_HOME/skills/$SKILL_NAME"
fi

if [ "$INSTALL_CLAUDE" -eq 1 ]; then
  copy_dir "$ROOT_DIR" "$CLAUDE_HOME/skills/$SKILL_NAME"
  copy_file "$ROOT_DIR/claude/$SKILL_NAME.md" "$CLAUDE_HOME/agents/$SKILL_NAME.md"
  printf 'Claude skill 安装完成：%s\n' "$CLAUDE_HOME/skills/$SKILL_NAME"
  printf 'Claude agent 安装完成：%s\n' "$CLAUDE_HOME/agents/$SKILL_NAME.md"
fi

if [ "$INSTALL_CURSOR" -eq 1 ]; then
  copy_dir "$ROOT_DIR" "$PROJECT_DIR/.cursor/$SKILL_NAME"
  copy_file "$ROOT_DIR/cursor/$SKILL_NAME.mdc" "$PROJECT_DIR/.cursor/rules/$SKILL_NAME.mdc"
  printf 'Cursor helper bundle 安装完成：%s\n' "$PROJECT_DIR/.cursor/$SKILL_NAME"
  printf 'Cursor rule 安装完成：%s\n' "$PROJECT_DIR/.cursor/rules/$SKILL_NAME.mdc"
fi

if [ "$INSTALL_CODEWIZ" -eq 1 ]; then
  copy_dir "$ROOT_DIR" "$PROJECT_DIR/.codewiz/skills/$SKILL_NAME"
  printf 'CodeWiz skill 安装完成：%s\n' "$PROJECT_DIR/.codewiz/skills/$SKILL_NAME"
fi

if [ "$INSTALL_COPILOT" -eq 1 ]; then
  copy_dir "$ROOT_DIR" "$PROJECT_DIR/.github/skills/$SKILL_NAME"
  printf 'Copilot skill 安装完成：%s\n' "$PROJECT_DIR/.github/skills/$SKILL_NAME"
fi
