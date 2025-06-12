package examples_autsys

import (
	"testing"
	"time"
)

// --------------------
// Sleeping Barber Variant II
// --------------------

// Constants for group sizes
const (
	BLONDS = 2
	REDS   = 3
)

// Barber with group formation logic
func barber(blond, red chan int) {
	seenBlonds, seenReds := 0, 0
	for {
		// if a full group ready, cut and reset
		if seenReds == REDS {
			seenReds = 0
		}
		if seenBlonds == BLONDS {
			seenBlonds = 0
		}

		// wait for next customer
		select {
		case <-blond:
			seenBlonds++
		case <-red:
			seenReds++
		}
	}
}

// Alternative barber2 using nested selects
func barber2(b, r chan int) {
	for {
		select {
		case <-b:
			select {
			case <-b:
				// processed two blonds
			default:
				b <- 1 // release blond back
			}
		case <-r:
			select {
			case <-r:
				select {
				case <-r:
					time.Sleep(100 * time.Millisecond)
				default:
					r <- 1
					r <- 1 // release two reds
				}
			default:
				r <- 1 // release red
			}
		}
	}
}

// Customer generator
func customerSimulation(ch chan int) {
	for i := 1; ; i++ {
		time.Sleep(time.Duration(time.Now().UnixNano()%5) * time.Second)
		ch <- i
	}
}

// TestSleepingBarberBasic exercises the simple barber() implementation
func TestSleepingBarberBasic(t *testing.T) {
	blond := make(chan int)
	red := make(chan int)
	go customerSimulation(blond)
	go customerSimulation(red)

	// run barber for a short period
	go barber(blond, red)
	time.Sleep(200 * time.Millisecond)
}

// TestSleepingBarberNested exercises barber2() and shows potential livelock/deadlock
func TestSleepingBarberNested(t *testing.T) {
	b := make(chan int)
	r := make(chan int)
	go customerSimulation(b)
	go customerSimulation(r)

	// run deeper variant
	go barber2(b, r)
	time.Sleep(200 * time.Millisecond)
}

// TestSleepingBarberBuffered uses buffered channels to avoid release deadlocks
func TestSleepingBarberBuffered(t *testing.T) {
	b := make(chan int, BLONDS)
	r := make(chan int, REDS)
	go customerSimulation(b)
	go customerSimulation(r)

	go barber2(b, r)
	time.Sleep(200 * time.Millisecond)
}
