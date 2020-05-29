package main

import (
	"fmt"
	"net/http"
	"os"

	"github.com/ZiCog/shiny-thing/foo"
)

func main() {
	foo.Do()
	http.HandleFunc("/", hello)
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

func hello(res http.ResponseWriter, req *http.Request) {
	fmt.Fprintln(res, "Hello, World!")
	fmt.Fprintf(res, "PATH=%s", os.Getenv("PATH"))
}
