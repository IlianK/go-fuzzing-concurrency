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

This is where concurrency analysis tools like GFuzz, GoPie and as per latest development ADVOCATE come into play. More information on the three analysis tools are explained in `Docs/Tools.md`.


---

## Project Overview
The goal of this project is to evaluate and compare the fuzzing modes of the Advocate Go tool in terms of performance and efficiency in detecting concurrency-related bugs. It also aims to analyze overlaps and distinctions in bug detection across modes, identifying whether specific bugs are more efficeintly exposed by certain modes. For example, while GFuzz, GoPie, and GoPie+ can all detect select-related bugs, Advocate's GFuzz mode is expected to perform more efficiently in these cases. 

The project structure is as follows:

```bash
├── ADVOCATE            # Cloned ADVOCATE
├── Docs				# Documentation
│ ├── Metrics.md          	# Metrics extracted & used for comparison
│ ├── Scripts.md   			# Automation Scripts
│ ├── Tools.md				# Functionality of GFuzz, GoPie, Advocate    
│ └── Setup.md   			# Verify prerequisites
├── Examples				
│ ├── Examples_Own      
│ ├── Examples_AutSys       
│ └── Examples_Projects     
├── Scripts               	# Automation scripts
├── run.sh					# Run automation scripts
├── config.yaml				# Config for run.sh
└── README.md
```


The scripts used to automate fuzzing test cases and comparing the artefacts are explained in `Docs/Scripts.md`. And the metrics extracted from the artefacts and used for comparison are explained in `Docs/Metrics.md`.

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

