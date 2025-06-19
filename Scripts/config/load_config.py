import yaml, sys

with open(sys.argv[1]) as f:
    cfg = yaml.safe_load(f)

print(f'ADVOCATE_BIN="{cfg.get("advocate_bin", "./advocate")}"')
print(f'MODES=({" ".join(cfg.get("modes", []))})')
print(f'MAX_RUNS={cfg.get("max_runs", 100)}')
print(f'TIMEOUT={cfg.get("timeout", 60)}')
print(f'RECORD_TIME={str(cfg.get("record_time", True)).lower()}')
print(f'RECORD_STATS={str(cfg.get("record_stats", True)).lower()}')
print(f'RESULTS_DIR="{cfg.get("results_dir", "results")}"')
