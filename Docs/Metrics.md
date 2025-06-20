# Metrics Explanation

The following are the metrics extracted and used for comparison from log and stats files during the fuzzing process to provide insights into performance, reliability, and issues encountered during testing.


## 1. Total Bugs

This metric captures the total number of bugs detected during the fuzzing process. These bugs are categorized into various types such as atomic, panics, etc. The `Total_Bugs` metric helps to understand how many issues were encountered across all modes of fuzzing.

**Source:**
- **Stats File:** `statsAnalysis_*.csv`

---

## 2. Leak Detection

Leak detection identifies any memory or resource leaks that were detected during fuzzing. It is important for ensuring that the system does not leave resources unfreed, which could cause performance degradation or crashes over time.

**Source:**
- **Stats File:** `statsAnalysis_*.csv`
- **Metric Names:** `NoLeaksTotal`, `NoLeaksWithRewriteTotal`, etc.

---

## 3. Panic Stats

Panics are unexpected errors that lead to program crashes. Tracking panics during fuzzing is important to identify areas where the system is vulnerable to unexpected crashes.

**Source:**
- **Stats File:** `statsAnalysis_*.csv`
- **Metric Names:** `NoPanicsTotal`, `NoPanicsVerifiedViaReplayTotal`, etc.

---

## 4. Replay Information

Replay information tracks how many times specific events were successfully or unsuccessfully replayed during the fuzzing process. This is important for reproducing bugs and verifying the correctness of the fuzzing results.

**Source:**
- **Stats File:** `statsFuzzing_*.csv`
- **Metric Names:** `NoReplayWritten`, `NoReplaySuccessful`

---

## 5. No. of Detected Bugs

This refers to the number of detected bugs categorized into different classes like atomic operations, panics, and leaks. This shows how many issues were encountered and whether they were unique to the execution.

**Source:**
- **Stats File:** `statsAll_*.csv`
- **Metric Names:** `NoTotalDetectedA01`, `NoTotalDetectedP01`, etc.

---

## 6. Unique Bugs

Unique bugs refer to the distinct bugs encountered during the fuzzing run. These metrics help in identifying the novel issues that were uncovered.

**Source:**
- **Stats File:** `statsAll_*.csv`
- **Metric Names:** `NoUniqueDetectedA01`, `NoUniqueDetectedP01`, etc.

---

## 7. Leaks and Panics

Leaks and panics are extracted to understand critical issues in the system. Leaks refer to resources that were not released, and panics represent system crashes that need attention.

**Source:**
- **Stats File:** `statsAnalysis_*.csv`
- **Metric Names:** `NoLeaksTotal`, `NoPanicsTotal`

---

## 8. Replay Stats

Replay stats are related to the success or failure of replaying previously detected issues. This metric is essential for verifying the reproducibility of bugs.

**Source:**
- **Stats File:** `statsFuzzing_*.csv`
- **Metric Names:** `NoReplayWritten`, `NoReplaySuccessful`

---

## 9. Run Stats

Run stats provide details about the number of times the test was executed, helping to understand the testing duration and the total number of executions.

**Source:**
- **Stats File:** `statsFuzzing_*.csv`
- **Metric Names:** `NoRuns`

---

## 10. Recording Time

The recording time metric measures the time spent on recording events during the fuzzing process.

**Source:**
- **Stats File:** `times_detail_*.csv`
- **Metric Names:** `Recording`

---

## 11. Analysis Time

Analysis time represents the duration spent in analyzing the fuzzing results during the test run. It helps in understanding how long it takes to perform in-depth analysis after fuzzing.

**Source:**
- **Stats File:** `times_detail_*.csv`
- **Metric Names:** `Analysis`

---

## 12. Replay Time

Replay time measures the duration spent on replaying any previously recorded or detected issues to verify the results.

**Source:**
- **Stats File:** `times_detail_*.csv`
- **Metric Names:** `Replay`

---

## 13. Run Time

The total time spent running the fuzzing test, how much time was invested in running tests.

**Source:**
- **Stats File:** `times_total_*.csv`
- **Metric Names:** `Time`

---

## 14. Replays

This metric tracks the total number of replays that were performed during the fuzzing process. Replays are important for ensuring that bugs can be reproduced in future runs.

**Source:**
- **Stats File:** `statsAnalysis_*.csv`
- **Metric Names:** `NoReplayWritten`, `NoReplaySuccessful`

---

## 15. Execution Time per Mode

This metric provides the execution time for each mode in the fuzzing process. It is useful for comparing the performance of different fuzzing strategies (e.g., GoPie, Flow, etc.).

**Source:**
- **Stats File:** `times_total_*.csv`
- **Metric Names:** `Time`

---

### Usage of Comparison Data

The comparison data in the `comparison.csv` file can be used to:

- Identify modes that produce highest number of bugs
- Compare efficiency of fuzzing modes based on number of runs, bugs, and time.
- Identify patterns between different modes in terms of resource usage, leaks, panics, and replays.
- Analyze bug types, leaks, and panics to improve the testing process and reduce vulnerabilities.

