package main

import "config"
import "graph"
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
	dependencies: graph.Graph
	graph_error: graph.Error
	when #config(REVERSE, false) {
		dependencies, graph_error = graph.build_reverse(cfg)
	} else {
		dependencies, graph_error = graph.build(cfg)
	}
	if graph_error != .None {
		fmt.eprintln(graph.ERROR_STRING[graph_error])
		os.exit(1)
	}
	when #config(REVERSE, false) {
		for name, index in dependencies.order {
			if index != 0 {fmt.println(name)}
		}
	} else {
	for name in dependencies.order {
		node := dependencies.nodes[name]
		fmt.printf("%s:", name)
		for dependency in node.dependencies {fmt.printf(" %s", dependency)}
		fmt.println()
	}
}

}
