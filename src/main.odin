package main

import "config"
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
	fmt.printf(
		"package=%s\nrepository=%s\ntest_mode=%t\noutput_file=%s\nascii_tree=%t\nfilter=%s\n",
		cfg.package_name,
		cfg.repository,
		cfg.test_mode,
		cfg.output_file,
		cfg.ascii_tree,
		cfg.filter,
	)
}
