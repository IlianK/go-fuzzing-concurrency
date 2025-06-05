#!/bin/bash

# === Config ===
ADVOCATE_BIN=~/Projects/Go_Fuzzing_Concurrency/ADVOCATE/advocate/advocate
PROJECTS_DIR=~/Projects/Go_Fuzzing_Concurrency/Examples/Examples_Projects
RESULTS_BASE=~/Projects/Go_Fuzzing_Concurrency/Examples/Examples_Projects/results

VALID_MODES=("GFuzz" "GFuzzHB" "Flow" "GFuzzHBFlow" "GoPie" "GoPie+" "GoPieHB")

# === Input Validation ===
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <ProjectFolder> <FuzzingMode>"
  echo "Example: $0 caddy-master GoPie"
  exit 1
fi

PROJECT=$1
MODE=$2
TARGET_DIR="$PROJECTS_DIR/$PROJECT"

if [ ! -d "$TARGET_DIR" ]; then
  echo "Project folder $TARGET_DIR not found."
  exit 1
fi

if [[ ! " ${VALID_MODES[*]} " =~ " ${MODE} " ]]; then
  echo "Invalid fuzzing mode: $MODE"
  echo "Valid modes: ${VALID_MODES[*]}"
  exit 1
fi

# === Detect Test Functions ===
TEST_FUNCS=($(grep -rhoP 'func\s+(Test\w+)\s*\(' "$TARGET_DIR"/*.go 2>/dev/null | sed -E 's/func\s+(Test\w+)\s*\(.*/\1/' | sort -u))

if [ "${#TEST_FUNCS[@]}" -eq 0 ]; then
  echo "No test functions found in $TARGET_DIR"
  exit 1
fi

echo "Detected Test Functions in $PROJECT:"
for i in "${!TEST_FUNCS[@]}"; do
  echo "$((i + 1)). ${TEST_FUNCS[$i]}"
done

read -p "Select test function to fuzz (number): " SELECTION

if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt "${#TEST_FUNCS[@]}" ]; then
  echo "Invalid selection."
  exit 1
fi

SELECTED_FUNC="${TEST_FUNCS[$((SELECTION - 1))]}"
PROG_NAME=$(basename "$(find "$TARGET_DIR" -maxdepth 1 -name '*_test.go' | head -n1)" .go)

echo "▶ Running $MODE fuzzing for $PROJECT, Test: $SELECTED_FUNC"

"$ADVOCATE_BIN" fuzzing \
  -path "$TARGET_DIR" \
  -exec "$SELECTED_FUNC" \
  -fuzzingMode "$MODE" \
  -prog "$PROG_NAME"

RESULT_DIR="$RESULTS_BASE/$PROJECT/$SELECTED_FUNC/$MODE"
mkdir -p "$RESULT_DIR"

if [ -d "$TARGET_DIR/advocateResult" ]; then
  INNER_DIR=$(find "$TARGET_DIR/advocateResult" -maxdepth 1 -type d -name 'file*' | head -n1)
  if [ -n "$INNER_DIR" ]; then
    mv "$INNER_DIR"/* "$RESULT_DIR"/
  fi
  rm -rf "$TARGET_DIR/advocateResult"
  echo "Saved results to $RESULT_DIR"
fi

if [ -d "$TARGET_DIR/fuzzingTraces" ]; then
  mv "$TARGET_DIR/fuzzingTraces" "$RESULT_DIR/"
  echo "Moved fuzzingTraces to $RESULT_DIR"
fi

echo "Done: $MODE on $PROJECT - $SELECTED_FUNC"
