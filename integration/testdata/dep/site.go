package main

import (
	_ "embed"
	"flag"
	"fmt"
	"net/http"
	"os"

	"github.com/ZiCog/shiny-thing/foo"
)

// Embeds the .occam-key to make the images unique after the source is removed.
//go:embed .occam-key
var s string

func main() {
	moonPtr := flag.Bool("moon", false, "say Hello, Moon!")
	flag.Parse()

	foo.Do()

	if *moonPtr {
		http.HandleFunc("/", moon)
	} else {
		http.HandleFunc("/", world)
	}

	port := "8080"
	if os.Getenv("PORT") != "" {
		port = os.Getenv("PORT")
	}
	fmt.Println(fmt.Sprintf("listening on %s...", port))
	err := http.ListenAndServe(":"+port, nil)
	if err != nil {
		panic(err)
	}
}

func world(res http.ResponseWriter, req *http.Request) {
	fmt.Fprintln(res, "Hello, World!")
	fmt.Fprintf(res, "PATH=%s", os.Getenv("PATH"))
}

func moon(res http.ResponseWriter, req *http.Request) {
	fmt.Fprintln(res, "Hello, Moon!")
	fmt.Fprintf(res, "PATH=%s", os.Getenv("PATH"))
}
