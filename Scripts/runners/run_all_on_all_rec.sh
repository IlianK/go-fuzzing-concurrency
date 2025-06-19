
#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Config
# -----------------------------
ADVOCATE_BIN="./ADVOCATE/advocate/advocate"
MODES=("GFuzz" "GFuzzHB" "Flow" "GFuzzHBFlow" "GoPie" "GoPie+" "GoPieHB")
MAX_RUNS=100
TIMEOUT=10

# -----------------------------
# Argument check
# -----------------------------
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <relative/path/to/project-root>"
  exit 1
fi

TARGET_REL="$1"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_DIR="$ROOT/$TARGET_REL"
[[ -d "$PROJECT_DIR" ]] || { echo "No such dir: $PROJECT_DIR"; exit 1; }

# -----------------------------
# Discover all testable packages
# -----------------------------
PACKAGES=$(find "$PROJECT_DIR" -type f -name "*_test.go" -exec dirname {} \; | sort -u)

# -----------------------------
# Loop through each test package
# -----------------------------
for PKG_DIR in $PACKAGES; do
  echo "## Testing package: $PKG_DIR"

  pushd "$PKG_DIR" > /dev/null
  TESTS=( $(go test -list . | grep '^Test') )
  popd > /dev/null

  if [[ ${#TESTS[@]} -eq 0 ]]; then
    echo "No tests found in $PKG_DIR"
    continue
  fi

  for TEST in "${TESTS[@]}"; do
    echo "### Test: $TEST"
    for M in "${MODES[@]}"; do
      echo ">>> Mode: $M"
      RDIR="$PROJECT_DIR/results/$(basename "$PKG_DIR")/$TEST/$M"
      mkdir -p "$RDIR"

      "$ADVOCATE_BIN" fuzzing \
        -path "$PKG_DIR" \
        -exec "$TEST" \
        -fuzzingMode "$M" \
        -prog "$TEST" \
        -maxFuzzingRun "$MAX_RUNS" \
        -timeoutFuz "$TIMEOUT" \
        -timeoutRec "$TIMEOUT" \
        -timeoutRep "$TIMEOUT" \
        -time -stats \
        || echo "$TEST / $M failed"

      if [[ -d "$PKG_DIR/advocateResult" ]]; then
        mv "$PKG_DIR/advocateResult"/* "$RDIR"/
        rm -rf "$PKG_DIR/advocateResult"
      fi
    done

    # -----------------------------
    # Generate comparison
    # -----------------------------
    python3 "$ROOT/Scripts/compare_results.py" "$PROJECT_DIR/results/$(basename "$PKG_DIR")/$TEST"
  done
done
