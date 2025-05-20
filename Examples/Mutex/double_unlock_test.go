package deadlock_one

import (
	"testing"
)

func TestChanOrder(t *testing.T) {
	ch := make(chan int, 1) // buffered to prevent blocking

	go func() {
		ch <- 1
	}()

	go func() {
		ch <- 2
	}()

	x := <-ch
	if x != 1 {
		t.Errorf("unexpected value: got %d, want 1", x)
	}
}
