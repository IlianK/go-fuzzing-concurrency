import argparse
import csv
import glob
import os

def read_csv_row(path, row=1):
    with open(path, newline='') as f:
        reader = csv.reader(f)
        for i, r in enumerate(reader):
            if i == row:
                return r
    return []

def find_file(pattern, directory):
    matches = glob.glob(os.path.join(directory, pattern))
    return matches[0] if matches else None

def parse_unique_bugs(result_dir):
    file = find_file("statsAll_*.csv", result_dir)
    if not file:
        return None, None
    hdr = read_csv_row(file, 0)
    values = read_csv_row(file, 1)
    ids = [h.replace("NoUniqueDetected", "") for h, v in zip(hdr, values)
           if h.startswith("NoUniqueDetected") and int(v) > 0]
    return len(ids), ";".join(ids) if ids else None

def parse_total_bugs(result_dir):
    file = find_file("statsAnalysis_*.csv", result_dir)
    if not file:
        return None
    row = read_csv_row(file, 1)
    return int(row[1])

def parse_total_runs(result_dir):
    file = find_file("statsFuzzing_*.csv", result_dir)
    if not file:
        return None
    row = read_csv_row(file, 1)
    return int(row[1])

def parse_total_time(result_dir):
    file = find_file("times_total_*.csv", result_dir)
    if not file:
        return None
    row = read_csv_row(file, 1)
    return float(row[1]) if row[1] else None

def parse_detail_times(result_dir):
    file = find_file("times_detail_*.csv", result_dir)
    rec = ana = rep = None
    if file:
        hdr = read_csv_row(file, 0)
        values = read_csv_row(file, 1)
        for h, v in zip(hdr, values):
            if h == "Recording":
                rec = v
            elif h == "Analysis":
                ana = v
            elif h == "Replay":
                rep = v
    return rec, ana, rep

def parse_leaks_panics_replays(result_dir):
    file = find_file("statsAnalysis_*.csv", result_dir)
    if not file:
        return None, None, None
    row = read_csv_row(file, 1)
    leaks = int(row[2])
    panics = int(row[5])
    replays = int(row[6])
    return leaks, panics, replays

def parse_bug_type_summary(result_dir):
    file = find_file("statsAll_*.csv", result_dir)
    if not file:
        return None
    hdr = read_csv_row(file, 0)
    values = read_csv_row(file, 1)
    types = [h.replace("NoUniqueDetected", "") for h, v in zip(hdr, values)
             if h.startswith("NoUniqueDetected") and int(v) > 0]
    return ";".join(types) if types else None

def parse_replay_stats(result_dir):
    file = find_file("statsFuzzing_*.csv", result_dir)
    if not file:
        return None, None
    hdr = read_csv_row(file, 0)
    row = read_csv_row(file, 1)
    replay_written = sum(int(v) for h, v in zip(hdr, row) if h.startswith("NoReplayWritten"))
    replay_successful = sum(int(v) for h, v in zip(hdr, row) if h.startswith("NoReplaySuccessful"))
    return replay_written, replay_successful

def gather_modes(results_dir):
    return sorted([
        d for d in os.listdir(results_dir)
        if os.path.isdir(os.path.join(results_dir, d))
    ])

def generate_comparison(results_dir):
    modes = gather_modes(results_dir)
    out_path = os.path.join(results_dir, "comparison.csv")
    header = [
        "Mode", "Unique_Bugs", "Bug_Types", "Total_Bugs",
        "Panics", "Leaks", "Confirmed_Replays",
        "Total_Runs", "Total_Time_s", "Rec_s", "Ana_s", "Rep_s",
        "Bugs_per_1000_Runs", "Bugs_per_Minute", "Runs_per_Minute",
        "Replays_Written", "Replays_Successful"
    ]

    with open(out_path, "w", newline='') as outf:
        writer = csv.writer(outf)
        writer.writerow(header)

        for mode in modes:
            path = os.path.join(results_dir, mode)
            uniq_cnt, bug_types = parse_unique_bugs(path)
            total_bugs = parse_total_bugs(path)
            total_runs = parse_total_runs(path)
            total_time = parse_total_time(path)
            rec, ana, rep = parse_detail_times(path)
            leaks, panics, replays = parse_leaks_panics_replays(path)
            replay_written, replay_successful = parse_replay_stats(path)

            bpr = round((total_bugs / total_runs) * 1000, 2) if total_runs and total_bugs is not None else None
            bpm = round(total_bugs / (total_time / 60), 2) if total_time and total_bugs is not None else None
            rpm = round(total_runs / (total_time / 60), 2) if total_time and total_runs else None

            writer.writerow([
                mode, uniq_cnt, bug_types, total_bugs,
                panics, leaks, replays,
                total_runs, f"{total_time:.5f}" if total_time is not None else None,
                rec, ana, rep,
                bpr, bpm, rpm,
                replay_written, replay_successful
            ])

    print(f"comparison.csv written to {out_path}")

def main():
    parser = argparse.ArgumentParser(description="Generate comparison.csv")
    parser.add_argument("results_dir", help="Path to a single test's results folder")
    args = parser.parse_args()

    if not os.path.isdir(args.results_dir):
        print(f"Error: '{args.results_dir}' is not a directory.")
        exit(1)

    generate_comparison(args.results_dir)

if __name__ == "__main__":
    main()
