package selectblock

import (
	"fmt"
	"testing"
	"time"
)

func TestNonDeterminism(t *testing.T) {
	ch1 := make(chan int, 1)
	ch2 := make(chan int, 1)

	ch1 <- 1
	ch2 <- 2

	for i := 0; i < 5; i++ {
		select {
		case v := <-ch1:
			fmt.Println("ch1:", v)
		case v := <-ch2:
			fmt.Println("ch2:", v)
		}
		time.Sleep(10 * time.Millisecond)
	}
}
