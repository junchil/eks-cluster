package api

type Event struct {
	Service_name   string `json:"service_name"`
	Version        string `json:"version"`
	Git_commit_sha string `json:"git_commit_sha"`
	Environment    *Environment
}

type Environment struct {
	Service_port string `json:"service_port"`
	Log_level    string `json:"log_level"`
}

type Eventmodel interface {
	CreateEvent(string, string, string, *Environment) *Event
	GetEvent() *Event
}

type Service struct {
	event Eventmodel
}
