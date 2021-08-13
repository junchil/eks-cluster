package main

import (
	"flag"
	"fmt"
	"os"
	"strings"
)

// ValidateRequiredFlags - Check that the given flags are present and fail otherwise
func ValidateRequiredFlags(required []string) {
	var missing []string
	for _, name := range required {
		flg := flag.Lookup(name)
		if flg.Value.String() == flg.DefValue {
			missing = append(missing, name)
		}
	}
	if len(missing) > 1 {
		panic(fmt.Sprintf("The following flags are required and missing: --%s\n", strings.Join(missing, ", --")))
	}
	if len(missing) > 0 {
		panic(fmt.Sprintf("flag --%s is required and missing\n", missing[0]))
	}
}

// LoadFlagsFromEnv -  initializes the command line flags with values in the environment variable.
func LoadFlagsFromEnv(envPrefix string) {
	// Load flags from environment
	flag.VisitAll(func(flg *flag.Flag) {
		envName := strings.ReplaceAll(strings.ToUpper(flg.Name), "-", "_")
		val := os.Getenv(envPrefix + "_FLAG_" + envName)
		if val != "" {
			os.Args = append(os.Args, fmt.Sprintf("--%s=%s", flg.Name, val))
		}
	})
}
