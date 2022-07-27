package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	moonPtr := flag.Bool("moon", false, "say Hello, Moon!")

	flag.Parse()

	http.HandleFunc("/", func(w http.ResponseWriter, req *http.Request) {
		if *moonPtr {
			fmt.Fprint(w, "Hello, Moon!")
			return
		}
		fmt.Fprint(w, "Hello, World!")
	})

	log.Fatal(http.ListenAndServe(":"+os.Getenv("PORT"), nil))
}
