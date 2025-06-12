#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Config
# -----------------------------
ADVOCATE_BIN="./ADVOCATE/advocate/advocate"
MODES=("GFuzz" "GoPie" "GoPie+")
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
# Pick test
# -----------------------------
pushd "$TDIR" > /dev/null
TESTS=( $(go test -list . | grep '^Test') )
popd > /dev/null
select TEST in "${TESTS[@]}"; do
  [[ -n "$TEST" ]] && break
done

# -----------------------------
# Prepare results folder
# -----------------------------
RDIR="$TDIR/results/$TEST"
mkdir -p "$RDIR"

# -----------------------------
# Loop tests & modes
# -----------------------------
for M in "${MODES[@]}"; do
  echo ">>> $M for $TEST"
  MDIR="$RDIR/$M"
  mkdir -p "$MDIR"
  "$ADVOCATE_BIN" fuzzing \
    -path "$TDIR" -exec "$TEST" -fuzzingMode "$M" \
    -prog "$TEST" -maxFuzzingRun "$MAX_RUNS" \
    -timeoutFuz "$TIMEOUT" -timeoutRec "$TIMEOUT" -timeoutRep "$TIMEOUT" \
    -time -stats -keepTrace \
    || echo "$M failed"
  [[ -d "$TDIR/advocateResult" ]] && mv "$TDIR/advocateResult"/* "$MDIR"/ && rm -rf "$TDIR/advocateResult"
done

# -----------------------------
# Generate comparison
# -----------------------------
python3 "$ROOT/Scripts/compare_results.py" "$RDIR"
