package channel

import "testing"
import "advocate"

func TestBufferOverflow(t *testing.T) {
	// ======= Preamble Start =======
  advocate.InitTracing(600)
  defer advocate.FinishTracing()
  // ======= Preamble End =======
	ch := make(chan int, 2)
	ch <- 1
	ch <- 2
	ch <- 3 // blocks or deadlocks (no receiver)
}
