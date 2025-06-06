# Leak: Leak on routine

The analyzer detected a leak on a routine without a blocking operations.
This means that the routine was terminated because of a panic in another routine or because the main routine terminated while this routine was still running.
This can be a desired behavior, but it can also be a signal for a not otherwise detected block.

## Test/Program
The bug was found in the following test/program:

- Test/Prog: TestLeak
- File: /home/ilian/Projects/Go_Fuzzing_Concurrency/Examples/Examples_Own/Lifecycle/routine_leak_test.go

## Bug Elements
The elements involved in the found leak are located at the following positions:

###  Routine: End
-> /home/ilian/Projects/Go_Fuzzing_Concurrency/Examples/Examples_Own/Lifecycle/routine_leak_test.go:11
```go
0 ...
1 
2 
3 import (
4 	"testing"
5 	"time"
6 )
7 
8 func leakyGoroutine(ch chan int) {
9 	for {
10 		select {
11 		case ch <- 1: // blocks forever if no receiver           // <-------
12 		default:
13 			time.Sleep(10 * time.Millisecond)
14 		}
15 	}
16 }
17 
18 func TestLeak(t *testing.T) {
19 	ch := make(chan int) // unbuffered, never read from
20 	go leakyGoroutine(ch)
21 
22 
23 ...
```


## Replay
**Replaying was not run**.

