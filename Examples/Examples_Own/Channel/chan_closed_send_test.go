package channel

import "testing"

func TestSendClosed(t *testing.T) {
	ch := make(chan int)
	close(ch)
	ch <- 1 // panic: send on closed channel
}
