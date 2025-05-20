package deadlock_one

import (
	"testing"
	"fmt"
	"time"
)

func sndd(ch chan int) {
	var x int = 0
	x++
	ch <- x
}

func rcvv(ch chan int) {
	var x int
	x = <-ch
	fmt.Printf("received %d \n", x)

}

func TestSndRcv(t *testing.T) {
	var ch chan int = make(chan int)
	go rcvv(ch) // R1
	go sndd(ch) // S1
	time.Sleep(1 * time.Second) // trying to provoke deadlock
	rcvv(ch)    // R2
}
