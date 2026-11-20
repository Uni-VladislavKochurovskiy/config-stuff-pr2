package main

import "config"
import "repository"
import "core:fmt"
import "core:os"

main :: proc() {
	if len(os.args) == 2 && (os.args[1] == "--help" || os.args[1] == "-h") {
		fmt.println("Usage: gravel <config.csv>")
		return
	}
	if len(os.args) != 2 {
		fmt.eprintln("Usage: gravel <config.csv>")
		os.exit(1)
	}
	cfg, err := config.load(os.args[1])
	if err != .None {
		fmt.eprintln(config.ERROR_STRING[err])
		os.exit(1)
	}
	if cfg.test_mode {
		fmt.eprintln("repository: stage 2 requires an HTTP(S) repository")
		os.exit(1)
	}
	metadata, repository_error := repository.fetch(cfg.repository, cfg.package_name)
	if repository_error != .None {
		fmt.eprintln(repository.ERROR_STRING[repository_error])
		os.exit(1)
	}
	fmt.printf("%s==%s\n", metadata.name, metadata.version)
	for dependency in metadata.dependencies {
		fmt.println(dependency.requirement)
	}
}
