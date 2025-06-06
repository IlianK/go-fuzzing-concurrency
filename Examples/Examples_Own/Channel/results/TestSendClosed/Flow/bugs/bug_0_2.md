# Bug: Actual Send on Closed Channel

During the execution of the program, a send on a closed channel occurred.
The occurrence of a send on closed leads to a panic.

## Test/Program
The bug was found in the following test/program:

- Test/Prog: TestSendClosed
- File: /home/ilian/Projects/Go_Fuzzing_Concurrency/Examples/Examples_Own/Channel/chan_closed_send_test.go

## Bug Elements
The elements involved in the found bug are located at the following positions:

###  Channel: Send
-> /home/ilian/Projects/Go_Fuzzing_Concurrency/Examples/Examples_Own/Channel/chan_closed_send_test.go:8
```go
-1 package channel
0 
1 import "testing"
2 
3 func TestSendClosed(t *testing.T) {
4 	ch := make(chan int)
5 	close(ch)
6 	ch <- 1 // panic: send on closed channel
7 }
8            // <-------
```


###  Channel: Close
-> /home/ilian/Projects/Go_Fuzzing_Concurrency/Examples/Examples_Own/Channel/chan_closed_send_test.go:7
```go
-1 package channel
0 
1 import "testing"
2 
3 func TestSendClosed(t *testing.T) {
4 	ch := make(chan int)
5 	close(ch)
6 	ch <- 1 // panic: send on closed channel
7 }           // <-------
8 
```


## Replay
**Replaying was not run**.

