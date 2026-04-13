#!/bin/sh
set -eu

SKILL_NAME="predy-setup-assistant"
DEFAULT_REPO_HOST="https://github.com"
DEFAULT_REPO="yuufen/predy-setup-assistant"
DEFAULT_REPO_URL="$DEFAULT_REPO_HOST/$DEFAULT_REPO"
REPO="$DEFAULT_REPO"
REPO_URL="$DEFAULT_REPO_URL"
ARCHIVE_URL=""
REF="main"
SOURCE_DIR=""
PROJECT_DIR=""
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
REPO_SET=0
REPO_URL_SET=0
INSTALL_CODEX=0
INSTALL_CLAUDE=0
INSTALL_CURSOR=0
INSTALL_CODEWIZ=0
INSTALL_COPILOT=0
TMP_DIR=""

usage() {
  cat <<'EOF'
Install Predy Setup Assistant without cloning the repository first.

Usage:
  ./install.sh
  ./install.sh --codex
  ./install.sh --repo-url <repo-web-url> --codex
  ./install.sh --archive-url <repo-archive-url> --cursor --project /path/to/repo

Options:
  --repo <namespace/name> Repository path, default: yuufen/predy-setup-assistant
  --repo-url <url>        Repository web URL, default: https://github.com/yuufen/predy-setup-assistant
  --archive-url <url>     Repository archive URL for this ref, overrides auto-detection
  --ref <git-ref>         Git ref to download, default: main
  --source-dir <path>     Local skill directory, mainly for testing or local use
  --codex                 Install for Codex
  --claude                Install for Claude
  --cursor                Install for Cursor
  --codewiz               Install for CodeWiz
  --project <path>        Target project path for project-based installs
  --codex-home <path>     Override CODEX_HOME
  --claude-home <path>    Override Claude home
  --help                  Show this help

Notes:
  - If no target is passed in an interactive terminal, this script asks which client to install for.
  - If no target is passed in a non-interactive shell, this script defaults to --codex.
  - If you are not running from a checked-out repo, this script downloads from the default repo URL above.
EOF
}

cleanup() {
  if [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ]; then
    rm -rf "$TMP_DIR"
  fi
}

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

read_line() {
  prompt="$1"
  printf '%s' "$prompt" >&2
  IFS= read -r line || line=""
  printf '%s' "$line"
}

normalize_dir() {
  raw_path="$1"
  case "$raw_path" in
    "~")
      raw_path="$HOME"
      ;;
    "~/"*)
      raw_path="$HOME/${raw_path#~/}"
      ;;
  esac

  if [ ! -d "$raw_path" ]; then
    return 1
  fi

  (
    cd "$raw_path"
    pwd
  )
}

prompt_project_dir() {
  default_dir="$PWD"

  while :; do
    answer="$(read_line "Project path [$default_dir]: ")"
    if [ -z "$answer" ]; then
      answer="$default_dir"
    fi

    normalized_dir="$(normalize_dir "$answer" 2>/dev/null || true)"
    if [ -n "$normalized_dir" ]; then
      PROJECT_DIR="$normalized_dir"
      return 0
    fi

    printf '%s\n' "Directory does not exist: $answer" >&2
  done
}

select_target_interactively() {
  printf '%s\n' 'Select the target assistant:' >&2
  printf '%s\n' '  1) Codex' >&2
  printf '%s\n' '  2) Claude' >&2
  printf '%s\n' '  3) Cursor' >&2
  printf '%s\n' '  4) CodeWiz' >&2

  while :; do
    choice="$(read_line 'Enter number [1]: ')"
    case "$choice" in
      ""|1)
        INSTALL_CODEX=1
        return 0
        ;;
      2)
        INSTALL_CLAUDE=1
        return 0
        ;;
      3)
        INSTALL_CURSOR=1
        prompt_project_dir
        return 0
        ;;
      4)
        INSTALL_CODEWIZ=1
        prompt_project_dir
        return 0
        ;;
      *)
        printf '%s\n' "Invalid choice: $choice" >&2
        ;;
    esac
  done
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "Missing required command: $1"
  fi
}

