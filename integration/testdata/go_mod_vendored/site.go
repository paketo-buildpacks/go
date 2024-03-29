package main

import (
	_ "embed"
	"fmt"
	"net/http"
	"os"

	uuid "github.com/satori/go.uuid"

	"github.com/BurntSushi/toml"
)

type Config struct {
	Age int
}

//go:embed .occam-key
var s string

func main() {
	var conf Config
	if _, err := toml.Decode("whatever", &conf); err != nil {
		fmt.Println("toml library installed")
	}

	u2 := uuid.NewV4()
	fmt.Printf("UUIDv4: %s\n", u2)

	http.HandleFunc("/", hello)
	fmt.Println("listening...")

	port := "8080"
	if systemPort := os.Getenv("PORT"); systemPort != "" {
		port = systemPort
	}

	if err := http.ListenAndServe(":"+port, nil); err != nil {
		panic(err)
	}
}

func hello(res http.ResponseWriter, req *http.Request) {
	fmt.Fprint(res, "Hello, World!")
}
