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
# Select test case
# -----------------------------
pushd "$TDIR" > /dev/null
TESTS=( $(go test -list . | grep '^Test') )
popd > /dev/null
select TEST in "${TESTS[@]}"; do [[ -n "$TEST" ]] && break; done


# -----------------------------
# Prepare results folder
# -----------------------------
RDIR="$TDIR/results/$TEST"
mkdir -p "$RDIR"


# -----------------------------
# Run ALL modes on ONE test
# -----------------------------
for M in "${MODES[@]}"; do
  echo ">>> $M for $TEST"
  MDIR="$RDIR/$M"
  mkdir -p "$MDIR"
  
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
  "${CMD[@]}" || echo "$M failed"
  
  # Move results 
  [[ -d "$TDIR/advocateResult" ]] && mv "$TDIR/advocateResult"/* "$MDIR"/ && rm -rf "$TDIR/advocateResult"
done


# -----------------------------
# Aggregating log and stat files
# -----------------------------
echo "Aggregating log and stat files..."
python3 "$ROOT/Scripts/tools/aggregate_log_files.py" "$RDIR"
python3 "$ROOT/Scripts/tools/aggregate_stat_files.py" "$RDIR"

echo "Aggregation complete. Files are stored in: $RDIR/combined"


# -----------------------------
# Generate comparison CSV
# -----------------------------
echo "Generating comparison.csv..."
python3 "$ROOT/Scripts/tools/compare_results.py" "$RDIR"