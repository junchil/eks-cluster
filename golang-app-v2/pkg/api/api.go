package api

import (
	"net/http"

	"github.com/go-chi/chi"
	"github.com/go-chi/render"
)

func SetupRoutes(r chi.Router, s *Service) {
	r.Get("/", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("hi golang app v2"))
	})
	r.Get("/info", s.GetEvent)
}

func NewEventService(event Eventmodel) *Service {
	return &Service{
		event: event,
	}
}

func (ps *Service) GetEvent(w http.ResponseWriter, r *http.Request) {
	render.Status(r, http.StatusOK)
	render.JSON(w, r, ps.event.GetEvent())
}
