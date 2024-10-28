package main

import (
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"time"
)

func main() {
	http.HandleFunc("/", randomDateHandler)
	//Probably better to pull from env but meh
	port := "8080"

	log.Printf("Server listening on port %s", port)
	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%s", port), nil))
}

func randomDateHandler(w http.ResponseWriter, r *http.Request) {
	// Seed the random number generator
	rand.Seed(time.Now().UnixNano())

	// Generate a random date within a specific range
	min := time.Date(1970, 1, 0, 0, 0, 0, 0, time.UTC).Unix()
	max := time.Date(2070, 1, 0, 0, 0, 0, 0, time.UTC).Unix()
	delta := max - min

	sec := rand.Int63n(delta) + min
	randomDate := time.Unix(sec, 0)

	// Format the date as a string
	dateString := randomDate.Format("2006-01-02")

	// Send the response
	fmt.Fprintf(w, "Random date: %s\n", dateString)
}
