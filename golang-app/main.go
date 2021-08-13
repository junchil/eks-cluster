package main

import (
	"flag"
	"log"
	"net/http"

	"github.com/julienschmidt/httprouter"
)

func main() {
	var (
		version        string
		git_commit_sha string
	)
	{
		flag.StringVar(&version, "version", "1.0.0", "Service version")
		flag.StringVar(&git_commit_sha, "git_commit_sha", "abc57858585", "Last commit related to this service")
	}

	// Parse flags
	LoadFlagsFromEnv("API_SERVER")
	flag.Parse()

	r := httprouter.New()

	r.GET("/info", returnVersion(version, git_commit_sha))

	err := http.ListenAndServe("0.0.0.0:8080", r)

	if err != nil {
		log.Fatal(err)
	}
}
