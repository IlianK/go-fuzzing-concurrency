package examples_autsys

import (
	"testing"
	"time"
)

// Helper sources for newsreader example
func reuters(ch chan string) {
	ch <- "REUTERS"
}

func bloomberg(ch chan string) {
	ch <- "BLOOMBERG"
}

// newsReaderWithThreads uses two helper goroutines to emulate select
func newsReaderWithThreads(reutersCh, bloombergCh chan string) string {
	ch := make(chan string)

	go func() { ch <- (<-reutersCh) }()
	go func() { ch <- (<-bloombergCh) }()

	x := <-ch
	return x
}

// newsReaderWithSelect uses Go's select primitive
func newsReaderWithSelect(reutersCh, bloombergCh chan string) string {
	var x string
	select {
	case x = <-reutersCh:
	case x = <-bloombergCh:
	}
	return x
}

// TestNewsReaderThreads will exercise the thread-based emulation
func TestNewsReaderThreads(t *testing.T) {
	rCh := make(chan string, 1)
	bCh := make(chan string, 1)

	// send one message each
	go reuters(rCh)
	go bloomberg(bCh)

	// two consecutive reads to expose deadlock
	_ = newsReaderWithThreads(rCh, bCh)
	time.Sleep(10 * time.Millisecond)
	_ = newsReaderWithThreads(rCh, bCh)
}

// TestNewsReaderSelect will exercise the select-based version
func TestNewsReaderSelect(t *testing.T) {
	rCh := make(chan string, 1)
	bCh := make(chan string, 1)

	go reuters(rCh)
	go bloomberg(bCh)

	// two consecutive reads via select
	_ = newsReaderWithSelect(rCh, bCh)
	time.Sleep(10 * time.Millisecond)
	_ = newsReaderWithSelect(rCh, bCh)
}
