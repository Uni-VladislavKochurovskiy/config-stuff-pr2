package graph

import "../config"
import "../repository"
import "core:encoding/csv"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"

Node :: struct {
	version:      string,
	dependencies: [dynamic]string,
}

Graph :: struct {
	nodes: map[string]Node,
	order: [dynamic]string,
}

Source :: struct {
	test_mode: bool,
	url:       string,
	graph:     Graph,
}

Error :: enum {
	None,
	Read,
	Invalid_Graph,
	Missing_Package,
	Fetch_Failed,
}

@(rodata)
ERROR_STRING := [Error]string {
	.None            = "",
	.Read            = "graph: cannot read test repository",
	.Invalid_Graph   = "graph: expected CSV edges with uppercase Latin package names",
	.Missing_Package = "graph: package is absent from test repository",
	.Fetch_Failed    = "graph: cannot fetch package metadata; check URL, network and package names",
}

append_unique :: proc(values: ^[dynamic]string, value: string) {
	for existing in values {
		if existing == value {return}
	}
	append(values, value)
}

parse :: proc(input: string) -> (Graph, Error) {
	rows, err := csv.read_all_from_string(input)
	if err != nil || len(rows) == 0 {return {}, .Invalid_Graph}
	result := Graph{nodes = make(map[string]Node)}
	for row in rows {
		if len(row) != 2 {return {}, .Invalid_Graph}
		parent := strings.trim_space(row[0])
		child := strings.trim_space(row[1])
		if !config.valid_package(parent, true) {return {}, .Invalid_Graph}
		if child != "" && !config.valid_package(child, true) {return {}, .Invalid_Graph}
		if _, exists := result.nodes[parent]; !exists {
			result.nodes[strings.clone(parent)] = {}
		}
		if child == "" {continue}
		if _, exists := result.nodes[child]; !exists {
			result.nodes[strings.clone(child)] = {}
		}
		node := result.nodes[parent]
		append_unique(&node.dependencies, strings.clone(child))
		result.nodes[parent] = node
	}
	for _, &node in result.nodes {slice.sort(node.dependencies[:])}
	return result, .None
}

load :: proc(path: string) -> (Graph, Error) {
	data, err := os.read_entire_file(path, context.allocator)
	if err != nil {return {}, .Read}
	defer delete(data)
	return parse(string(data))
}

get_node :: proc(source: ^Source, name: string) -> (Node, Error) {
	if source.test_mode {
		node, exists := source.graph.nodes[name]
		if !exists {return {}, .Missing_Package}
		return node, .None
	}
	metadata, err := repository.fetch(source.url, name)
	if err != .None {
		fmt.eprintf("%s: %s\n", name, repository.ERROR_STRING[err])
		return {}, .Fetch_Failed
	}
	node := Node{version = metadata.version}
	for dependency in metadata.dependencies {append_unique(&node.dependencies, dependency.name)}
	slice.sort(node.dependencies[:])
	return node, .None
}

excluded :: proc(name, filter: string) -> bool {
	return filter != "" && strings.contains(name, filter)
}

traverse :: proc(source: ^Source, start, filter: string) -> (Graph, Error) {
	result := Graph{nodes = make(map[string]Node)}
	if excluded(start, filter) {return result, .None}
	stack := make([dynamic]string)
	defer delete(stack)
	append(&stack, start)
	for len(stack) > 0 {
		name := pop(&stack)
		if _, visited := result.nodes[name]; visited {continue}
		node, err := get_node(source, name)
		if err != .None {return {}, err}
		filtered := Node{version = node.version}
		for dependency in node.dependencies {
			if !excluded(dependency, filter) {append(&filtered.dependencies, dependency)}
		}
		result.nodes[name] = filtered
		append(&result.order, name)
		for index := len(filtered.dependencies) - 1; index >= 0; index -= 1 {
			append(&stack, filtered.dependencies[index])
		}
	}
	return result, .None
}

build :: proc(settings: config.Config) -> (Graph, Error) {
	source := Source{test_mode = settings.test_mode, url = settings.repository}
	start := settings.package_name
	filter := settings.filter
	if settings.test_mode {
		err: Error
		source.graph, err = load(settings.repository)
		if err != .None {return {}, err}
		if _, exists := source.graph.nodes[start]; !exists {return {}, .Missing_Package}
	} else {
		start = repository.normalize(start)
		filter = repository.normalize(filter)
	}
	return traverse(&source, start, filter)
}
