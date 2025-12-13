package main

import (
	"log"
	"net/http"
)

func main() {
	mux := http.NewServeMux()

	mux.HandleFunc("/hello", handleHello)
	mux.HandleFunc("/parse_heavy", handleParseHeavyJson)

	log.Println("Starting net/http server on port 3002...")
	log.Fatal(http.ListenAndServe(":3002", mux))
}













