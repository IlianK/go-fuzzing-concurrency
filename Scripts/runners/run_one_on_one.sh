#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------
# Resolve paths
# ------------------------------------------
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TARGET_REL="$1"
CONFIG_PATH="$2"
MODE="$3"
TEST="$4"
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
# Prepare result folder for the test and mode
# -----------------------------
RDIR="$TDIR/results/$TEST/$MODE"
mkdir -p "$RDIR"

# Prepare the common base of the command
CMD=(
  "$ADVOCATE_BIN" fuzzing
  -path "$TDIR"
  -exec "$TEST"
  -fuzzingMode "$MODE"
  -prog "$TEST"
  -maxFuzzingRun "$MAX_RUNS"
  -timeoutFuz "$TIMEOUT"
  -timeoutRec "$TIMEOUT"
  -timeoutRep "$TIMEOUT"
)

# Conditionally add options if enabled in the config
if [[ "$RECORD_TIME" == "true" ]]; then
  CMD+=(-time)
fi
if [[ "$RECORD_STATS" == "true" ]]; then
  CMD+=(-stats)
fi

# Run the command
"${CMD[@]}" || echo "$TEST / $MODE failed"

# -----------------------------
# Move advocateResult to the respective mode folder and clean up
# -----------------------------
echo "Moving advocateResult to: $RDIR"
if [[ -d "$TDIR/advocateResult" ]]; then
  mv "$TDIR/advocateResult"/* "$RDIR"/
  rm -rf "$TDIR/advocateResult"  # Clean up the advocateResult directory
else
  echo "Error: No advocateResult directory found."
fi

echo "Results moved to: $RDIR"
