package lifecycle

import (
	"fmt"
	"testing"
	"time"
)

func worker(id int) {
	time.Sleep(10 * time.Millisecond)
	panic(fmt.Sprintf("goroutine %d panicked", id))
}

func TestPanicInGoroutines(t *testing.T) {
	for i := 0; i < 5; i++ {
		go worker(i)
	}
	time.Sleep(100 * time.Millisecond) // wait for panics
}
