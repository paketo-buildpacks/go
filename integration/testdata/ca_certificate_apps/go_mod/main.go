package main

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {

	certpool, err := x509.SystemCertPool()
	if err != nil {
		log.Fatal("failed to get system certs")
	}

	cert, err := tls.LoadX509KeyPair("cert.pem", "key.pem")
	if err != nil {
		log.Fatal("failed to load keypair")
	}

	config := tls.Config{
		Certificates: []tls.Certificate{
			cert,
		},
		ClientAuth: tls.RequireAndVerifyClientCert,
		ClientCAs:  certpool,
	}

	var handler http.HandlerFunc = func(w http.ResponseWriter, req *http.Request) {
		fmt.Fprint(w, "Hello, World!")
	}

	server := http.Server{
		Addr:      ":" + os.Getenv("PORT"),
		Handler:   handler,
		TLSConfig: &config,
	}

	log.Fatal(server.ListenAndServeTLS("", ""))
}
