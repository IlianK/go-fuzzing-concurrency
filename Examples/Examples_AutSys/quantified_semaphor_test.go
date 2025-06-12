package examples_autsys

import (
	"testing"
	"time"
)

// QSem: simple quantified semaphore using two mutex-channels for blocked waits/signals.
type Mutex chan int

func newMutex() Mutex {
	m := make(chan int, 1)
	return m
}

func lock(m Mutex)   { m <- 1 }
func unlock(m Mutex) { <-m }

// QSem structure
// q: maximum units
// curr: current available units
// m: protects curr and counters
// waitSem: mutex-channel to block/wake waiters
// signalSem: mutex-channel to block/wake signallers
// blockedWaits/signals: counters of blocked threads

type QSem struct {
	q              int
	curr           int
	m              Mutex
	waitSem        Mutex
	signalSem      Mutex
	blockedWaits   int
	blockedSignals int
}

func newQSem(q int) *QSem {
	qs := &QSem{
		q:         q,
		curr:      q,
		m:         newMutex(),
		waitSem:   newMutex(),
		signalSem: newMutex(),
	}
	// both semaphores initially unavailable
	// fill their buffers to zero by empty operations
	// (newMutex returns buffered, so initial state buffer=0)
	return qs
}

func (qs *QSem) Wait() {
	lock(qs.m)
	if qs.curr > 0 {
		qs.curr--
		// if there are blocked signals, wake one
		if qs.blockedSignals > 0 {
			qs.blockedSignals--
			unlock(qs.m)
			lock(qs.signalSem)
		} else {
			unlock(qs.m)
		}
	} else {
		qs.blockedWaits++
		unlock(qs.m)
		lock(qs.waitSem)
	}
}

func (qs *QSem) Signal() {
	lock(qs.m)
	if qs.curr < qs.q {
		qs.curr++
		// if there are blocked waiters, wake one
		if qs.blockedWaits > 0 {
			qs.blockedWaits--
			unlock(qs.m)
			lock(qs.waitSem)
		} else {
			unlock(qs.m)
		}
	} else {
		qs.blockedSignals++
		unlock(qs.m)
		lock(qs.signalSem)
	}
}

// =============================
// Tests for QSem behavior
// =============================

// TestQSemBasic: two Waits block when curr==0 and two Signals wake them
func TestQSemBasic(t *testing.T) {
	qs := newQSem(1)

	// First waiter consumes the unit
	go func() { qs.Wait() }()

	// Second waiter should block
	go func() { qs.Wait() }()

	// give goroutines time to schedule and block
	time.Sleep(10 * time.Millisecond)

	// Signal twice: should wake one, then increment
	qs.Signal()
	qs.Signal()
}

// TestQSemFairness: blocked waiters are served FIFO
func TestQSemFairness(t *testing.T) {
	qs := newQSem(1)
	order := make(chan int, 2)

	// two waiters
	go func() { qs.Wait(); order <- 1 }()
	go func() { qs.Wait(); order <- 2 }()

	time.Sleep(10 * time.Millisecond)

	// one signal should wake waiter 1 first
	qs.Signal()
	time.Sleep(5 * time.Millisecond)
	// second signal wakes waiter 2
	qs.Signal()

	// collect order
	first := <-order
	second := <-order
	if first != 1 || second != 2 {
		t.Errorf("Expected FIFO wake order, got %d then %d", first, second)
	}
}

// TestQSemParallelSignal: multiple signals block when at max and then release
func TestQSemParallelSignal(t *testing.T) {
	qs := newQSem(1)

	// Two signals: first increases to 1->1 (block second)
	go func() { qs.Signal() }()
	go func() { qs.Signal() }()

	time.Sleep(10 * time.Millisecond)

	// Wait twice to allow blocked signals to proceed
	qs.Wait()
	qs.Wait()
}
