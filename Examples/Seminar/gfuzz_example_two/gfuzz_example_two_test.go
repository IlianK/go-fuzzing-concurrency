package gfuzz_test

import (
	"testing"
	"sync"
)

func TestWgBug(t *testing.T) {

	var wg sync.WaitGroup
	wg.Add(1)

	wg.Wait()
}
