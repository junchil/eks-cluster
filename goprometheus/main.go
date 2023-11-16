package main

import (
	"fmt"
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	opsProcessed = promauto.NewCounter(prometheus.CounterOpts{
		Name: "hello_processed_total",
		Help: "The total number of processed calls",
	})
)

func main() {
	fmt.Println("Starting hello-world server...")
	mux := http.NewServeMux()
	mux.Handle("/metrics", promhttp.Handler())
	mux.HandleFunc("/", helloServer)
	mux.HandleFunc("/info", infoServer)

	http.ListenAndServe(":8080", mux)
}

func helloServer(w http.ResponseWriter, r *http.Request) {
	fmt.Fprint(w, "Hello world!")

	fmt.Println("increasing hello_processed_total counter")
	opsProcessed.Inc()
}

func infoServer(w http.ResponseWriter, r *http.Request) {
	fmt.Fprint(w, "info page")

	fmt.Println("increasing hello_processed_total counter")
	opsProcessed.Inc()
}
