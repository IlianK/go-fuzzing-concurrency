#!/usr/bin/env bash
set -euo pipefail


# ------------------------------------------
# Resolve paths 
# ------------------------------------------
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TARGET_REL="$1"
CONFIG_PATH="$2"
TDIR="$ROOT/$TARGET_REL"
[[ -d "$TDIR" ]] || { echo "No such dir: $TDIR"; exit 1; }


# ------------------------------------------
# Load config
# ------------------------------------------
if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "Error: Config file not found at $CONFIG_PATH"
  exit 1
fi
eval "$(python3 "$ROOT/Scripts/config/load_config.py" "$CONFIG_PATH")"


# -----------------------------
# Gather test cases
# -----------------------------
pushd "$TDIR" > /dev/null
TESTS=( $(go test -list . | grep '^Test') )
popd > /dev/null


# -----------------------------
# Loop through each test and mode
# -----------------------------
for TEST in "${TESTS[@]}"; do
  echo "### Test: $TEST"

  # Loop through each mode
  for M in "${MODES[@]}"; do
    echo ">>> Mode: $M"

    # Prepare result folder for each mode and test
    RDIR="$TDIR/results/$TEST/$M"
    mkdir -p "$RDIR"

    # Prepare common base 
    CMD=(
      "$ADVOCATE_BIN" fuzzing
      -path "$TDIR"
      -exec "$TEST"
      -fuzzingMode "$M"
      -prog "$TEST"
      -maxFuzzingRun "$MAX_RUNS"
      -timeoutFuz "$TIMEOUT"
      -timeoutRec "$TIMEOUT"
      -timeoutRep "$TIMEOUT"
    )

    if [[ "$RECORD_TIME" == "true" ]]; then
      CMD+=(-time)
    fi
    if [[ "$RECORD_STATS" == "true" ]]; then
      CMD+=(-stats)
    fi

    # Run 
    "${CMD[@]}" || echo "$TEST / $M failed"

    # Move results 
    [[ -d "$TDIR/advocateResult" ]] && mv "$TDIR/advocateResult"/* "$RDIR"/ && rm -rf "$TDIR/advocateResult"
  done


  # -----------------------------
  # Aggregating log and stat files
  # -----------------------------
  echo "Aggregating log and stat files..."
  
  # Combined dir
  COMBINED_DIR="$TDIR/results/$TEST/combined"
  mkdir -p "$COMBINED_DIR"  

  # Aggregate 
  python3 "$ROOT/Scripts/tools/aggregate_log_files.py" "$TDIR/results/$TEST"
  python3 "$ROOT/Scripts/tools/aggregate_stat_files.py" "$TDIR/results/$TEST"

  echo "Aggregation complete. Files are stored in: $COMBINED_DIR"


  # -----------------------------
  # Generate comparison CSV
  # -----------------------------
  echo "Generating comparison.csv..."
  python3 "$ROOT/Scripts/tools/compare_results.py" "$TDIR/results/$TEST"

done
