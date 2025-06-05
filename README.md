# ADVOCATE: Concurrency Bug Detection for Go

ADVOCATE is a toolset for analyzing, fuzzing, recording, and replaying concurrency bugs in Go programs. The original Git Repository can be found [here](https://github.com/ErikKassubek/ADVOCATE).

This project aims to test the three different fuzzing modes with specific samples of Go Concurrency Primitives.

---

## Install Advocate
### Prerequisites
- Linux OS or WSL
- Go Version 1.24.1

### Step 1: Update System

```bash
sudo apt update
sudo apt upgrade
```


### Step 2: Install Go 1.24.1
```bash
cd ~/Downloads 
curl -LO https://go.dev/dl/go1.24.1.linux-amd64.tar.gz
tar -xzf go1.24.1.linux-amd64.tar.gz
mkdir -p ~/Tools
mv go ~/Tools/go-runtime
```


### Step 3: Set Go Environment
```bash
export GOROOT=$HOME/Tools/go-runtime
export PATH=$GOROOT/bin:$PATH
source ~/.bashrc
```


### 4. Verify Version
```bash
go version  # go version go1.24.2 linux/amd64
which go    # /home/USER/Tools/go-runtime/bin/go
```

### 5. Clone & Build Advocate
```bash
# Clone git
git clone https://github.com/ErikKassubek/ADVOCATE.git
cd ADVOCATE

# Build patched go runtime (using ~/Tools/go-runtime Go 1.24.1)
# Patch version now lives in /home/ilian/Projects/Go_Fuzzing_Concurrency/ADVOCATE/go-patch/bin/go
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


### 6. Test Sample
Run in /ADVOCATE/advocate:
```bash
./advocate fuzzing \
-path ~/Projects/Go_Fuzzing_Concurrency/ADVOCATE/examples/deadlocks/ \
-exec TestBasicLockdep \
-fuzzingMode GoPie \
-prog deadlock_test \
```

```bash
./advocate fuzzing \
-path ~/Projects/Go_Fuzzing_Concurrency/Examples/Mutex/ \
-exec TestChanOrder \
-fuzzingMode GoPie \
-prog deadlock_test \
```

# Advocate Fuzzing Modes

This section explains the different fuzzing modes provided by Advocate, and the types of concurrency issues each is best suited to uncover. For each mode, relevant example folders are provided to help with testing and experimentation.

## Overview

| Mode       | Best For                                                              | Examples Folder        |
|------------|-----------------------------------------------------------------------|------------------------|
| **GFuzz**  | Non-deterministic `select` cases, especially those rarely taken       | `Channels/`, `GFuzz/` |
| **GoPie**  | Reordering basic synchronization primitives like mutexes or channels  | `Mutex/`, `Channels/` |
| **GoPie+** | Everything GoPie does + atomic operations + stricter replay           | `Atomic/`, `RealWorld/` |
| **GoPieHB**| Same as GoPie+ but uses HB (Happens-Before) to skip invalid schedules | All folders (optimization) |
| **Flow**   | Order-sensitive identical operations where one succeeds, one fails    | `Flow/`, `RealWorld/` |

---

## Details

### GFuzz
- **What it does:** Forces uncommon `select` branches to execute.
- **Good for:** Revealing bugs hidden by biased or non-deterministic execution.
- **Example scenario:** A `select` with a `default` and a channel receive — the receive path may contain a hidden bug that’s rarely triggered.

---

### GoPie
- **What it does:** Mutates the scheduling order of mutexes and channels (e.g., which goroutine locks first).
- **Good for:** Bugs depending on the precise interleaving of synchronization primitives.
- **Example scenario:** Two goroutines attempting to lock the same `sync.Mutex` — error appears only under a certain locking sequence.

---

### GoPie+
- **What it does:** 
  - Builds on GoPie by enforcing **precise replay** up to mutation point.
  - Adds support for **atomic operations** (e.g., `sync/atomic`).
- **Good for:** Finding bugs caused by low-level atomic orderings and subtle concurrency issues.

---

### GoPieHB
- **What it does:** 
  - Adds **Happens-Before (HB)** analysis to GoPie+.
  - Skips redundant or **impossible schedules**, speeding up fuzzing.
- **Good for:** Efficient analysis of complex concurrency bugs.

---

### Flow
- **What it does:** Swaps the order of **two identical operations** (e.g., two `Once.Do`, two `Lock()`).
  - Focuses on **succeed/fail interaction pairs**.
- **Good for:** Spotting misused primitives like `sync.Once`, `Mutex`, or buffered/unbuffered channels.
- **Example scenario:** Two `Once.Do()` calls — both attempt to initialize, but only one should succeed.

---

## Examples
- Autonome Systeme
- Go Primitve Beispiele
- Go Projects

- Comparison Bug Found and Type Log
- Comparison Time Log+