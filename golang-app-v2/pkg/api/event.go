package api

import (
	"github.com/spf13/viper"
	"strings"
)

func (event *Event) CreateEvent(service_name string, version string, git_commit_sha string, environment *Environment) *Event {
	event.Service_name = service_name
	event.Version = version
	event.Git_commit_sha = git_commit_sha
	event.Environment = environment
	return event
}

// GetPet handles a GET request to retrieve a pet
func (event *Event) GetEvent() *Event {
	service_name := "myapplication"
	version := "1.0.0"
	git_commit_sha := "abc57858585"

	environment := ReadEnvironment()
	event.CreateEvent(service_name, version, git_commit_sha, environment)
	return event
}

func ReadEnvironment() *Environment {
	env := &Environment{}

	v := viper.New()
	v.SetConfigName("conf")
	v.SetConfigType("toml")
	v.AddConfigPath(".")

	v.SetDefault("Service_port", "")
	v.SetDefault("Log_level", "")

	v.SetEnvPrefix("VTT")
	v.AutomaticEnv()

	err := v.ReadInConfig() // Find and read the config file
	if err != nil {
		panic(err)
	}

	env.Service_port = strings.TrimSpace(v.GetString("Service_port"))
	env.Log_level = strings.TrimSpace(v.GetString("Log_level"))
	return env
}
