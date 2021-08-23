package api

import (
	"github.com/go-chi/chi"
	"github.com/go-chi/render"
	"net/http"
)

func SetupRoutes(r chi.Router, s *Service) {
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
