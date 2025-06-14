#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Config
# -----------------------------
ADVOCATE_BIN="./ADVOCATE/advocate/advocate"
MODES=("GFuzz" "GFuzzHB" "Flow" "GFuzzHBFlow" "GoPie" "GoPie+" "GoPieHB")
MAX_RUNS=100
TIMEOUT=60

# -----------------------------
# Argument check
# -----------------------------
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <relative/path/to/test/folder>"
  exit 1
fi
TARGET_REL="$1"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TDIR="$ROOT/$TARGET_REL"
[[ -d "$TDIR" ]] || { echo "No such dir: $TDIR"; exit 1; }

# -----------------------------
# Gather tests
# -----------------------------
pushd "$TDIR" > /dev/null
TESTS=( $(go test -list . | grep '^Test') )
popd > /dev/null

# -----------------------------
# Loop tests & modes
# -----------------------------
for TEST in "${TESTS[@]}"; do
  echo "### Test: $TEST"
  for M in "${MODES[@]}"; do
    echo ">>> Mode: $M"
    RDIR="$TDIR/results/$TEST/$M"
    mkdir -p "$RDIR"

    "$ADVOCATE_BIN" fuzzing \
      -path "$TDIR" \
      -exec "$TEST" \
      -fuzzingMode "$M" \
      -prog "$TEST" \
      -maxFuzzingRun "$MAX_RUNS" \
      -timeoutFuz "$TIMEOUT" \
      -timeoutRec "$TIMEOUT" \
      -timeoutRep "$TIMEOUT" \
      -time -stats -keepTrace \
      || echo "$TEST / $M failed"

    if [[ -d "$TDIR/advocateResult" ]]; then
      mv "$TDIR/advocateResult"/* "$RDIR"/
      rm -rf "$TDIR/advocateResult"
    fi
  done

  # -----------------------------
  # Generate comparison
  # -----------------------------
  python3 "$ROOT/Scripts/compare_results.py" "$TDIR/results/$TEST"
done
