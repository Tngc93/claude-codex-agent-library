#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_DIR="$ROOT_DIR/agency-agents"
QUARANTINE_FILE="$ROOT_DIR/config/quarantine.txt"
CATALOG="$ROOT_DIR/.claude/skills/workspace-router/references/agent-catalog.tsv"

frontmatter_field() {
  local field="$1" file="$2"
  awk -v field="$field" '
    NR == 1 && $0 != "---" { exit 1 }
    NR > 1 && /^---$/ { exit }
    NR > 1 && index($0, field ":") == 1 {
      sub("^" field ":[[:space:]]*", "")
      print
      exit
    }
  ' "$file"
}

slugify() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//'
}

is_quarantined() {
  local rel="$1"
  awk 'NF && $1 !~ /^#/ { print $1 }' "$QUARANTINE_FILE" | grep -Fxq "$rel"
}

[[ -d "$SOURCE_DIR" ]] || { printf 'Upstream repository not found: %s\n' "$SOURCE_DIR" >&2; exit 1; }
[[ -f "$QUARANTINE_FILE" ]] || { printf 'Quarantine list not found.\n' >&2; exit 1; }

mkdir -p "$(dirname "$CATALOG")"
temp="$(mktemp "${TMPDIR:-/tmp}/agent-catalog.XXXXXX")"
printf 'slug\tcategory\tsource_path\tdescription\n' > "$temp"

count=0
while IFS= read -r source; do
  [[ "$(head -n 1 "$source")" == "---" ]] || continue
  rel="${source#$SOURCE_DIR/}"
  is_quarantined "$rel" && continue

  name="$(frontmatter_field name "$source")"
  description="$(frontmatter_field description "$source" | tr '\t\r\n' '   ' | sed 's/[[:space:]]*$//')"
  slug="$(slugify "$name")"
  category="${rel%%/*}"
  printf '%s\t%s\t%s\t%s\n' "$slug" "$category" "$rel" "$description" >> "$temp"
  count=$((count + 1))
done < <(find -H "$SOURCE_DIR" -mindepth 2 -type f -name '*.md' \
  ! -path '*/integrations/*' ! -path '*/examples/*' ! -path '*/strategy/*' | sort)

duplicates="$(tail -n +2 "$temp" | cut -f1 | sort | uniq -d)"
if [[ -n "$duplicates" ]]; then
  printf 'Duplicate agent slugs found:\n%s\n' "$duplicates" >&2
  exit 1
fi

mv "$temp" "$CATALOG"
chmod 0644 "$CATALOG"
printf 'Agent catalog generated: %s entries\n' "$count"
