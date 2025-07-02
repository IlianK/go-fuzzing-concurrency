import os
import sys

# Get the target dir
TARGET_DIR = sys.argv[1]  

# Configuration
MODES = ["GFuzz", "GFuzzHB", "Flow", "GFuzzHBFlow", "GoPie", "GoPie+", "GoPieHB"]
LOG_FILES = [
    "output.log",
    "results_machine.log",
    "results_readable.log",
    "total_output.log",
    "total_results_machine.log",
    "total_results_readable.log"
]

# Create combined dir 
combined_dir = os.path.join(TARGET_DIR, "combined")
os.makedirs(combined_dir, exist_ok=True)

# Create logs dir
logs_dir = os.path.join(combined_dir, "logs")
os.makedirs(logs_dir, exist_ok=True)

# Aggregate logs from each mode and subdir
for log_name in LOG_FILES:
    combined_path = os.path.join(logs_dir, log_name)
    with open(combined_path, "w", encoding="utf-8") as out_file:
        for mode in MODES:
            mode_dir = os.path.join(TARGET_DIR, mode)
            if not os.path.isdir(mode_dir):
                continue
            
            # Search for the subdirs (e.g., file(1)-test(1)-...)
            subdirs = [d for d in os.listdir(mode_dir) if os.path.isdir(os.path.join(mode_dir, d))]
            for sub in subdirs:
                file_path = os.path.join(mode_dir, sub, log_name)
                if os.path.exists(file_path):
                    out_file.write(f"\n\n### Mode: {mode} | Subdir: {sub} ###\n\n")
                    with open(file_path, "r", encoding="utf-8") as f:
                        out_file.write(f.read())

print(f"Aggregated log files written to: {logs_dir}")
