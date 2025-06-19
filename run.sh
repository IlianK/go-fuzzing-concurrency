#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Resolve paths
# -----------------------------
ROOT="$(cd "$(dirname "$0")" && pwd)"
RUNNERS="$ROOT/Scripts/runners"
CONFIG_PATH="$ROOT/config.yaml"

# ------------------------------------------
# Arg check 
# ------------------------------------------
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <relative/path/to/test/folder>"
  exit 1
fi

TARGET_REL="$1"
TDIR="$ROOT/$TARGET_REL"
[[ -d "$TDIR" ]] || { echo "No such dir: $TDIR"; exit 1; }

# ------------------------------------------
# Main menu
# ------------------------------------------
echo "========== Advocate Fuzzing Runner =========="
echo "Select mode:"
echo "  1) Run ALL modes on ALL test cases"
echo "  2) Run ALL modes on ONE selected test case"
echo "  3) Run ONE selected mode on ALL test cases"
echo "  4) Run ONE selected mode on ONE selected test case"
echo "  5) Exit"
read -rp "Choice [1-5]: " CHOICE
echo ""

# ------------------------------------------
# Define possible modes
# ------------------------------------------
MODES=("GFuzz" "GFuzzHB" "Flow" "GFuzzHBFlow" "GoPie" "GoPie+" "GoPieHB")

# ------------------------------------------
# Dispatch based on user choice
# ------------------------------------------
case "$CHOICE" in
  1) bash "$RUNNERS/run_all_on_all.sh" "$TARGET_REL" "$CONFIG_PATH" ;;
  2) bash "$RUNNERS/run_all_on_one.sh" "$TARGET_REL" "$CONFIG_PATH" ;;
  3)
    # Prompt for mode selection
    echo "Select fuzz mode:"
    select MODE in "${MODES[@]}"; do
      if [[ -n "$MODE" ]]; then
        echo "Selected mode: $MODE"
        break
      else
        echo "Invalid selection. Try again."
      fi
    done
    bash "$RUNNERS/run_one_on_all.sh" "$TARGET_REL" "$CONFIG_PATH" "$MODE"
    ;;
  4)
    # Prompt for mode selection
    echo "Select fuzz mode:"
    select MODE in "${MODES[@]}"; do
      if [[ -n "$MODE" ]]; then
        echo "Selected mode: $MODE"
        break
      else
        echo "Invalid selection. Try again."
      fi
    done
    # Prompt for test case selection
    pushd "$TDIR" > /dev/null
    TESTS=( $(go test -list . | grep '^Test') )
    popd > /dev/null

    echo "Available Tests:"
    select TEST in "${TESTS[@]}"; do
      if [[ -n "$TEST" ]]; then
        echo "Selected Test: $TEST"
        break
      else
        echo "Invalid selection. Try again."
      fi
    done

    bash "$RUNNERS/run_one_on_one.sh" "$TARGET_REL" "$CONFIG_PATH" "$MODE" "$TEST"
    ;;
  5) echo "Exiting." && exit 0 ;;
  *) echo "Invalid option." && exit 1 ;;
esac
