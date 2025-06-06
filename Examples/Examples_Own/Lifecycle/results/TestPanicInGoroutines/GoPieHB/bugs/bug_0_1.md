# Bug: Unknown Panic

The execution of the program timed out

## Test/Program
The bug was found in the following test/program:

- Test/Prog: TestPanicInGoroutines
- File: /home/ilian/Projects/Go_Fuzzing_Concurrency/Examples/Examples_Own/Lifecycle/routine_panic_test.go

## Bug Elements
The elements involved in the found bug are located at the following positions:

###  Unknown element type
-> /home/ilian/Projects/Go_Fuzzing_Concurrency/Examples/Examples_Own/Lifecycle/routine_panic_test.go:11
```go
0 ...
1 
2 
3 import (
4 	"fmt"
5 	"testing"
6 	"time"
7 )
8 
9 func worker(id int) {
10 	time.Sleep(10 * time.Millisecond)
11 	panic(fmt.Sprintf("goroutine %d panicked", id))           // <-------
12 }
13 
14 func TestPanicInGoroutines(t *testing.T) {
15 	for i := 0; i < 5; i++ {
16 		go worker(i)
17 	}
18 	time.Sleep(100 * time.Millisecond) // wait for panics
19 }
20 
```


## Replay
**Replaying was not run**.

