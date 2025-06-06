# Diagnostics: Actual Receive on Closed Channel

During the execution of the program, a receive on a closed channel occurred.


## Test/Program
The bug was found in the following test/program:

- Test/Prog: TestRecvClosed
- File: /home/ilian/Projects/Go_Fuzzing_Concurrency/Examples/Examples_Own/Channel/chan_closed_rcv_test.go

## Bug Elements
The elements involved in the found diagnostics are located at the following positions:

###  Channel: Receive
-> /home/ilian/Projects/Go_Fuzzing_Concurrency/Examples/Examples_Own/Channel/chan_closed_rcv_test.go:11
```go
0 ...
1 
2 
3 import (
4 	"fmt"
5 	"testing"
6 )
7 
8 func TestRecvClosed(t *testing.T) {
9 	ch := make(chan int)
10 	close(ch)
11 	v := <-ch           // <-------
12 	fmt.Println("Received:", v) // zero-value receive
13 }
14 
```


###  Channel: Close
-> /home/ilian/Projects/Go_Fuzzing_Concurrency/Examples/Examples_Own/Channel/chan_closed_rcv_test.go:10
```go
-1 ...
0 
1 package channel
2 
3 import (
4 	"fmt"
5 	"testing"
6 )
7 
8 func TestRecvClosed(t *testing.T) {
9 	ch := make(chan int)
10 	close(ch)           // <-------
11 	v := <-ch
12 	fmt.Println("Received:", v) // zero-value receive
13 }
14 
```


## Replay
**Replaying was not run**.

