#!/bin/bash

# === Config ===
ADVOCATE_BIN=~/Projects/Go_Fuzzing_Concurrency/ADVOCATE/advocate/advocate
FUZZ_MODES=("GFuzz" "GFuzzHB" "Flow" "GFuzzHBFlow" "GoPie" "GoPie+" "GoPieHB")

# === Input Validation ===
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <BaseFolder> <Subfolder>"
  echo "Example: $0 Examples/Examples_Own Lifecycle"
  exit 1
fi

BASE_FOLDER=$1
SUBFOLDER=$2
TARGET_DIR=~/Projects/Go_Fuzzing_Concurrency/$BASE_FOLDER/$SUBFOLDER

if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: Target directory $TARGET_DIR does not exist."
  exit 1
fi

# === Detect Test Functions ===
TEST_FUNCS=($(grep -hoP 'func\s+(Test\w+)\s*\(' "$TARGET_DIR"/*.go | sed -E 's/func\s+(Test\w+)\s*\(.*/\1/' | sort -u))

if [ "${#TEST_FUNCS[@]}" -eq 0 ]; then
  echo "--- No test functions found in $TARGET_DIR"
  exit 1
fi

echo "Available Test Functions in $TARGET_DIR:"
for i in "${!TEST_FUNCS[@]}"; do
  echo "$((i + 1)). ${TEST_FUNCS[$i]}"
done

read -p "Enter the number of the test function to fuzz: " SELECTION

# Validate user input
if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt "${#TEST_FUNCS[@]}" ]; then
  echo "Invalid selection."
  exit 1
fi

SELECTED_TEST_FUNC="${TEST_FUNCS[$((SELECTION - 1))]}"
PROG_NAME=$(basename "$(find "$TARGET_DIR" -maxdepth 1 -name '*_test.go' | head -n1)" .go)

echo "▶ Running all fuzzing modes on $SELECTED_TEST_FUNC in $BASE_FOLDER/$SUBFOLDER"

# === Loop through fuzzing modes ===
for MODE in "${FUZZ_MODES[@]}"; do
  echo "--- Mode: $MODE"

  "$ADVOCATE_BIN" fuzzing \
    -path "$TARGET_DIR" \
    -exec "$SELECTED_TEST_FUNC" \
    -fuzzingMode "$MODE" \
    -prog "$PROG_NAME"

  RESULT_DIR="$TARGET_DIR/results/$SELECTED_TEST_FUNC/$MODE"
  mkdir -p "$RESULT_DIR"

  if [ -d "$TARGET_DIR/advocateResult" ]; then
    INNER_DIR=$(find "$TARGET_DIR/advocateResult" -maxdepth 1 -type d -name 'file*' | head -n1)
    if [ -n "$INNER_DIR" ]; then
      mv "$INNER_DIR"/* "$RESULT_DIR"/
    fi
    rm -rf "$TARGET_DIR/advocateResult"
    echo "Saved advocateResult to $RESULT_DIR"
  else
    echo "No advocateResult folder found."
  fi

  if [ -d "$TARGET_DIR/fuzzingTraces" ]; then
    mv "$TARGET_DIR/fuzzingTraces" "$RESULT_DIR/"
    echo "Moved fuzzingTraces to $RESULT_DIR/fuzzingTraces"
  fi
done

echo "Completed all fuzzing modes for $SELECTED_TEST_FUNC in $BASE_FOLDER/$SUBFOLDER"
