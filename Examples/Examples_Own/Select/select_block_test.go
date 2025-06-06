package selectblock

import (
	"advocate"
	"testing"
)

func TestBlockingSelect(t *testing.T) {
	// ======= Preamble Start =======
  advocate.InitTracing(600)
  defer advocate.FinishTracing()
  // ======= Preamble End =======
	ch := make(chan int)
	select {
	case <-ch: // blocks forever
	}
}
