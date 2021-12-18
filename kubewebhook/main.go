package main

import (
	"log"
	"net/http"

	"github.com/sirupsen/logrus"
)

func main() {
	setLogger()

	// setup certs
	logrus.Print("Initializing certificates...\n")
	serverTLSConf, clientTLSConf, caPEM, err := certsetup()
	if err != nil {
		panic(err)
	}

	s := Server{
		ServerTLSConf: serverTLSConf,
		ClientTLSConf: clientTLSConf,
		CaPEM:         caPEM,
	}

	go func() {
		handler := http.NewServeMux()

		handler.HandleFunc("/ca.pem", s.getCA)
		logrus.Print("Starting localhost http server on :8080 with ca.pem endpoint\n")
		err = http.ListenAndServe("localhost:8080", handler)

		if err != nil {
			log.Fatal(err)
		}
	}()

	// start TLS server
	handler := http.NewServeMux()
	handler.HandleFunc("/health", s.ServeHealth)
	handler.HandleFunc("/validate-pods", s.ServeValidatePods)
	handler.HandleFunc("/mutate-pods", s.ServeMutatePods)

	https := &http.Server{
		Addr:      ":8443",
		TLSConfig: serverTLSConf,
		Handler:   handler,
	}

	logrus.Print("Listening on port 8443...")
	logrus.Fatal(https.ListenAndServeTLS("", ""))
}
