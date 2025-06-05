package channel

import "testing"

func TestDoubleClose(t *testing.T) {
	ch := make(chan int)
	close(ch)
	close(ch) // panic: close of closed channel
}
