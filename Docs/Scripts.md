
# Scripts Overview

The `Scripts/` folder contains files used for running the fuzzing process, handling configurations, and aggregating the results.


## Folder Structure
```
Scripts/
├── config/
│ └── load_config.py 
├── runners/
│ ├── run_all_on_all.sh 
│ ├── run_all_on_one.sh 
│ ├── run_one_on_all.sh 
│ ├── run_one_on_one.sh 
├── setup/ 
│ ├── check_setup.sh 
│ ├── check_setup.sh 
├── tools/
│ ├── aggregate_log_files.py
│ ├── aggregate_stat_files.py 
│ ├── compare_results.py 
```

## Folder Descriptions

### `config/`
Contains `load_config.py` to read from `config.yaml`. It allows to tweak configurations like the number of runs, modes to be used, and timeouts, without modifying the scripts themselves. The scripts in the **runners/** folder allow for flexibility in running fuzzing process across different test cases and modes, to make it easier to compare results and aggregate them into one comprehensive report. 


### `runners/`
Contains bash scripts that automate the fuzzing tasks. The scripts allow:
- **`run_all_on_all.sh`**: Executes all modes on all test cases.
- **`run_all_on_one.sh`**: Executes all modes on a selected test case.
- **`run_one_on_all.sh`**: Executes one selected mode on all test cases.
- **`run_one_on_one.sh`**: Executes one selected mode on one selected test case.

These scripts are triggered with `run.sh` which allows for a selection.


### `setup/`
The `check_setup.sh` checks for the prerequisites to run ADVOCATE.
The `clean_results.sh` removes all result artefacts created by the fuzzing runs.


### `tools/`
Contains python scripts for aggregating logs and stats, as well as comparing results:
- **`aggregate_log_files.py`**: Aggregates log files into a single combined file for further analysis.
- **`aggregate_stat_files.py`**: Aggregates statistical data into a combined file to simplify comparison between runs.
- **`compare_results.py`**: Compares the results of different fuzzing modes and generates reports.


