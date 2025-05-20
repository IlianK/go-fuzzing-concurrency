package main

import "fmt"
import "time"
import "testing"

func philo(id int, forks chan int) {

    for {
        <-forks
        <-forks
        fmt.Printf("%d eats \n", id)
        time.Sleep(1 * 1e9)
        forks <- 1
        forks <- 1

        time.Sleep(1 * 1e9) // think

    }

}

func TestPhilo(t *testing.T) {
    var forks = make(chan int, 3)
    forks <- 1
    forks <- 1
    forks <- 1
    go philo(1, forks)
    go philo(2, forks)
    philo(3, forks)
}