activate_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi

  for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$brew_bin" ]; then
      PATH="$(dirname "$brew_bin"):$PATH"
      export PATH
      return 0
    fi
  done

  return 1
}

maybe_install_homebrew() {
  os_name="$(uname -s 2>/dev/null || printf '%s' unknown)"
  if [ "$os_name" != "Darwin" ]; then
    return 0
  fi

  if activate_homebrew; then
    return 0
  fi

  need_cmd curl

  printf '%s\n' 'Homebrew is missing on macOS. Trying the official Homebrew installer first. macOS may ask for an administrator password.'

  if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    if activate_homebrew; then
      printf '%s\n' 'Homebrew is now available.'
    else
      printf '%s\n' 'Homebrew may have installed successfully, but this shell cannot see it yet. Open a new terminal if later install steps still say brew is missing.' >&2
    fi
  else
    printf '%s\n' 'Homebrew installation did not complete. Continuing to install the setup assistant; later Predy install steps may still stop here until Homebrew is installed.' >&2
  fi
}

is_valid_zip() {
  unzip -tqq "$1" >/dev/null 2>&1
}

resolve_self_source_dir() {
  case "$0" in
    -* | sh | bash | zsh)
      return 1
      ;;
  esac

  SELF_PATH="$0"
  case "$SELF_PATH" in
    /*) ;;
    *) SELF_PATH="$PWD/$SELF_PATH" ;;
  esac

  if [ ! -f "$SELF_PATH" ]; then
    return 1
  fi

  SELF_DIR="$(CDPATH= cd -- "$(dirname "$SELF_PATH")" && pwd)"
  if [ -f "$SELF_DIR/SKILL.md" ] && [ -f "$SELF_DIR/scripts/install_targets.sh" ]; then
    printf '%s\n' "$SELF_DIR"
    return 0
  fi

  return 1
}

download_source_dir() {
  need_cmd curl
  need_cmd unzip

  TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/predy-setup-assistant.XXXXXX")"
  trap cleanup EXIT INT TERM HUP

  ZIP_PATH="$TMP_DIR/repo.zip"
  EXTRACT_DIR="$TMP_DIR/unpack"
  mkdir -p "$EXTRACT_DIR"

  if [ -n "$ARCHIVE_URL" ]; then
    curl -L --fail "$ARCHIVE_URL" -o "$ZIP_PATH"
    if ! is_valid_zip "$ZIP_PATH"; then
      fail "Archive URL did not return a valid zip file: $ARCHIVE_URL"
    fi
  else
    REPO_URL_CLEAN="${REPO_URL%/}"
    case "$REPO_URL_CLEAN" in
      https://github.com/*)
        DOWNLOAD_URL="$REPO_URL_CLEAN/archive/refs/heads/$REF.zip"
        ;;
      *)
        REPO_NAME="${REPO_URL_CLEAN##*/}"
        DOWNLOAD_URL="$REPO_URL_CLEAN/-/archive/$REF/$REPO_NAME-$REF.zip"
        ;;
    esac

    curl -L --fail "$DOWNLOAD_URL" -o "$ZIP_PATH"
    if ! is_valid_zip "$ZIP_PATH"; then
      fail "Repo archive URL did not return a valid zip file: $DOWNLOAD_URL"
    fi
  fi

  unzip -q "$ZIP_PATH" -d "$EXTRACT_DIR"

  for entry in "$EXTRACT_DIR"/*; do
    if [ -d "$entry" ]; then
      if [ -f "$entry/SKILL.md" ] && [ -f "$entry/scripts/install_targets.sh" ]; then
        SOURCE_DIR="$entry"
        return 0
      fi
    fi
  done

  fail "Downloaded repository does not look like a $SKILL_NAME repo."
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      REPO="${2:?missing value for --repo}"
      REPO_SET=1
      shift 2
      ;;
    --repo-url)
      REPO_URL="${2:?missing value for --repo-url}"
      REPO_URL_SET=1
      shift 2
      ;;
    --archive-url)
      ARCHIVE_URL="${2:?missing value for --archive-url}"
      shift 2
      ;;
    --ref)
      REF="${2:?missing value for --ref}"
      shift 2
      ;;
    --source-dir)
      SOURCE_DIR="${2:?missing value for --source-dir}"
      shift 2
      ;;
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
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail "Unknown argument: $1"
      ;;
  esac
done

if [ "$INSTALL_CODEX" -eq 0 ] && [ "$INSTALL_CLAUDE" -eq 0 ] && [ "$INSTALL_CURSOR" -eq 0 ] && [ "$INSTALL_CODEWIZ" -eq 0 ] && [ "$INSTALL_COPILOT" -eq 0 ]; then
  if [ -t 0 ] && [ -t 1 ]; then
    select_target_interactively
  else
    INSTALL_CODEX=1
  fi
fi

if [ "$REPO_SET" -eq 1 ] && [ "$REPO_URL_SET" -eq 0 ]; then
  REPO_URL="$DEFAULT_REPO_HOST/$REPO"
fi

maybe_install_homebrew

if [ -n "$SOURCE_DIR" ]; then
  :
elif SOURCE_DIR_RESOLVED="$(resolve_self_source_dir 2>/dev/null)"; then
  SOURCE_DIR="$SOURCE_DIR_RESOLVED"
else
  download_source_dir
fi

if [ ! -f "$SOURCE_DIR/SKILL.md" ] || [ ! -f "$SOURCE_DIR/scripts/install_targets.sh" ]; then
  fail "Invalid --source-dir: $SOURCE_DIR"
fi

set --

if [ "$INSTALL_CODEX" -eq 1 ]; then
  set -- "$@" --codex
fi
if [ "$INSTALL_CLAUDE" -eq 1 ]; then
  set -- "$@" --claude
fi
if [ "$INSTALL_CURSOR" -eq 1 ]; then
  set -- "$@" --cursor
fi
if [ "$INSTALL_CODEWIZ" -eq 1 ]; then
  set -- "$@" --codewiz
fi
if [ "$INSTALL_COPILOT" -eq 1 ]; then
  set -- "$@" --copilot
fi
if [ -n "$PROJECT_DIR" ]; then
  set -- "$@" --project "$PROJECT_DIR"
fi
if [ -n "$CODEX_HOME" ]; then
  set -- "$@" --codex-home "$CODEX_HOME"
fi
if [ -n "$CLAUDE_HOME" ]; then
  set -- "$@" --claude-home "$CLAUDE_HOME"
fi

printf '%s\n' "Installing $SKILL_NAME from $SOURCE_DIR"

# Reuse the repo-local installer so each client stays on the same copy logic.
(
  cd "$SOURCE_DIR"
  ./scripts/install_targets.sh "$@"
)

printf '\n'
printf '%s\n' "Installed $SKILL_NAME."
printf '%s\n' "Restart the target assistant to pick up the new skill."

if [ "$INSTALL_CODEX" -eq 1 ]; then
  printf '%s\n' 'In Codex, run: $predy-setup-assistant 帮我一步步安装 Predy'
fi
if [ "$INSTALL_CLAUDE" -eq 1 ]; then
  printf '%s\n' 'In Claude, run: 请使用 predy-setup-assistant 帮我一步步安装 Predy'
fi
if [ "$INSTALL_CURSOR" -eq 1 ] || [ "$INSTALL_CODEWIZ" -eq 1 ]; then
  printf '%s\n' 'In the chat box, run: 帮我一步步安装 Predy'
fi
