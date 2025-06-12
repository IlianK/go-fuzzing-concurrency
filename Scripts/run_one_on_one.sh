#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Config
# -----------------------------
ADVOCATE_BIN="./ADVOCATE/advocate/advocate"
MAX_RUNS=100
TIMEOUT=60

# -----------------------------
# Arg check
# -----------------------------
if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <Mode> <relative/path/to/test/folder>"
  exit 1
fi
MODE="$1"
TARGET_REL="$2"
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
RDIR="$TDIR/results/$TEST/$MODE"
mkdir -p "$RDIR"

# -----------------------------
# Run the single mode
# -----------------------------
echo ">>> $MODE for $TEST"
"$ADVOCATE_BIN" fuzzing \
  -path "$TDIR" -exec "$TEST" \
  -fuzzingMode "$MODE" -prog "$TEST" \
  -maxFuzzingRun "$MAX_RUNS" \
  -timeoutFuz "$TIMEOUT" -timeoutRec "$TIMEOUT" -timeoutRep "$TIMEOUT" \
  -time -stats -keepTrace \
  || echo "$MODE failed"
[[ -d "$TDIR/advocateResult" ]] && mv "$TDIR/advocateResult"/* "$RDIR"/ && rm -rf "$TDIR/advocateResult"

