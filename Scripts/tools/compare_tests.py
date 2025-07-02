# creates /results/performance_ & precision_comparison.csv

import os, sys
import pandas as pd

# -------- Get path from command-line argument --------
if len(sys.argv) < 2:
    print("Usage: python3 compare_tests.py <path/to/Scenarios>")
    sys.exit(1)

root = sys.argv[1].strip()
if not os.path.isdir(root):
    print("Invalid folder path.")
    sys.exit(1)

metrics_perf = ["Total_Time_s", "Rec_s", "Ana_s", "Rep_s", "Runs_per_Minute"]
metrics_prec = ["Unique_Bugs", "Total_Bugs", "Bug_Types", "Bugs_per_1000_Runs", "Bugs_per_Minute"]


# -------- Discover tests --------
test_dirs = []
for d in os.listdir(root):
    test_path = os.path.join(root, d)
    if os.path.isdir(test_path) and os.path.isfile(os.path.join(test_path, "comparison.csv")):
        test_dirs.append(d)

if not test_dirs:
    print("No tests with comparison.csv found.")
    exit(1)

print(f"Found {len(test_dirs)} test(s): {', '.join(test_dirs)}")
selected_tests = test_dirs


# -------- Load and merge --------
perf_rows = []
prec_rows = []

for test in selected_tests:
    path = os.path.join(root, test, "comparison.csv")
    df = pd.read_csv(path)

    for _, row in df.iterrows():
        base = {"Test": test, "Mode": row["Mode"]}
        perf = {k: row[k] for k in metrics_perf if k in row}
        prec = {k: row[k] for k in metrics_prec if k in row}
        perf_rows.append({**base, **perf})
        prec_rows.append({**base, **prec})


# -------- Output tables --------
df_perf = pd.DataFrame(perf_rows)
df_prec = pd.DataFrame(prec_rows)

print("\n=== PERFORMANCE COMPARISON ===")
print(df_perf.to_string(index=False))

print("\n=== PRECISION COMPARISON ===")
print(df_prec.to_string(index=False))


# -------- Save to CSV --------
df_perf.to_csv(os.path.join(root, "performance_comparison.csv"), index=False)
df_prec.to_csv(os.path.join(root, "precision_comparison.csv"), index=False)
print(f"\nCSV files saved to: {root}")
