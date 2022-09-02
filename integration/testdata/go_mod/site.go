package main

import (
	_ "embed"
	"flag"
	"fmt"
	"net/http"
	"os"

	uuid "github.com/satori/go.uuid"

	"github.com/BurntSushi/toml"
)

//go:embed .occam-key
var s string

type Config struct {
	Age int
}

func main() {
	moonPtr := flag.Bool("moon", false, "say Hello, Moon!")
	flag.Parse()

	var conf Config
	if _, err := toml.Decode("whatever", &conf); err != nil {
		fmt.Println("toml library installed")
	}

	u2 := uuid.NewV4()
	fmt.Printf("UUIDv4: %s\n", u2)

	http.HandleFunc("/", hello(*moonPtr))
	fmt.Println("listening...")

	port := "8080"
	if systemPort := os.Getenv("PORT"); systemPort != "" {
		port = systemPort
	}

	if err := http.ListenAndServe(":"+port, nil); err != nil {
		panic(err)
	}
}

func hello(moon bool) func(res http.ResponseWriter, req *http.Request) {
	if moon {
		return func(res http.ResponseWriter, req *http.Request) {
			fmt.Fprint(res, "Hello, Moon!")
		}
	}
	return func(res http.ResponseWriter, req *http.Request) {
		fmt.Fprint(res, "Hello, World!")
	}
}
