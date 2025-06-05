package lifecycle

import "testing"

func TestUncontrolledSpawning(t *testing.T) {
	for i := 0; i < 1e6; i++ {
		go func(i int) {
			_ = i * 2 // placeholder work
		}(i)
	}
}
