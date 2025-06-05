package channel

import "testing"

func TestBufferOverflow(t *testing.T) {
	ch := make(chan int, 2)
	ch <- 1
	ch <- 2
	ch <- 3 // blocks or deadlocks (no receiver)
}
