package lifecycle

import (
	"testing"
	"time"
)

func leakyGoroutine(ch chan int) {
	for {
		select {
		case ch <- 1: // blocks forever if no receiver
		default:
			time.Sleep(10 * time.Millisecond)
		}
	}
}

func TestLeak(t *testing.T) {
	ch := make(chan int) // unbuffered, never read from
	go leakyGoroutine(ch)

	time.Sleep(100 * time.Millisecond) // enough time for it to enter leak state
}
