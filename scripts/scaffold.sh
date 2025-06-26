#!/bin/bash

# === CONFIG ===
STAGING_DIR="Recipes/!staging"
BASE_DIR="Recipes"
INDEX_FILE="$BASE_DIR/Recipes_Index.md"

# === MAPPING RULES ===
declare -A KEYWORD_MAP=(
  ["bread"]="Breads_and_Baking"
  ["loaf"]="Breads_and_Baking"
  ["cookie"]="Breads_and_Baking"
  ["pizza"]="Breads_and_Baking"
  ["pasta"]="Pasta_and_Noodles"
  ["ramen"]="Pasta_and_Noodles"
  ["noodle"]="Pasta_and_Noodles"
  ["sauce"]="Sauces_and_Condiments"
  ["pickle"]="Sauces_and_Condiments"
  ["curry"]="Meal_Systems"
  ["stir"]="Meal_Systems"
  ["wrap"]="Meal_Systems"
  ["taco"]="Tacos"
  ["sweet"]="Sweets_and_Desserts"
  ["pudding"]="Sweets_and_Desserts"
  ["family"]="Heritage_and_Family"
)

# === STEP 1: TRIAGE FILES ===
echo "🔍 Step 1: Triaging files from $STAGING_DIR..."

for file in "$STAGING_DIR"/*.md; do
  [[ -e "$file" ]] || continue
  filename=$(basename "$file")
  lower=$(echo "$filename" | tr '[:upper:]' '[:lower:]')
  suggested="!unmatched"

  for keyword in "${!KEYWORD_MAP[@]}"; do
    if [[ "$lower" == *"$keyword"* ]]; then
      suggested="${KEYWORD_MAP[$keyword]}"
      break
    fi
  done

  echo ""
  echo "📝 $filename"
  echo "→ Suggested folder: $BASE_DIR/$suggested"

  read -p "   Move this file? (y/n): " confirm
  if [[ "$confirm" == "y" ]]; then
    mkdir -p "$BASE_DIR/$suggested"
    mv "$file" "$BASE_DIR/$suggested/"
    echo "✅ Moved to $BASE_DIR/$suggested/"
  else
    echo "⏭️  Skipped"
  fi
done

# === STEP 2: YAML INJECTION ===
echo ""
echo "🧬 Step 2: Injecting YAML frontmatter..."

find "$BASE_DIR" -type f -name "*.md" | while read -r file; do
  if grep -q "^---" "$file"; then
    echo "✅ YAML exists: $(basename "$file")"
  else
    echo "✍️ Adding YAML: $(basename "$file")"
    tmpfile=$(mktemp)
    cat <<EOL > "$tmpfile"
---
title: $(basename "$file" .md)
category: 
tags: []
tested: false
difficulty: 
---

EOL
    cat "$file" >> "$tmpfile"
    mv "$tmpfile" "$file"
  fi
done

# === STEP 3: INDEX GENERATION ===
echo ""
echo "🗂️ Step 3: Generating $INDEX_FILE..."

echo "# 📚 Recipes Index" > "$INDEX_FILE"
echo "" >> "$INDEX_FILE"

find "$BASE_DIR" -mindepth 2 -type f -name "*.md" | sort | while read -r file; do
  rel_path="${file#$BASE_DIR/}"
  display_name=$(basename "$rel_path" .md)
  echo "- [[${rel_path%.md}]]" >> "$INDEX_FILE"
done

echo "✅ Done! All steps complete."
