#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_DIR="$ROOT_DIR/agency-agents"
DIVISIONS_FILE="$SOURCE_DIR/divisions.json"
CATALOG="$ROOT_DIR/.claude/skills/workspace-router/references/agent-catalog.tsv"
MAP_ROOT="$ROOT_DIR/Agent Kütüphanesi"
ROOT_MAP="$ROOT_DIR/Ana Sayfa.md"

frontmatter_field() {
  local field="$1" file="$2"
  awk -v field="$field" '
    NR == 1 && $0 != "---" { exit 1 }
    NR > 1 && /^---$/ { exit }
    NR > 1 && index($0, field ":") == 1 {
      sub("^" field ":[[:space:]]*", "")
      gsub(/^"|"$/, "")
      print
      exit
    }
  ' "$file"
}

[[ -f "$DIVISIONS_FILE" ]] || { printf 'Kategori tanımları bulunamadı: %s\n' "$DIVISIONS_FILE" >&2; exit 1; }
[[ -f "$CATALOG" ]] || { printf 'Agent kataloğu bulunamadı: %s\n' "$CATALOG" >&2; exit 1; }

mkdir -p "$MAP_ROOT/Kategoriler"

{
  printf '%s\n' '---'
  printf '%s\n' 'tags:' '  - agent-map' '  - agent-map/root'
  printf '%s\n' '---' '' '# AI Agent Kütüphanesi' ''
  printf '%s\n' '> Obsidian gezinme merkezi. Claude Code seçimi bu görünümden bağımsız olarak küçük katalog üzerinden otomatik yapar.' ''
  printf '%s\n' '## Kategoriler' ''
} > "$ROOT_MAP"

total=0
while IFS=$'\t' read -r category label color; do
  category_dir="$MAP_ROOT/Kategoriler/$category"
  category_map="$category_dir/$label.md"
  mkdir -p "$category_dir"

  count="$(awk -F '\t' -v category="$category" 'NR > 1 && $2 == category { count++ } END { print count + 0 }' "$CATALOG")"
  total=$((total + count))
  printf -- '- [[Agent Kütüphanesi/Kategoriler/%s/%s|%s]] — %s agent\n' "$category" "$label" "$label" "$count" >> "$ROOT_MAP"

  {
    printf '%s\n' '---'
    printf '%s\n' 'tags:' '  - agent-map' "  - agent-category/$category"
    printf 'category: %s\n' "$category"
    printf 'graph-color: "%s"\n' "$color"
    printf '%s\n' '---' '' "# $label" ''
    printf '[[Ana Sayfa|← Ana Sayfa]]\n\n'
    printf '**%s agent** · Renk: `%s`\n\n' "$count" "$color"
    printf '%s\n' '## Agent’lar' ''
  } > "$category_map"

  while IFS=$'\t' read -r agent_slug agent_category source_path description; do
    [[ "$agent_category" == "$category" ]] || continue
    name="$(frontmatter_field name "$SOURCE_DIR/$source_path")"
    target="agency-agents/${source_path%.md}"
    printf -- '- [[%s|%s]]\n' "$target" "$name" >> "$category_map"
  done < <(tail -n +2 "$CATALOG")
done < <(
  sed -nE 's/^ *"([^"]+)": \{ "label": "([^"]+)",.*"color": "(#[0-9A-F]+)".*/\1\t\2\t\3/p' "$DIVISIONS_FILE"
)

{
  printf '%s\n' '' '---' ''
  printf '**Toplam:** %s katalog agent’ı (karantinadaki profiller hariç).\n' "$total"
  printf '%s\n' '' 'Kaynak: `agency-agents/divisions.json` ve router agent kataloğu.'
} >> "$ROOT_MAP"

printf 'Obsidian agent haritası oluşturuldu: %s kategori, %s agent\n' \
  "$(find "$MAP_ROOT/Kategoriler" -type f -name '*.md' | wc -l | tr -d ' ')" "$total"
