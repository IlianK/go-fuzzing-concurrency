package mutexes_one

import (
	"testing"
	"fmt"
	"sync"
	//"time"
)


func TestMut(t *testing.T) {
	var group sync.WaitGroup
	var mutex1, mutex2 sync.Mutex

	group.Add(2)
	go func() {
		defer group.Done()
		//time.Sleep(1 * time.Second) //trying to prevent deadlock
		mutex1.Lock()
		fmt.Println("Routine one got lock one.")
		mutex2.Lock()
		fmt.Println("Routine one got lock two.")
		mutex2.Unlock()
		mutex1.Unlock()
	} ()

	go func() {
		defer group.Done()
		mutex2.Lock()
		fmt.Println("Routine two got lock two.")
		mutex1.Lock()
		fmt.Println("Routine two got lock one.")
		mutex1.Unlock()
		mutex2.Unlock()
	} ()
	group.Wait()
}
