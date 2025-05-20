# Leak: Leak on routine with unknown cause

The analyzer detected a leak on a routine without a blocking operations.
This means that the routine was terminated because of a panic in another routine or because the main routine terminated while this routine was still running.
This can be a desired behavior, but it can also be a signal for a not otherwise detected block.

## Test/Program
The bug was found in the following test/program:

- Test/Prog: TestSndRcv
- File: /home/ilian/Projects/Go_Fuzzing_Concurrency/Examples/Seminar/deadlock_one/deadlock_one_test.go

## Bug Elements
The elements involved in the found leak are located at the following positions:

###  Routine: End
-> /home/ilian/Projects/Go_Fuzzing_Concurrency/Examples/Seminar/deadlock_one/deadlock_one_test.go:16
```go
5 ...
6 
7 
8 func snd(ch chan int) {
9 	var x int = 0
10 	x++
11 	ch <- x
12 }
13 
14 func rcv(ch chan int) {
15 	var x int
16 	x = <-ch           // <-------
17 	fmt.Printf("received %d \n", x)
18 
19 }
20 
21 func TestSndRcv(t *testing.T) {
22 	var ch chan int = make(chan int)
23 	go rcv(ch) // R1
24 	go snd(ch) // S1
25 	rcv(ch)    // R2
26 }
27 
28 ...
```


## Replay
**Replaying was not run**.

