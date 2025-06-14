# Go Concurrency Fuzzing
This project serves as an educational overview of concurrency-related bugs in Go, exploring the effectiveness of the Go Analysis tool [ADVOCATE](https://github.com/ErikKassubek/ADVOCATE) in detecting elusive concurrency bugs in both simple practial examples and real-world projects.

---

## Go Concurrency Bugs
Go offers built-in support for concurrency through goroutines and channels, making it a popular choice for building scalable, efficent applications.

However, writing correct concurrent programs is challenging. Concurrency bugs such as race conditions, deadlocks, and improper synchronization can lead to unpredictable behavior, crashes, and security vulnerabilities. These bugs are hard to detect and reproduce due to their non-deterministic nature, since all alternative schedules that lead to the concurrency bug, need to be considered.

Fuzzing is an automated testing technique that involves providing invalid, unexpected, or random data as inputs to a program to find crashes, bugs, or unexpected behavior. While traditionally used to test input handling and robustness,in the context of concurrency, fuzzing can be used to explore different execution paths (interleavings), increasing the chances of uncovering concurrency bugs that may only occur under specific timing conditions.

```go
func TestDeadlock(t *testing.T) {
	var mu1, mu2 sync.Mutex
	var wg sync.WaitGroup
	wg.Add(2)

	go func() {
		defer wg.Done()
		mu1.Lock()
		mu2.Lock()
		mu2.Unlock()
		mu1.Unlock()
	}()

	go func() {
		defer wg.Done()
		mu2.Lock()
		mu1.Lock()
		mu1.Unlock()
		mu2.Unlock()
	}()

	wg.Wait()
}

```
Considering the classic circular wait example above. Each goroutine attempts to lock two shared mutexes, but in opposite order: one locks `mu1` then `mu2`, while the other locks `mu2` then `mu1`. The main function cannot terminate either, because it is blocked by `wg.Wait()`, which waits for both goroutines to finish signaled by `wg.Done()`: 

A deadlock occurs if the first goroutine locks `mu1` and, before it can acquire `mu2`, the second goroutine locks `mu2` and tries to acquire `mu1`. At this point, each goroutine is waiting on a lock held by the other, leading to a circular wait with no way forward, which is a classic deadlock.


```
Main          |        Go 1         |          Go 2
-----------------------------------------------------------
              | Lock mu1            |
              |                     | Lock mu2
              | Wait for mu2        | Wait for mu1
              |                     |
```

On the other hand, if one goroutine manages to acquire both locks before the second begins or reaches its second lock, the function completes successfully. This can happen, for instance, if the first goroutine locks mu1 and mu2 sequentially before the second has a chance to lock mu2.

```
Main          |        Go 1         |          Go 2
-----------------------------------------------------------
              | Lock mu1            |
              | Lock mu2            |
              | Unlock mu2          |
              |                     | Lock mu2
              |                     | Wait for mu1
              | Unlock mu1          |
              |                     | Lock mu1
```

This is where concurrency analysis tools like GFuzz, GoPie and as per latest development ADVOCATE come into play.


---


## Concurrency Analysis Tools

### GFuzz
[GFuzz](https://github.com/system-pclub/GFuzz), is a concurrency analysis tool focused on detecting channel-related bugs in Go programs by systematically mutating select case executions.
According to the [GFuzz paper](https://songlh.github.io/paper/gfuzz.pdf), GFuzz found 184 previously unknown bugs in real-world Go projects 
<a id="cite2"></a>[<a href="#ref2">2</a>]. 

#### Mutation strategy 
GFuzz assigns unique identifiers to each select and its cases. In each test run, it enforces a preferred case for every select. After execution, it checks whether new behaviors or operations were explored. If so, it mutates the preferred cases to guide the next run. This targeted message reordering increases the likelihood of uncovering concurrency bugs that only occur under specific interleavings <a id="cite1"></a>[<a href="#ref1">1</a>].

#### Run Time Statistics
The mutation strategy is driven by runtime statistics such as the number of send/receive operations, created or closed channels, and buffer states. These metrics are used to calculate mutation scores.

#### Order Enforcement
GFuzz modifies the program code to enforce execution order. It instruments each select with a wrapper that initially tries to execute only the preferred case. If the case is not selectable (due to a missing sender/receiver), it falls back to the original select with a timeout, to ensure progress without getting stuck.

#### Bug detection
GFuzz focuses on identifying blocking goroutines. If a goroutine is stuck in a channel operation with no possible partner it flags it as a blocking bug.

---

### GoPie
[GoPie](https://github.com/CGCL-codes/GoPie) extends GFuzz’s ideas beyond select statements. It targets a broader class of concurrency bugs by directly influencing the interleaving of goroutine scheduling across synchronization primitives like channels and mutexes.
The theory is explained in detail in the [GoPie paper](https://chao-peng.github.io/publication/ase23/ase23.pdf).

#### Fragmentation
To manage the complexity and avoid exploring all possible interleavings, GoPie breaks the execution trace into smaller fragments called scheduling chains (SCs). Those are sequences of operations from different goroutines, and only one chain is mutated at a time. So GoPie analysis focus is only on key interaction points between goroutines <a id="cite3"></a>[<a href="#ref3">3</a>].

#### Relationships
GoPie identifies potential mutation points by analyzing two types of relationships between operations. These relationships reveal which operations are meaningfully connected and suitable for mutation <a id="cite4"></a>[<a href="#ref4">4</a>].
- Rel1: operations that occur one after another within the same goroutine
- Rel2: operations on the same synchronization primitive (channel or mutex) across different goroutines.

#### Mutation Strageties
Based on these relationships, GoPie applies different mutation strategies to explore new (potentially bug-revealing) interleavings <a id="cite3"></a>[<a href="#ref3">3</a>]. . 

- Abridge: shortens the scheduling chain by trimming head or tail operations.
- Flip: reverses operation order in a chain segment.
- Substitute: replaces operations with related ones from Rel1.
- Augment: adds related operations from Rel2 to the chain.

(Note: While the Flip strategy is described in the GoPie paper, it is not implemented in the current version of the tool.)

#### Feedback Collection
GoPie selectively chooses which test runs to mutate further, based on feedback from previous executions. A run is considered successful if it completes without exceeding time limits or triggering timeouts on synchronization operations. If a run fails due to timeouts or if runs are too long (over 7 minutes), it may be excluded from future mutations. This mechanism helps to focus resources on promising interleavings and avoid wasting time on ineffective paths <a id="cite4"></a>[<a href="#ref4">4</a>].

#### Order Reinforcement
GoPie also enforces execution order based on the mutated schedule. This means that each operation runs only when it is its turn in the planned schedule. If it’s not the next expected operation, it simply waits. 

So by combining selective mutation with schedule-based execution control, GoPie can find concurrency bugs without relying on random scheduling or trying every possible combination.

--- 

### Advocate
[ADVOCATE](https://github.com/ErikKassubek/ADVOCATE) builds on GFuzz and GoPie, operating by recording execution traces of programs and analyzing them to identify potential concurrency issues, also using happens-before relations and vector clocks. Advocate supports several modes  <a id="cite5"></a>[<a href="#ref5">5</a>]:
1. **Record**: Captures the execution trace of a program or test.
2. **Replay**: Re-executes a program following a recorded trace to reproduce specific behaviors.
3. **Analysis**: Analyzes recorded traces to detect potential concurrency bugs like channel misuse, leaks and deadlocks.
4. **Fuzzing**: Includes and extends GFuzz (select-based) and GoPie (order-based) strategies.


#### Runtime
Advocate uses a custom-modified Go runtime to implement recording, replay, and fuzzing. Instrumentation in this context refers to the insertion of extra logic to monitor or control execution. Traditional tools like GFuzz and GoPie instrument source code directly. For example, the original GFuzz directly instruments each select in the source code to enforce case selection <a id="cite7"></a>[<a href="#ref7">7</a>], and GoPie modifies the source to enable recording and replay <a id="cite9"></a>[<a href="#ref9">9</a>]. Advocate instruments the Go runtime itself, embedding logic into low-level concurrency primitives like select, channel operations, mutexes, and atomics <a id="cite10"></a>[<a href="#ref10">10</a>] <a id="cite11"></a>[<a href="#ref11">11</a>].

This runtime-level instrumentation allows Advocate to:
- Log execution traces during normal runs
- Enforce specific execution orders during replay or fuzzing
- Mutate schedules without modifying application logic

Although a small preamble and import are temporarily added to the program’s main or test function to initiate tracing, these are automatically removed after fuzzing. This minimizes developer overhead and ensures the original code remains untouched <a id="cite11"></a>[<a href="#ref11">11</a>].

--- 

#### Fuzzing Modes
Advocate's Fuzzing supports several modes, each for exploring different aspects of concurrency interleavings and bug types <a id="cite6"></a>[<a href="#ref6">6</a>]:

##### GFuzz
Reimplements the original GFuzz by mutating select statements to prefer specific cases. Unlike the original, which directly modifies source code, Advocate enforces case preference through its runtime. It uses recorded traces to guide mutations and avoids unnecessary instrumentation by relying on internal scheduling control as seen in <a id="cite7"></a>[<a href="#ref7">7</a>]

##### GFuzzHB
Extends GFuzz by integrating happens-before (HB) analysis. This allows Advocate to detect possible but unexecuted bugs, reducing the number of required runs. It also enhances scoring by incorporating select-case partner availability and biases mutation toward useful interleavings.
<a id="cite7"></a>[<a href="#ref7">7</a>]

##### Flow
The Flow mode uses trace-based HB relations alone (without mutations) to identify concurrency bugs. This means it relies entirely on static trace analysis instead of runtime execution of mutations, which offers a low-overhead bug detection pass.
<a id="cite8"></a>[<a href="#ref8">8</a>]

##### GFuzzHBFlow
This mode combines GFuzzHB's mutation strategy with Flow’s static HB-based analysis. Mutated schedules are executed once, and their traces are analyzed to detect both executed and theoretical bugs.
<a id="cite8"></a>[<a href="#ref8">8</a>]

##### GoPie
Reimplements GoPie’s order-based fuzzing. It mutates the execution order of operations within a scheduling chain derived from the trace. And again, unlike the original, which requires source code changes, Advocate integrates this logic into the runtime and improves replay accuracy.
<a id="cite9"></a>[<a href="#ref9">9</a>]

##### GoPie+
Improves upon GoPie by multiple features:
1. Allowing mutation of all operations, not just channels and mutexes, 
2. Introducing new chains from each mutation
3. Implementing the flip strategy missing in the original
4. Mutating even incomplete (leaking) operations
5. Enforcing more consistent replay.
<a id="cite9"></a>[<a href="#ref9">9</a>]

##### GoPieHB
Extends GoPie+ with HB analysis. This enables detection of theoretically possible bugs without requiring those interleavings to be executed, which improves both precision and coverage in concurrency testing.
<a id="cite9"></a>[<a href="#ref9">9</a>]


| **Note**: The fuzzing modes GFuzz, GoPie, and GoPie+ detect only bugs that result in observable effects, such as panics or goroutine leaks. They cannot detect silent or theoretical concurrency issues like scenarios A02, A07, or P01–P03, which require reasoning over happens-before relations. To detect these the analysis-based modes like Flow, GFuzzHB, GFuzzHBFlow, and GoPieHB should be used. which has HB-based detection logic.

--- 

#### Result artefacts
Each test produces results for a selected fuzzing engine (e.g., GFuzz, GoPie, GoPie+) including log files (output.log, results_machine.log, results_readable.log) and a bug summary (bug_*.md). Also csv-based statistics reports are created when flag `-stats` is set (statsAll, statsAnalysis, statsFuzzing) <a id="cite12"></a>[<a href="#ref12">12</a>].

---
---

## Project Overview
The goal of this project is to evaluate and compare the fuzzing modes of the Advocate Go tool in terms of performance (recording, analysis, replay, and fuzzing time) and efficiency in detecting concurrency-related bugs. It also aims to analyze overlaps and distinctions in bug detection across modes, identifying whether specific bugs are more efficeintly exposed by certain modes. For example, while GFuzz, GoPie, and GoPie+ can all detect select-related bugs, Advocate's GFuzz mode is expected to perform more efficiently in these cases. The project structure is as follows:

```bash
├── ADVOCATE                # Cloned ADVOCATE tool
├── Examples
│ ├── Examples_Own          # Concurrency bugs
│ ├── Examples_AutSys       # Examples from course Autonomous Systems
│ └── Examples_Projects     # Real-world Go projects
├── Scripts               	# Automation Scripts  
│ ├── check_setup.sh      
│ ├── clean_results.sh    
│ ├── compare_results.py  
│ ├── run_all_on_all.sh   
│ ├── run_all_on_one.sh   
│ └── run_one_on_one.sh   
└── README.md
```

---

### Scripts
The following scripts were used to automate the comparison of fuzzing modes and test cases:

- **check_setup.sh**: Checks Go environment, version, patched binary, version of patched go to verify setup.

- **clean_results.sh**: Removes all result artifacts to reset the workspace for fresh fuzzing runs.

- **run_all_on_all.sh**: Runs all defined fuzzing modes on all test case found 
    in the given directory.

- **run_all_on_one.sh**: Runs all defined fuzzing modes on a selected test case (interactive select).

- **run_one_on_one.sh**: Runs one given fuzzing mode on a selected test case (interactive select).

- **compare_results.py**: Is called within the `run_all_on_one.sh` and `run_all_on_all.sh` and creates a comparison.csv for a specific test case, aggregating the bugs, timings, and replay info per mode.


---

### Metrics of comparison

---

### Examples_Own
This directory contains simple Go programs that include common concurrency bugs, to test Advocate's detection of specific issues. They cover tests related to ...:

#### Channel
#### Deadlock
#### Select
#### WaitGroup



#### Scenarios

The `Scenarios` directory contains test cases to cover each scenario Advocate is able to cover via analysis. 

##### Modes Detection Scope

| **Test Function**                    | **Description**                                | **GFuzz** | **GoPie (incl. +)** | **HB-Based Modes** |
| ------------------------------------ | ---------------------------------------------- | :-------: | :-----------------: | :----------------: |
| `TestA00_UnknownPanic`               | Explicit `panic(...)`                          |     ✓     |          ✓          |          ✓         |
| `TestA01_SendOnClosed`               | Send on a closed channel → runtime panic       |     ✓     |          ✓          |          ✓         |
| `TestA02_ReceiveOnClosed`            | Receive from closed channel returns zero       |           |                     |          ✓         |
| `TestA03_CloseOnClosed`              | Closing a channel twice → runtime panic        |     ✓     |          ✓          |          ✓         |
| `TestA04_CloseOnNil`                 | Closing a nil channel → runtime panic          |     ✓     |          ✓          |          ✓         |
| `TestA05_NegativeWaitGroup`          | Too many `wg.Done()` calls → runtime panic     |     ✓     |          ✓          |          ✓         |
| `TestA06_UnlockUnlocked`             | Unlocking an unlocked mutex → runtime panic    |     ✓     |          ✓          |          ✓         |
| `TestA07_ConcurrentRecv`             | Two concurrent `<-ch` ops, no panic or hang    |           |                     |          ✓         |
| `TestP01_PossibleSendOnClosed`       | Racing `ch <-` vs. `close(ch)` (no panic)      |           |                     |          ✓         |
| `TestP02_PossibleRecvOnClosed`       | Racing receives after close (no panic)         |           |                     |          ✓         |
| `TestP03_PossibleNegativeWaitGroup`  | Two `Done()` in goroutine (no panic)           |           |                     |          ✓         |
| `TestL00_UnknownLeak`                | Goroutine blocks on unclosed channel           |     ✓     |          ✓          |          ✓         |
| `TestL01_UnbufferedLeakWithPartner`  | Send paired later by goroutine → leak at exit  |     ✓     |          ✓          |          ✓         |
| `TestL02_UnbufferedLeakNoPartner`    | Send on unbuffered channel with no receiver    |     ✓     |          ✓          |          ✓         |
| `TestL03_BufferedLeakWithPartner`    | Buffered send consumed too late → leak at exit |     ✓     |          ✓          |          ✓         |
| `TestL04_BufferedLeakNoPartner`      | Send on full buffered channel with no reader   |     ✓     |          ✓          |          ✓         |
| `TestL05_LeakOnNilChan`              | Send on nil channel → blocks forever           |     ✓     |          ✓          |          ✓         |
| `TestL06_LeakOnSelectWithPartner`    | Select waiting on channel, matched later       |     ✓     |          ✓          |          ✓         |
| `TestL07_LeakOnSelectWithoutPartner` | Select on nil channel, fallback via timeout    |     ✓     |          ✓          |          ✓         |
| `TestL08_LeakOnMutex`                | `mu.Lock()` blocks, `Unlock()` delayed         |     ✓     |          ✓          |          ✓         |
| `TestL09_LeakOnWaitGroup`            | `wg.Wait()` never unblocks                     |     ✓     |          ✓          |          ✓         |
| `TestL10_LeakOnCond`                 | `cond.Wait()` without `Signal()`               |     ✓     |          ✓          |          ✓         |


##### Modes Performance
[TABLE]

##### Modes Precision
[TABLE]

---

### Examples_Projects
This directory contains cloned real-world Go projects, such as Docker Compose, Caddy, etcd, Gin, and Kubernetes. The goal is to apply Advocate's analysis and fuzzing capabilities to bigger Go projects to uncover their potential concurrency issues in production-grade codebases.

##### Modes Performance
[TABLE]

##### Modes Precision
[TABLE]


---

### Examples_AutSys
This directory contains examples sourced from the course [Autonomous Systems](https://sulzmann.github.io/AutonomeSysteme/) by Prof. Dr. Martin Sulzmann. These examples are educational in nature and cover various aspects of concurrent programming in Go, including deadlock analysis and concurrency models:


---
---

## References
[↩](#cite1) <a id="ref1">[1]</a> Erik Kassubek, GFuzz Summary, AdvocateGo Project, https://github.com/ErikKassubek/ADVOCATE/blob/main/doc_proj/relatedWorks/PaperAndTools/Fuzzing/GFuzz.md

[↩](#cite2) <a id="ref2">[2]</a> Z. Liu, S. Xia, Y. Liang, L. Song, and H. Hu. Who goes first? Detecting Go concurrency bugs via message reordering. ASPLOS 2022, https://songlh.github.io/paper/gfuzz.pdf

[↩](#cite3)  <a id="ref3">[3]</a> Z. Jiang, M. Wen, Y. Yang, C. Peng, P. Yang, and H. Jin. Effective Concurrency Testing for Go via Directional Primitive-Constrained Interleaving Exploration. ASE 2023, https://chao-peng.github.io/publication/ase23/ase23.pdf

[↩](#cite4)  <a id="ref4">[4]</a> Erik Kassubek, GoPie Summary, AdvocateGo Project, https://github.com/ErikKassubek/ADVOCATE/blob/main/doc_proj/relatedWorks/PaperAndTools/Fuzzing/GoPie.md

[↩](#cite5)  <a id="ref5">[5]</a> Erik Kassubek, GoPie Usage, AdvocateGo Project, https://github.com/ErikKassubek/ADVOCATE/blob/main/doc_proj/usage.md

[↩](#cite6)  <a id="ref6">[6]</a> Erik Kassubek, GoPie Fuzzing, AdvocateGo Project, https://github.com/ErikKassubek/ADVOCATE/tree/main/doc/fuzzing

[↩](#cite7)  <a id="ref7">[7]</a> Erik Kassubek, Advocate GFuzz Mode, AdvocateGo Project, https://github.com/ErikKassubek/ADVOCATE/blob/main/doc/fuzzing/GFuzz.md

[↩](#cite8)  <a id="ref8">[8]</a> Erik Kassubek, Advocate Flow Mode, AdvocateGo Project, https://github.com/ErikKassubek/ADVOCATE/blob/main/doc/fuzzing/GoPie.md

[↩](#cite9)  <a id="ref9">[9]</a> Erik Kassubek, Advocate GoPie Mode, AdvocateGo Project, https://github.com/ErikKassubek/ADVOCATE/blob/main/doc/fuzzing/GoPie.md

[↩](#cite10)  <a id="ref10">[10]</a> Erik Kassubek, Advocate Runtime, AdvocateGo Project, https://github.com/ErikKassubek/ADVOCATE/blob/main/doc_proj/runtime.md

[↩](#cite11)  <a id="ref11">[11]</a> Erik Kassubek, Advocate Recording, AdvocateGo Project, https://github.com/ErikKassubek/ADVOCATE/blob/main/doc_proj/recording.md

[↩](#cite12)  <a id="ref12">[12]</a> Erik Kassubek, Advocate Statistics, AdvocateGo Project, https://github.com/ErikKassubek/ADVOCATE/blob/main/doc/stats/stats.md