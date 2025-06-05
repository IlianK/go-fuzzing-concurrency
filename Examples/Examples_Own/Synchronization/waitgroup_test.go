package sysnchronization

import (
	"sync"
	"testing"
)

func TestWaitGroupMisuse(t *testing.T) {
	var wg sync.WaitGroup
	wg.Done() // panic: negative WaitGroup counter
	wg.Wait()
}
