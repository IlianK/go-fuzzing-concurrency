#!/bin/bash

echo "Cleaning all advocateResult, fuzzingTraces and results folders..."

find ./Examples -type d -name "advocateResult" -exec rm -rf {} +
find ./Examples -type d -name "fuzzingTraces" -exec rm -rf {} +
find ./Examples -type d -name "results" -exec rm -rf {} +

echo "Cleanup complete."
