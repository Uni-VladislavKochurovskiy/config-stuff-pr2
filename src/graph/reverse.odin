package graph

import "../config"
import "../repository"
import "core:slice"

reverse :: proc(input: Graph, start, filter: string) -> (Graph, Error) {
	if _, exists := input.nodes[start]; !exists {return {}, .Missing_Package}
	inverted := Graph{nodes = make(map[string]Node)}
	for name, node in input.nodes {inverted.nodes[name] = Node{version = node.version}}
	for name, node in input.nodes {
		for dependency in node.dependencies {
			parent := inverted.nodes[dependency]
			append_unique(&parent.dependencies, name)
			inverted.nodes[dependency] = parent
		}
	}
	for _, &node in inverted.nodes {slice.sort(node.dependencies[:])}
	source := Source{test_mode = true, graph = inverted}
	return traverse(&source, start, filter)
}

build_reverse :: proc(settings: config.Config) -> (Graph, Error) {
	input: Graph
	err: Error
	start := settings.package_name
	filter := settings.filter
	if settings.test_mode {
		input, err = load(settings.repository)
	} else {
		input, err = build(settings)
		start = repository.normalize(start)
		filter = repository.normalize(filter)
		if excluded(start, filter) {return input, err}
	}
	if err != .None {return {}, err}
	return reverse(input, start, filter)
}
