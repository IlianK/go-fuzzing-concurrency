# Go Concurrency Fuzzing

---------------------------------------------------------------------------------------------------------

## Go Concurrency Bugs
Go offers built-in support for concurrency through goroutines and channels, making it a popular choice for building scalable, efficent applications.

However, writing correct concurrent programs is challenging. Concurrency bugs such as race conditions, deadlocks, and improper synchronization can lead to unpredictable behavior, crashes, and security vulnerabilities. These bugs are often hard to detect and reproduce due to their non-deterministic nature.

Fuzzing is an automated testing technique that involves providing invalid, unexpected, or random data as inputs to a program. In the context of concurrency, fuzzing can be used to explore different execution paths and interleavings, increasing the chances of uncovering hidden concurrency bugs.
This goal is to reveal bugs that may only occur under specific timing conditions.

```go
package main

import "fmt"

func main() {
    ch := make(chan int)
    close(ch)
    go func() {
        ch <- 1   // send on closed channel
    }()
    fmt.Println("Done")
}

```

This program starts a goroutine that tries to send on a closed channel. But whether the program crashes depends on timing, since the goroutine may not execute before the main function exits. And whene it exists consequently all active go routines are terminated. Running this multiple times may or may not trigger a panic.

This is where concurrency analysis tools like GFuzz, GoPie and as per latest development ADVOCATE come into play.


---------------------------------------------------------------------------------------------------------


## Concurrency Analysis Tools


