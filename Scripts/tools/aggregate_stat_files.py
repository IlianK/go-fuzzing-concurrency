import os
import sys
import csv
import glob

def find_stat_files(test_dir, stat_prefix):
    """Find all stat files for a given prefix in subdirectories (modes)."""
    pattern = os.path.join(test_dir, "*", f"{stat_prefix}_*.csv")
    return sorted(glob.glob(pattern))

def extract_mode_from_path(path):
    """Extract the mode name (folder name) from file path."""
    return os.path.basename(os.path.dirname(path))

def aggregate_stats(test_dir):
    combined_dir = os.path.join(test_dir, "combined")
    os.makedirs(combined_dir, exist_ok=True)

    # Create stats subdirectory for stat files aggregation
    stats_dir = os.path.join(combined_dir, "stats")
    os.makedirs(stats_dir, exist_ok=True)

    prefixes = [
        "statsAll", "statsFuzzing", "statsAnalysis", "statsMisc",
        "statsProgram", "statsTrace", "times_detail", "times_total"
    ]

    for prefix in prefixes:
        stat_files = find_stat_files(test_dir, prefix)
        if not stat_files:
            continue

        output_file = os.path.join(stats_dir, os.path.basename(stat_files[0]))
        with open(output_file, "w", newline='') as out_csv:
            writer = None
            for f in stat_files:
                with open(f, newline='') as in_csv:
                    reader = csv.reader(in_csv)
                    rows = list(reader)
                    if not rows:
                        continue
                    mode = extract_mode_from_path(f)
                    if writer is None:
                        # Extend header with "Mode" and write
                        header = ["Mode"] + rows[0]
                        writer = csv.writer(out_csv)
                        writer.writerow(header)
                    # Add mode name as first column for each row (skip header)
                    for row in rows[1:]:
                        writer.writerow([mode] + row)

    print(f"Aggregated stat files written to: {stats_dir}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 aggregate_stats_by_mode.py <path/to/TestX_folder>")
        sys.exit(1)

    test_folder = sys.argv[1]
    if not os.path.isdir(test_folder):
        print(f"Invalid folder: {test_folder}")
        sys.exit(1)

    aggregate_stats(test_folder)
