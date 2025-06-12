package examples_autsys

import (
	"testing"
	"time"
)

// Helper to release N tokens into a channel
func release(ch chan int, num int) {
	for i := 0; i < num; i++ {
		ch <- 1
	}
}

// santa: wakes on 9 reindeer or 3 elves, no priority enforced
func santa(deers, elves chan int) {
	nDeers, nElves := 0, 0
	for {
		select {
		case <-deers:
			nDeers++
		case <-elves:
			nElves++
		}
		if nDeers == 9 {
			// deliver toys
			nDeers = 0
			release(deers, 9)
		}
		if nElves == 3 {
			// R&D
			nElves = 0
			release(elves, 3)
		}
	}
}

// santaPrio: enforces reindeer priority over elves
func santaPrio(deers, elves chan int) {
	nDeers, nElves := 0, 0
	for {
		select {
		case <-deers:
			nDeers++
		case <-elves:
			nElves++
			// nested select to prefer deers
			select {
			case <-deers:
				nDeers++
			default:
			}
		}
		if nDeers == 9 {
			// deliver toys
			nDeers = 0
			release(deers, 9)
		}
		if nElves == 3 {
			// R&D
			nElves = 0
			release(elves, 3)
		}
	}
}

// TestSantaNoPriority runs santa without priority rule
func TestSantaNoPriority(t *testing.T) {
	// buffered channels for initial availability
	deers := make(chan int, 9)
	elves := make(chan int, 10)
	release(deers, 9)
	release(elves, 10)

	// run without priority
	go santa(deers, elves)
	// let it run and assemble groups
	time.Sleep(200 * time.Millisecond)
}

// TestSantaWithPriority runs santaPrio enforcing deer-first rule
func TestSantaWithPriority(t *testing.T) {
	deers := make(chan int, 9)
	elves := make(chan int, 10)
	release(deers, 9)
	release(elves, 10)

	go santaPrio(deers, elves)
	time.Sleep(200 * time.Millisecond)
}