### GFuzz
GFuzz is a dynamic [open source analysis tool](https://github.com/system-pclub/GFuzz) designed to detect channel-related concurrency bugs in Go programs. It operates by:

- Reordering Concurrent Messages: GFuzz identifies concurrent channel operations, particularly within select statements, and systematically mutates their processing orders to explore different execution paths.

-  Feedback-Guided Fuzzing: It employs a fuzzing engine that prioritizes message orderings likely to expose bugs, based on execution feedback metrics.

-   Runtime Sanitization: It also includes a sanitizer that dynamically tracks channel references among goroutines to detect blocking bugs that cannot be unblocked by any other goroutine.

According to the [GFuzz paper](https://songlh.github.io/paper/gfuzz.pdf), the developers detected 184 previously unknown bugs across several real-world Go applications, demonstrating its effectiveness in uncovering subtle concurrency issues. 

---

### GoPie
GoPie is also an [open source tool](https://github.com/CGCL-codes/GoPie) introduces a novel approach for detecting concurrency bugs in Go by exploring interleavings constrained by synchronization primitives. According to the [GoPie paper](https://chao-peng.github.io/publication/ase23/ase23.pdf) key features include:

- Primitive-Constrained Interleaving Exploration: GoPie systematically explores execution paths by considering the constraints imposed by synchronization primitives like mutexes, channels, and wait groups.

- Directional Fuzzing: It guides the exploration towards interleavings that are more likely to reveal concurrency bugs, improving the efficiency of the testing process.

- Execution Feedback: GoPie utilizes execution feedback to prioritize interleavings that lead to new or previously untested code paths.

By focusing on the interplay between different synchronization primitives, GoPie effectively uncovers concurrency bugs that might be missed by other testing approaches.

--- 

### Advocate

ADVOCATE is an advanced [analysis tool available on Github](https://github.com/ErikKassubek/ADVOCATE) focused on detecting and diagnosing concurrency bugs.  
It operates by recording execution traces of programs and analyzing them to identify potential concurrency issues, also using happens-before relations and vector clocks. Advocate supports several modes:

1. **Record**: Captures the execution trace of a program or test.

2. **Replay**: Re-executes a program following a recorded trace to reproduce specific behaviors.

3. **Analysis**: Analyzes recorded traces to detect potential concurrency bugs like channel misuse, leaks and deadlocks.

4. **Fuzzing**: Applies various fuzzing strategies to explore different execution paths and uncover hidden bugs.

For detailed documentation on Advocate's fuzzing modes, refer to the [fuzzing documentation](https://github.com/ErikKassubek/ADVOCATE/tree/main/doc/fuzzing)


### Comparison

| **Tool**|**Approach**|**Strengths**|
| ------- | ---------- | ------------|
| **ADVOCATE** | Trace-based analysis using vector clocks; integrates multiple fuzzing strategies (GFuzz, GoPie, custom happens-before) | Broadest coverage: detects deadlocks, race conditions, goroutine leaks, panics, misuse of channels and sync primitives.<br>Deterministic replay for bug confirmation.<br>Extends GFuzz and GoPie with enhanced runtime control. |
| **GFuzz**    | Dynamic analysis via systematic mutation of message orderings in `select` and `chan` ops                               | Highly effective at uncovering **channel-related bugs** by exploring alternative communication schedules.<br> Lightweight and focused on select cases.                                                                             |
| **GoPie**    | Combines static and dynamic analysis; explores interleavings based on synchronization primitives                       | Detects **data races**, **deadlocks**, and **synchronization misuse**.<br>Fewer false positives due to primitive-constrained path exploration.                                                                                    |

--- 

#### Fuzzing Modes

ADVOCATE supports several distinct fuzzing modes, each designed to explore different aspects of concurrency interleavings and bug types. According to its documentation and repository, the main fuzzing modes are:

- **GFuzz**:
    Implements the original GFuzz algorithm, which systematically mutates the order of channel messages to explore different message interleavings and uncover channel-related bugs.

- **GFuzzHB**:
    An extension of GFuzz that incorporates happens-before (HB) analysis using vector clocks. This mode prunes redundant interleavings by only exploring those that are not equivalent under the happens-before relation, making the exploration more efficient and focused on unique concurrency behaviors.

- **Flow**:
    Focuses on the data flow between goroutines, guiding the fuzzing process based on the observed flow of data and synchronization events. This can help uncover bugs related to specific data dependencies and communication patterns.

- **GoPie**:
    Implements fuzzing strategies inspired by the GoPie tool, which combines static and dynamic analysis to guide the exploration of interleavings, particularly for synchronization primitives.

- **GoPieHB**:
    Extends the GoPie-inspired approach by integrating happens-before analysis, further reducing redundant explorations and targeting only those interleavings that could lead to new concurrency behaviors.

- **GFuzzHBFlow**:
    Combines the happens-before-guided exploration of GFuzzHB with the data flow focus of Flow mode, aiming for comprehensive coverage of both unique interleavings and data-dependent behaviors.


----

#### Configuration


---------------------------------------------------------------------------------------------------------


## Project Overview

The following project work will use ADVOCATE Go to detect and analyze concurrency related bugs across various codebases. 
The structure is as follows:


```bash
Go_Fuzzing_Concurrency/
├── ADVOCATE/              # Advocate tool
├── Examples/
│   ├── Examples_Own/      # Classic concurrency bugs
│   ├── Examples_Projects/ # Real-world Go projects
│   └── Examples_AutSys/   # Examples from course Autonomous Systems
└── Scripts/               # Automation scripts

```

### Examples_Own
This directory contains simple Go programs that intentionally include common concurrency bugs. These examples are designed to test Advocate's ability to detect specific issues. They cover scenarios related to ...:

- **Channels**: send, receive on closed channel, nil channels, double close, overflow
- **Lifecycle**: routine leaks, panics, uncontrolled spawning
- **Select**: select blocks, non-deterministic select
- **Synchronization**: mutex deadlocks, unlocks, waitgroups, race condition

Each example has a brief in-code description of the intended bug and expected behavior.

---

### Examples_Projects
This directory includes real-world Go projects, such as Docker Compose, Caddy, etcd, Gin, and Kubernetes. The goal is to apply Advocate's analysis and fuzzing capabilities to bigger Go projects to uncover potential concurrency issues in production-grade codebases.

---

### Examples_AutSys

This directory contains examples sourced from the course [Autonomous Systems](https://sulzmann.github.io/AutonomeSysteme/) by Prof. Dr. Martin Sulzmann. These examples are educational in nature and cover various aspects of concurrent programming in Go, including:

- Concurrency models
- Futures and promises
- Dynamic data race prediction
- Deadlock analysis

They serve as additional sources for understanding concurrency concepts and testing Advocate's analysis capabilities.

---

### Scripts
To process, analyze and fuzz the examples, there are specific scripts written:

- `verify_setup.sh`: Verifies that the environment is correctly set up for running Advocate.

- `clean_results.sh`: Removes all generated results, including advocateResult, fuzzingTraces, and results folders within the `Examples` directory.

- `run_fuzzing.sh`: Takes as arguments the mode and folder directory of the example to be fuzzed. Usage: `./run_fuzzing.sh [Subfolder of Examples] [Fuzzing Mode]`

- `run_all_modes.sh`: Runs all available fuzzing modes on a specified. Usage: `./run_all_modes.sh [Base Example Folder] [Subfolder]`
- `run_project_fuzzing.sh`: Detects test functions within large projects.

All three `run_` scripts are interactive. They first take in the arguments for project / example directory (and fuzz mode) and then give the user a choice by number input which of the detected test functions should be executed.

---------------------------------------------------------------------------------------------------------


## Setup Advocate & Execute Samples

### Install Advocate

#### Prerequisites
- Linux OS or WSL
- Go Version 1.24.1

--- 

#### Step 1: Update System

```bash
sudo apt update
sudo apt upgrade
```

---

#### Step 2: Install Go 1.24.1
```bash
cd ~/Downloads 
curl -LO https://go.dev/dl/go1.24.1.linux-amd64.tar.gz
tar -xzf go1.24.1.linux-amd64.tar.gz
mkdir -p ~/Tools
mv go ~/Tools/go-runtime
```

---

#### Step 3: Set Go Environment
```bash
export GOROOT=$HOME/Tools/go-runtime
export PATH=$GOROOT/bin:$PATH
source ~/.bashrc 
```

---

#### 4. Verify Version
```bash
go version  # go version go1.24.2 linux/amd64
which go    # /home/USER/Tools/go-runtime/bin/go
```

---

#### 5. Clone & Build Advocate
```bash
# Clone git
git clone https://github.com/ErikKassubek/ADVOCATE.git
cd ADVOCATE

# Build patched go runtime (using ~/Tools/go-runtime Go 1.24.1)
# Patch version lives in /home/USER/Projects/Go_Fuzzing_Concurrency/ADVOCATE/go-patch/bin/go
cd go-patch/src
./make.bash

# Add to path
export PATH=$HOME/Projects/Go_Fuzzing_Concurrency/ADVOCATE/go-patch/bin:$PATH

# (To Remove)
# export PATH=$(echo $PATH | sed -e "s|$HOME/Projects/Go_Fuzzing_Concurrency/ADVOCATE/go-patch/bin:||") 

# Build CLI
cd ../../advocate
go build
```

---


#### 6. Test Advocate Sample
Run in /ADVOCATE/advocate:
```bash
./advocate fuzzing \
-path ~/Projects/Go_Fuzzing_Concurrency/ADVOCATE/examples/deadlocks/ \
-exec TestBasicLockdep \
-fuzzingMode GoPie \
-prog deadlock_test \
```



--------------------------------------------------------------------

## Examples

--- 

### Examples_Own

---

### Examples_AutSys

---

### Examples_Projects


---
### Mode Comparison
#### Precision: Amount of Found Bugs (+ Type)
#### Performance: Time & Efficiency 