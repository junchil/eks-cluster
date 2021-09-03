package main

import (
	"net/http"

	"flag"
	"fmt"
	"golang-app/pkg/api"

	"github.com/go-chi/chi"
	"github.com/go-chi/chi/middleware"
	log "github.com/sirupsen/logrus"
)

var (
	port int
)

func main() {
	flag.IntVar(&port, "port", 8081, "HTTP Port Number")
	flag.Parse()

	router := chi.NewRouter()
	router.Use(middleware.Logger)

	event := &api.Event{}
	service := api.NewEventService(event)

	api.SetupRoutes(router, service)
	server := &http.Server{
		Handler: router,
		Addr:    fmt.Sprintf(":%d", port),
	}

	log.Infoln("Server listening on port", port)
	log.Fatal(server.ListenAndServe())
}
