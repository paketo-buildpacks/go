package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, req *http.Request) {
		fmt.Fprint(w, "Hello world!")
	})

	log.Fatal(http.ListenAndServe(":"+os.Getenv("PORT"), nil))
}
