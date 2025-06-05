package sysnchronization

import (
	"testing"
)

var counter int

func increment() {
	counter++
}

func TestRaceCondition(t *testing.T) {
	for i := 0; i < 100; i++ {
		go increment()
	}
}
