package channel

import (
	"fmt"
	"testing"
)

func TestRecvClosed(t *testing.T) {
	ch := make(chan int)
	close(ch)
	v := <-ch
	fmt.Println("Received:", v) // zero-value receive
}
