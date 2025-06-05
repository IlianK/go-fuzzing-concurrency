package channel

import "testing"

func TestNilChan(t *testing.T) {
	var ch chan int
	go func() {
		ch <- 42 // blocks forever
	}()
}
