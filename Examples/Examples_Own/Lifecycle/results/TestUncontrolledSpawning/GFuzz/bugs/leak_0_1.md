# Leak: Leak on routine

The analyzer detected a leak on a routine without a blocking operations.
This means that the routine was terminated because of a panic in another routine or because the main routine terminated while this routine was still running.
This can be a desired behavior, but it can also be a signal for a not otherwise detected block.

## Test/Program
The bug was found in the following test/program:

- Test/Prog: TestUncontrolledSpawning
- File: /home/ilian/Projects/Go_Fuzzing_Concurrency/Examples/Examples_Own/Lifecycle/routine_spawn_test.go

## Bug Elements
The elements involved in the found leak are located at the following positions:

###  Routine: End
-> /home/ilian/Projects/Go_Fuzzing_Concurrency/Examples/Examples_Own/Lifecycle/routine_spawn_test.go:7
```go
-1 package lifecycle
0 
1 import "testing"
2 
3 func TestUncontrolledSpawning(t *testing.T) {
4 	for i := 0; i < 1e6; i++ {
5 		go func(i int) {
6 			_ = i * 2 // placeholder work
7 		}(i)           // <-------
8 	}
9 }
10 
```


## Replay
**Replaying was not run**.

