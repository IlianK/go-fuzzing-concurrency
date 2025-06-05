#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <Subfolder>"
  echo "Example: $0 Lifecycle"
  exit 1
fi

EXAMPLES_DIR=~/Projects/Go_Fuzzing_Concurrency/Examples
SUBFOLDER=$1
TARGET_DIR="$EXAMPLES_DIR/$SUBFOLDER/results"

TEST_FUNCS=($(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort))
if [ ${#TEST_FUNCS[@]} -eq 0 ]; then
  echo "No test functions found in $TARGET_DIR"
  exit 1
fi

echo "Available Test Functions:"
for i in "${!TEST_FUNCS[@]}"; do
  echo "$((i + 1)). ${TEST_FUNCS[$i]}"
done

read -p "Select the test function: " SELECTION
if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt "${#TEST_FUNCS[@]}" ]; then
  echo "Invalid selection."
  exit 1
fi

FUNC_NAME="${TEST_FUNCS[$((SELECTION - 1))]}"
FUNC_PATH="$TARGET_DIR/$FUNC_NAME"
OUTFILE="$FUNC_PATH/comparison_summary.log"

declare -A BUG_MAP
declare -A DESC_MAP
declare -A MODE_BUG_COUNT
declare -A TYPE_MAP

echo "=== Bug Comparison Summary for $FUNC_NAME ==="
echo "=== Bug Comparison Summary for $FUNC_NAME ===" > "$OUTFILE"

for MODE_DIR in "$FUNC_PATH"/*; do
  MODE=$(basename "$MODE_DIR")
  BUG_DIR="$MODE_DIR/bugs"
  COUNT=0

  if [ -d "$BUG_DIR" ]; then
    for MD_FILE in "$BUG_DIR"/*.md; do
      if [ -f "$MD_FILE" ]; then
        BUG_ID=$(awk '/-> .*\.go:[0-9]+/ { print $2 }' "$MD_FILE" | head -n1)
        BUG_TYPE=$(grep -E '^# ' "$MD_FILE" | head -n1 | cut -d':' -f1 | sed 's/# //')
        if [ -n "$BUG_ID" ]; then
          BUG_MAP["$BUG_ID"]+="$MODE,"
          TYPE_MAP["$BUG_ID"]="$BUG_TYPE"
          ((COUNT++))
        fi
      fi
    done
  fi

  MODE_BUG_COUNT["$MODE"]=$COUNT
done

echo ""
echo "Bug Counts per Mode:"
for MODE in "${!MODE_BUG_COUNT[@]}"; do
  echo "$MODE → ${MODE_BUG_COUNT[$MODE]}"
done

echo "" >> "$OUTFILE"
echo "=== Bugs by Category ===" >> "$OUTFILE"

# Group and print bugs by type
for BUG_TYPE in $(printf "%s\n" "${TYPE_MAP[@]}" | sort -u); do
  echo "" >> "$OUTFILE"
  echo "== $BUG_TYPE ==" >> "$OUTFILE"
  for ID in "${!BUG_MAP[@]}"; do
    if [[ "${TYPE_MAP[$ID]}" == "$BUG_TYPE" ]]; then
      MODES=$(echo "${BUG_MAP[$ID]}" | tr ',' '\n' | sort -u | paste -sd, -)
      UNIQUE=""
      [[ $(echo "$MODES" | tr ',' '\n' | wc -l) -eq 1 ]] && UNIQUE=" [UNIQUE]"
      echo "$ID → $MODES$UNIQUE" >> "$OUTFILE"
    fi
  done
done

echo ""
echo "Summary written to: $OUTFILE"
