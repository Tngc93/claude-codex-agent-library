#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_DIR="$ROOT_DIR/agency-agents"

if [[ ! -f "$SOURCE_DIR/divisions.json" ]]; then
  if ! command -v git >/dev/null 2>&1; then
    printf 'Git is required to initialize the agency-agents submodule.\n' >&2
    exit 1
  fi

  printf 'Initializing the pinned agency-agents submodule...\n'
  git -C "$ROOT_DIR" submodule update --init --recursive
fi

"$SCRIPT_DIR/build-agent-catalog.sh"
"$SCRIPT_DIR/build-obsidian-agent-map.sh"
"$SCRIPT_DIR/validate.sh"

printf '\nSetup complete. Add this folder as an additional workspace in Claude Code App or Codex.\n'
