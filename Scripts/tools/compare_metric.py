# creates /results/comparison_pivot_METRIC].csv

import os
import sys
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
all_metrics = metrics_perf + metrics_prec


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


# -------- Load all rows --------
rows = []
for test in selected_tests:
    path = os.path.join(root, test, "comparison.csv")
    df = pd.read_csv(path)
    for _, row in df.iterrows():
        rows.append({"Test": test, **row.to_dict()})

df_all = pd.DataFrame(rows)


# -------- Ask for metric to compare --------
print("\nAvailable metrics to compare:")
for i, m in enumerate(all_metrics, 1):
    print(f"{i}) {m}")
choice = input("Select a metric by number: ").strip()
if not choice.isdigit() or int(choice) < 1 or int(choice) > len(all_metrics):
    print("Invalid choice.")
    sys.exit(1)
metric = all_metrics[int(choice) - 1]


# -------- Pivot and display --------
pivot = df_all.pivot(index="Test", columns="Mode", values=metric)
print(f"\n=== {metric} COMPARISON ===")
print(pivot.fillna("-").to_string())


# -------- Save --------
output_csv = os.path.join(root, f"comparison_pivot_{metric}.csv")
pivot.to_csv(output_csv)
print(f"\nSaved: {output_csv}")
