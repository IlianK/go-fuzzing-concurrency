package selectblock

import (
	"testing"
)

func TestBlockingSelect(t *testing.T) {
	ch := make(chan int)
	select {
	case <-ch: // blocks forever
	}
}
