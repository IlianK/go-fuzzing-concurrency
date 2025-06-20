#!/usr/bin/env bash
set -euo pipefail

RESULTS_DIR="$1"

if [[ ! -d "$RESULTS_DIR" ]]; then
  echo "Error: '$RESULTS_DIR' is not a valid directory."
  exit 1
fi

for TEST_DIR in "$RESULTS_DIR"/*/; do
  if [[ -d "$TEST_DIR" ]]; then
    echo "Running comparison for: $TEST_DIR"
    python3 Scripts/tools/compare_results.py "$TEST_DIR"
  fi
done
