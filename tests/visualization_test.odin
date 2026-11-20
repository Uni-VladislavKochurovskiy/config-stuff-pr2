package tests

import "../src/graph"
import "../src/visualization"
import "core:strings"
import "core:testing"

@(test)
visualization :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	input, _ := graph.parse("A,B\nA,C\nB,D\nC,D\nD,A\n")
	source := graph.Source{test_mode = true, graph = input}
	result, _ := graph.traverse(&source, "A", "")
	expected := "A\n|-- B\n|   `-- D\n|       `-- A [cycle]\n`-- C\n    `-- D [shared]\n"
	testing.expect(t, visualization.to_ascii(result) == expected)
	dot := visualization.to_dot(result)
	for edge in ([]string{`"A" -> "B"`, `"A" -> "C"`, `"B" -> "D"`, `"C" -> "D"`, `"D" -> "A"`}) {
		testing.expect(t, strings.contains(dot, edge), edge)
	}
	testing.expect(t, visualization.to_ascii({}) == "(empty graph)\n")
	testing.expect(t, visualization.to_dot({}) == "digraph dependencies {\n  rankdir=LR;\n}\n")
	testing.expect(t, visualization.quote("a\"b\\c\nd") == "\"a\\\"b\\\\c\\nd\"")
}
