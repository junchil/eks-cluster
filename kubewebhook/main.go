package main

import (
	"bytes"
	"crypto/tls"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/sirupsen/logrus"
	admissionv1 "k8s.io/api/admission/v1"
)

//Server contains the functions handling server requests
type Server struct {
	ServerTLSConf *tls.Config
	ClientTLSConf *tls.Config
	CaPEM         []byte
}

func main() {
	setLogger()

	// setup certs
	fmt.Printf("Initializing certificates...\n")
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
		fmt.Printf("Starting localhost http server on :8080 with ca.pem endpoint\n")
		err = http.ListenAndServe("localhost:8080", handler)

		if err != nil {
			log.Fatal(err)
		}
	}()

	// start TLS server
	fmt.Printf("Starting TLS server on :8443\n")
	handler := http.NewServeMux()
	handler.HandleFunc("/webhook", s.ServeHealth)

	https := &http.Server{
		Addr:      ":8443",
		TLSConfig: serverTLSConf,
		Handler:   handler,
	}

	log.Fatal(https.ListenAndServeTLS("", ""))
}

func (s Server) getCA(w http.ResponseWriter, req *http.Request) {
	if len(s.CaPEM) == 0 {
		fmt.Fprintf(w, "No certificate found\n")
		return
	}

	// if base64 parameter is set, return in base64 format
	req.ParseForm()
	if _, hasParam := req.Form["base64"]; hasParam {
		fmt.Fprintf(w, string(base64.StdEncoding.EncodeToString(s.CaPEM)))
		return
	}

	fmt.Fprintf(w, string(s.CaPEM))
}

// ServeHealth returns 200 when things are good
func (s Server) ServeHealth(w http.ResponseWriter, r *http.Request) {
	logrus.WithField("uri", r.RequestURI).Debug("healthy")
	fmt.Fprint(w, "OK")
}

// setLogger sets the logger using env vars, it defaults to text logs on
// debug level unless otherwise specified
func setLogger() {
	logrus.SetLevel(logrus.DebugLevel)

	lev := os.Getenv("LOG_LEVEL")
	if lev != "" {
		llev, err := logrus.ParseLevel(lev)
		if err != nil {
			logrus.Fatalf("cannot set LOG_LEVEL to %q", lev)
		}
		logrus.SetLevel(llev)
	}

	if os.Getenv("LOG_JSON") == "true" {
		logrus.SetFormatter(&logrus.JSONFormatter{})
	}
}

// parseRequest extracts an AdmissionReview from an http.Request if possible
func parseRequest(r http.Request) (*admissionv1.AdmissionReview, error) {
	if r.Header.Get("Content-Type") != "application/json" {
		return nil, fmt.Errorf("Content-Type: %q should be %q",
			r.Header.Get("Content-Type"), "application/json")
	}

	bodybuf := new(bytes.Buffer)
	bodybuf.ReadFrom(r.Body)
	body := bodybuf.Bytes()

	if len(body) == 0 {
		return nil, fmt.Errorf("admission request body is empty")
	}

	var a admissionv1.AdmissionReview

	if err := json.Unmarshal(body, &a); err != nil {
		return nil, fmt.Errorf("could not parse admission review request: %v", err)
	}

	if a.Request == nil {
		return nil, fmt.Errorf("admission review can't be used: Request field is nil")
	}

	return &a, nil
}