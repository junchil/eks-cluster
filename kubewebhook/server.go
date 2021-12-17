package main

import (
	"bytes"
	"crypto/tls"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net/http"
	"os"

	"github.com/junchil/eks-cluster/kubewebhook/pkg/admission"
	"github.com/sirupsen/logrus"
	admissionv1 "k8s.io/api/admission/v1"
)

//Server contains the functions handling server requests
type Server struct {
	ServerTLSConf *tls.Config
	ClientTLSConf *tls.Config
	CaPEM         []byte
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

// ServeValidatePods validates an admission request and then writes an admission
// review to `w`
func (s Server) ServeValidatePods(w http.ResponseWriter, r *http.Request) {
	logger := logrus.WithField("uri", r.RequestURI)
	logger.Debug("received validation request")

	in, err := parseRequest(*r)
	if err != nil {
		logger.Error(err)
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	adm := admission.Admitter{
		Logger:  logger,
		Request: in.Request,
	}

	out, err := adm.ValidatePodReview()
	if err != nil {
		e := fmt.Sprintf("could not generate admission response: %v", err)
		logger.Error(e)
		http.Error(w, e, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	jout, err := json.Marshal(out)
	if err != nil {
		e := fmt.Sprintf("could not parse admission response: %v", err)
		logger.Error(e)
		http.Error(w, e, http.StatusInternalServerError)
		return
	}

	logger.Debug("sending response")
	logger.Debugf("%s", jout)
	fmt.Fprintf(w, "%s", jout)
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

	fmt.Println(string(body))

	if len(body) == 0 {
		return nil, fmt.Errorf("admission request body is empty")
	}

	// https://pkg.go.dev/k8s.io/api/admission/v1#AdmissionReview
	var a admissionv1.AdmissionReview

	if err := json.Unmarshal(body, &a); err != nil {
		return nil, fmt.Errorf("could not parse admission review request: %v", err)
	}

	if a.Request == nil {
		return nil, fmt.Errorf("admission review can't be used: Request field is nil")
	}

	return &a, nil
}
