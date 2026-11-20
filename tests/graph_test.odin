package tests

import "../src/graph"
import "core:testing"

@(test)
depth_first :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	input, err := graph.parse("A,B\nA,C\nB,D\nC,D\nD,A\nE,\n")
	testing.expect(t, err == .None)
	source := graph.Source{test_mode = true, graph = input}
	result: graph.Graph
	result, err = graph.traverse(&source, "A", "")
	testing.expect(t, err == .None && len(result.order) == 4)
	for name, index in ([]string{"A", "B", "D", "C"}) {
		testing.expect(t, result.order[index] == name)
	}
	testing.expect(t, result.nodes["D"].dependencies[0] == "A")
	filtered, _ := graph.traverse(&source, "A", "B")
	testing.expect(t, len(filtered.nodes) == 3)
	testing.expect(t, len(filtered.nodes["A"].dependencies) == 1)
	empty, _ := graph.traverse(&source, "A", "A")
	testing.expect(t, len(empty.nodes) == 0)
	isolated, _ := graph.traverse(&source, "E", "")
	testing.expect(t, len(isolated.nodes) == 1)
	_, err = graph.traverse(&source, "Z", "")
	testing.expect(t, err == .Missing_Package)
}

@(test)
graph_input :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	for input in ([]string{"", "a,B", "A,B,C", "A,1", ",B", "A,\"bad"}) {
		_, err := graph.parse(input)
		testing.expect(t, err == .Invalid_Graph, input)
	}
	input, err := graph.parse("A,A\nA,A\n")
	testing.expect(t, err == .None)
	source := graph.Source{test_mode = true, graph = input}
	result: graph.Graph
	result, err = graph.traverse(&source, "A", "")
	testing.expect(t, err == .None && len(result.order) == 1)
	testing.expect(t, len(result.nodes["A"].dependencies) == 1)
}

@(test)
reverse_dependencies :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	input, _ := graph.parse("A,B\nA,C\nB,D\nC,D\nD,A\nE,B\nF,\n")
	result, err := graph.reverse(input, "D", "")
	testing.expect(t, err == .None && len(result.order) == 5)
	for name, index in ([]string{"D", "B", "A", "E", "C"}) {
		testing.expect(t, result.order[index] == name)
	}
	filtered, _ := graph.reverse(input, "D", "B")
	testing.expect(t, len(filtered.order) == 3)
	isolated, _ := graph.reverse(input, "F", "")
	testing.expect(t, len(isolated.order) == 1)
	_, err = graph.reverse(input, "Z", "")
	testing.expect(t, err == .Missing_Package)
}
