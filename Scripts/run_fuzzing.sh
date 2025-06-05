#!/bin/bash

# === Config ===
ADVOCATE_BIN=~/Projects/Go_Fuzzing_Concurrency/ADVOCATE/advocate/advocate
EXAMPLES_DIR=~/Projects/Go_Fuzzing_Concurrency/Examples/Examples_Own
#EXAMPLES_DIR=~/Projects/Go_Fuzzing_Concurrency/ADVOCATE/examples


# === Input Validation ===
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <Subfolder> <FuzzingMode>"
  echo "Example: $0 Mutex GoPie"
  exit 1
fi

SUBFOLDER=$1
MODE=$2
TARGET_DIR="$EXAMPLES_DIR/$SUBFOLDER"


# === Detect Test Functions ===
TEST_FUNCS=($(grep -hoP 'func\s+(Test\w+)\s*\(' "$TARGET_DIR"/*.go | sed -E 's/func\s+(Test\w+)\s*\(.*/\1/' | sort -u))

if [ -z "$TEST_FUNCS" ]; then
  echo "--- No test functions found in $TARGET_DIR"
  exit 1
fi


# === List all Test Functions and Let User Select ===
echo "Available Test Functions:"
for i in "${!TEST_FUNCS[@]}"; do
  echo "$((i + 1)). ${TEST_FUNCS[$i]}"
done

read -p "Enter the number of the test function you want to fuzz: " SELECTION


# Validate user input
if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt "${#TEST_FUNCS[@]}" ]; then
  echo "Invalid selection. Please enter a valid number."
  exit 1
fi


# Get the selected test function
SELECTED_TEST_FUNC="${TEST_FUNCS[$((SELECTION - 1))]}"

echo "Running $MODE on $SELECTED_TEST_FUNC in $SUBFOLDER"


# === Run Fuzzing for Selected Test Function ===
# Fuzzing Command (do not create directories yet)
# Detect first matching *_test.go file (assuming 1 test file per subfolder)
PROG_NAME=$(basename "$(find "$TARGET_DIR" -maxdepth 1 -name '*_test.go' | head -n1)" .go)

"$ADVOCATE_BIN" fuzzing \
  -path "$TARGET_DIR" \
  -exec "$SELECTED_TEST_FUNC" \
  -fuzzingMode "$MODE" \
  -prog "$PROG_NAME"



# === Create Directories After Fuzzing ===
RESULT_BASE="$TARGET_DIR/results/$SELECTED_TEST_FUNC/$MODE"

mkdir -p "$RESULT_BASE"


# === Move advocateResult ===
if [ -d "$TARGET_DIR/advocateResult" ]; then
  INNER_DIR=$(find "$TARGET_DIR/advocateResult" -maxdepth 1 -type d -name 'file*' | head -n1)
  if [ -n "$INNER_DIR" ]; then
    mv "$INNER_DIR"/* "$RESULT_BASE"/
  fi
  rm -rf "$TARGET_DIR/advocateResult"
  echo "--- Saved advocateResult to $RESULT_BASE"
else
  echo "--- No advocateResult generated for $SELECTED_TEST_FUNC"
fi


# === Move fuzzingTraces ===
if [ -d "$TARGET_DIR/fuzzingTraces" ]; then
  mv "$TARGET_DIR/fuzzingTraces" "$RESULT_BASE"/
  echo "---> Moved fuzzingTraces to $RESULT_BASE/fuzzingTraces"
fi

echo "Fuzzing finished for $SELECTED_TEST_FUNC with mode $MODE."
