package sysnchronization

import (
	"sync"
	"testing"
)

func TestUnlockWithoutLock(t *testing.T) {
	var mu sync.Mutex
	mu.Unlock() // panic: unlock of unlocked mutex
}
