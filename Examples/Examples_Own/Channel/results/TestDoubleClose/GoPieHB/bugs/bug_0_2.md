# Bug: Actual Close on Closed Channel

During the execution of the program, a close on a close channel occurred.
The occurrence of a close on a closed channel lead to a panic.

## Test/Program
The bug was found in the following test/program:

- Test/Prog: TestDoubleClose
- File: /home/ilian/Projects/Go_Fuzzing_Concurrency/Examples/Examples_Own/Channel/chan_close_test.go

## Bug Elements
The elements involved in the found bug are located at the following positions:

###  Channel: Close
-> /home/ilian/Projects/Go_Fuzzing_Concurrency/Examples/Examples_Own/Channel/chan_close_test.go:7
```go
-1 package channel
0 
1 import "testing"
2 
3 func TestDoubleClose(t *testing.T) {
4 	ch := make(chan int)
5 	close(ch)
6 	close(ch) // panic: close of closed channel
7 }           // <-------
8 
```


###  Channel: Close
## Replay
**Replaying was not run**.

