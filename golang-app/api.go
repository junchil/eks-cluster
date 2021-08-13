package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/julienschmidt/httprouter"
)

func hello() httprouter.Handle {
	return func(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
		fmt.Fprintf(w, "Hello Golang")
	}
}

func returnVersion(version string, git_commit_sha string) httprouter.Handle {
	return func(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
		env := Environment{}

		file, err := os.Open("env.json")
		if err != nil {
			log.Fatal(err)
		}
		defer file.Close()

		decoder := json.NewDecoder(file)
		err = decoder.Decode(&env)
		if err != nil {
			log.Fatal(err)
		}

		event := Event{
			Version:        version,
			Git_commit_sha: git_commit_sha,
			Service_name:   "myapplication",
			Environment:    env,
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusCreated)
		err = json.NewEncoder(w).Encode(event)
		if err != nil {
			log.Fatal(err)
		}
	}
}
