# Leak: Leak on routine

The analyzer detected a leak on a routine without a blocking operations.
This means that the routine was terminated because of a panic in another routine or because the main routine terminated while this routine was still running.
This can be a desired behavior, but it can also be a signal for a not otherwise detected block.

## Test/Program
The bug was found in the following test/program:

- Test/Prog: TestPanicInGoroutines
- File: /home/ilian/Projects/Go_Fuzzing_Concurrency/Examples/Examples_Own/Lifecycle/routine_panic_test.go

## Bug Elements
The elements involved in the found leak are located at the following positions:

###  Routine: End
-> /home/ilian/Projects/Go_Fuzzing_Concurrency/Examples/Examples_Own/Lifecycle/routine_panic_test.go:16
```go
5 ...
6 
7 )
8 
9 func worker(id int) {
10 	time.Sleep(10 * time.Millisecond)
11 	panic(fmt.Sprintf("goroutine %d panicked", id))
12 }
13 
14 func TestPanicInGoroutines(t *testing.T) {
15 	for i := 0; i < 5; i++ {
16 		go worker(i)           // <-------
17 	}
18 	time.Sleep(100 * time.Millisecond) // wait for panics
19 }
20 
```


## Replay
**Replaying was not run**.

