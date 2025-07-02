
# Scripts Overview

The [`Scripts/`](../Scripts/) folder contains files used for running the fuzzing process, handling configurations, and aggregating the results.


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

### [`setup/`](../Scripts/setup/)
- [`check_setup.sh`](../Scripts/setup/check_setup.sh): Verifies that your system and Advocate environment are correctly set up, by checking:
  - The system Go binary and version
  - Presence of the patched Advocate Go runtime (`go-patch`) and that it is executable
  - Version of the patched Go runtime

- [`clean_results.sh`](../Scripts/setup/clean_results.sh): Removes all result artifacts created by fuzzing runs. You can customize it by modifying the target folder path, which is recursively searched for artifacts to delete.




### [`config/`](../Scripts/config/)
Contains [`load_config.py`](../Scripts/config/load_config.py) to read from [`config.yaml`](../config.yaml). It allows to tweak configurations like the number of runs, modes to be used, and timeouts, without modifying the scripts themselves. The scripts in the **runners/** folder allow for flexibility in running fuzzing process across different test cases and modes, to make it easier to compare results and aggregate them into one comprehensive report. 


### [`runners/`](../Scripts/runners/)
Contains bash scripts that automate the fuzzing tasks. The scripts allow:
- [`run_all_on_all.sh`](../Scripts/runners/run_all_on_all.sh): Executes all modes on all test cases.
- [`run_all_on_one.sh`](../Scripts/runners/run_all_on_one.sh): Executes all modes on a selected test case.
- [`run_one_on_all.sh`](../Scripts/runners/run_one_on_all.sh): Executes one selected mode on all test cases.
- [`run_one_on_one.sh`](../Scripts/runners/run_one_on_one.sh): Executes one selected mode on one selected test case.

These scripts are triggered by [`run.sh`](../run.sh), which presents an interactive selection menu.


As **`run_all_on_all.sh`** and **`run_all_on_one.sh`** are using all modes defined in the `config` for fuzzing tests, the execution of `compare_results.py` is triggered afterwards, which compares the tests across all modes.


### [`tools/`](../Scripts/tools/)

Contains Python and shell scripts for aggregating logs and stats, extracting meaningful metrics, and comparing results:

- [`aggregate_log_files.py`](../Scripts/tools/aggregate_log_files.py): Aggregates log files into a single combined file for further analysis.
- [`aggregate_stat_files.py`](../Scripts/tools/aggregate_stat_files.py): Aggregates statistical data into a combined file to simplify comparison between runs.
- [`compare_results.py`](../Scripts/tools/compare_results.py): Compares the results of different fuzzing modes and generates reports. Triggered automatically by the runner scripts or manually by `compare_results.sh`.
- [`compare_results.sh`](../Scripts/tools/compare_results.sh): Manually triggers `compare_results.py` to run comparisons in a given `results` directory after fuzzing has completed.
- [`compare_metric.py`](../Scripts/tools/compare_metric.py): Generates a cross-test pivot table comparing a specific selected metric across all fuzzing modes.

