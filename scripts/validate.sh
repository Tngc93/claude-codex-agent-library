#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_DIR="$ROOT_DIR/agency-agents"
CATALOG="$ROOT_DIR/.claude/skills/workspace-router/references/agent-catalog.tsv"
QUARANTINE="$ROOT_DIR/config/quarantine.txt"
LOCK_FILE="$ROOT_DIR/config/upstream.lock"
MAP_ROOT="$ROOT_DIR/Agent Kütüphanesi"

fail() {
  printf 'Validation failed: %s\n' "$1" >&2
  exit 1
}

required_files=(
  "$ROOT_DIR/AGENTS.md"
  "$ROOT_DIR/CLAUDE.md"
  "$ROOT_DIR/README.md"
  "$ROOT_DIR/LICENSE"
  "$ROOT_DIR/THIRD_PARTY_NOTICES.md"
  "$ROOT_DIR/docs/images/obsidian-agent-graph.jpeg"
  "$ROOT_DIR/.claude/skills/workspace-router/SKILL.md"
  "$ROOT_DIR/.claude/skills/workspace-router/agents/openai.yaml"
  "$SOURCE_DIR/divisions.json"
  "$CATALOG"
  "$QUARANTINE"
  "$LOCK_FILE"
  "$ROOT_DIR/Ana Sayfa.md"
)

for required in "${required_files[@]}"; do
  [[ -f "$required" ]] || fail "missing required file: ${required#$ROOT_DIR/}"
done

for script in "$SCRIPT_DIR"/*.sh; do
  bash -n "$script" || fail "invalid shell syntax: ${script#$ROOT_DIR/}"
done

expected_revision="$(tr -d '[:space:]' < "$LOCK_FILE")"
[[ "$expected_revision" =~ ^[0-9a-f]{40}$ ]] || fail 'config/upstream.lock must contain one full commit SHA'

if command -v git >/dev/null 2>&1; then
  actual_revision="$(git -C "$SOURCE_DIR" rev-parse HEAD 2>/dev/null)" || \
    fail 'agency-agents is not an initialized Git submodule'
  [[ "$actual_revision" == "$expected_revision" ]] || \
    fail "upstream revision mismatch: expected $expected_revision, found $actual_revision"
fi

references="$ROOT_DIR/.claude/skills/workspace-router/references"
for link_name in agency-agents quarantine.txt; do
  link_path="$references/$link_name"
  [[ -L "$link_path" ]] || fail "expected a symbolic link: ${link_path#$ROOT_DIR/}"
  [[ -e "$link_path" ]] || fail "broken symbolic link: ${link_path#$ROOT_DIR/}"
  [[ "$(readlink "$link_path")" != /* ]] || fail "symbolic link must be relative: ${link_path#$ROOT_DIR/}"
done

codex_skill="$ROOT_DIR/.agents/skills/workspace-router"
[[ -L "$codex_skill" ]] || fail 'expected Codex router to be a symbolic link'
[[ -e "$codex_skill/SKILL.md" ]] || fail 'Codex router symbolic link is broken'
[[ "$(readlink "$codex_skill")" == '../../.claude/skills/workspace-router' ]] || \
  fail 'Codex router must point to the canonical Claude router'
grep -F -q 'allow_implicit_invocation: true' \
  "$codex_skill/agents/openai.yaml" || fail 'Codex implicit invocation must be enabled'

expected_header=$'slug\tcategory\tsource_path\tdescription'
[[ "$(head -n 1 "$CATALOG")" == "$expected_header" ]] || fail 'unexpected agent catalog header'

catalog_count="$(($(wc -l < "$CATALOG") - 1))"
(( catalog_count > 0 )) || fail 'agent catalog is empty'

while IFS=$'\t' read -r _slug _category source_path _description; do
  [[ -f "$SOURCE_DIR/$source_path" ]] || fail "catalog source does not exist: $source_path"
  [[ "$(head -n 1 "$SOURCE_DIR/$source_path")" == '---' ]] || \
    fail "catalog source has no frontmatter: $source_path"
done < <(tail -n +2 "$CATALOG")

while IFS= read -r quarantined_path; do
  [[ -n "$quarantined_path" && "$quarantined_path" != \#* ]] || continue

  if awk -F '\t' -v path="$quarantined_path" 'NR > 1 && $3 == path { found = 1 } END { exit !found }' "$CATALOG"; then
    fail "quarantined profile appears in catalog: $quarantined_path"
  fi

  quarantined_stem="${quarantined_path%.md}"
  if grep -R -F -q "$quarantined_stem" "$MAP_ROOT" "$ROOT_DIR/Ana Sayfa.md"; then
    fail "quarantined profile appears in Obsidian map: $quarantined_path"
  fi
done < "$QUARANTINE"

map_count="$(find "$MAP_ROOT/Kategoriler" -type f -name '*.md' | wc -l | tr -d ' ')"
(( map_count > 0 )) || fail 'Obsidian category map is empty'
grep -F -q "**Toplam:** $catalog_count katalog agent’ı" "$ROOT_DIR/Ana Sayfa.md" || \
  fail 'Obsidian map total does not match the agent catalog'

if command -v python3 >/dev/null 2>&1; then
  python3 - "$ROOT_DIR" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
files = [
    root / ".obsidian/app.json",
    root / ".obsidian/appearance.json",
    root / ".obsidian/core-plugins.json",
    root / ".obsidian/graph.json",
    root / "agency-agents/divisions.json",
    root / "config/obsidian-app.clean.json",
    root / "config/obsidian-appearance.clean.json",
    root / "config/obsidian-graph.before-category-map.json",
    root / "config/obsidian-graph.category-map.json",
]

for path in files:
    with path.open(encoding="utf-8") as handle:
        json.load(handle)
PY
else
  printf 'Warning: python3 not found; JSON syntax checks were skipped.\n' >&2
fi

if grep -R --exclude='validate.sh' -n -E '/Users/[^/]+|[A-Za-z]:\\\\Users\\\\' \
  "$ROOT_DIR/.agents" "$ROOT_DIR/.claude" "$ROOT_DIR/config" "$ROOT_DIR/scripts" \
  "$ROOT_DIR/AGENTS.md" "$ROOT_DIR/CLAUDE.md" "$ROOT_DIR/README.md" \
  "$ROOT_DIR/README.tr.md" >/dev/null; then
  fail 'personal absolute path found in a public repository file'
fi

printf 'Validation passed: %s catalog profiles, %s category maps, upstream %s.\n' \
  "$catalog_count" "$map_count" "$expected_revision"
