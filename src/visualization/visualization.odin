package visualization

import "../graph"
import "core:fmt"
import "core:os"
import "core:strings"

Error :: enum {
	None,
	Write_DOT,
	Read_DOT,
	Render,
	Write_SVG,
}

@(rodata)
ERROR_STRING := [Error]string {
	.None      = "",
	.Write_DOT = "visualization: cannot write DOT file",
	.Read_DOT  = "visualization: cannot read DOT file",
	.Render    = "visualization: Graphviz failed; check that dot is installed",
	.Write_SVG = "visualization: cannot write SVG file",
}

quote :: proc(value: string) -> string {
	builder: strings.Builder
	strings.write_byte(&builder, '"')
	for character in value {
		switch character {
		case '"': strings.write_string(&builder, "\\\"")
		case '\\': strings.write_string(&builder, "\\\\")
		case '\n': strings.write_string(&builder, "\\n")
		case '\r': strings.write_string(&builder, "\\r")
		case: strings.write_rune(&builder, character)
		}
	}
	strings.write_byte(&builder, '"')
	return strings.to_string(builder)
}

to_dot :: proc(input: graph.Graph) -> string {
	builder: strings.Builder
	strings.write_string(&builder, "digraph dependencies {\n  rankdir=LR;\n")
	for name in input.order {
		node := input.nodes[name]
		label := name
		if node.version != "" {label = fmt.aprintf("%s\n%s", name, node.version)}
		fmt.sbprintf(&builder, "  %s [label=%s];\n", quote(name), quote(label))
		for dependency in node.dependencies {
			fmt.sbprintf(&builder, "  %s -> %s;\n", quote(name), quote(dependency))
		}
	}
	strings.write_string(&builder, "}\n")
	return strings.to_string(builder)
}

save :: proc(input: graph.Graph, output_file: string) -> Error {
	description := to_dot(input)
	defer delete(description)
	dot_file := fmt.aprintf("%s.dot", output_file[:len(output_file) - len(".svg")])
	defer delete(dot_file)
	if os.write_entire_file(dot_file, description) != nil {return .Write_DOT}
	file, err := os.open(dot_file)
	if err != nil {return .Read_DOT}
	defer os.close(file)
	command := []string{"dot", "-Tsvg"}
	state, output, errors, process_error := os.process_exec(
		{command = command, stdin = file}, context.allocator,
	)
	defer delete(output)
	defer delete(errors)
	if process_error != nil || !state.success || state.exit_code != 0 {return .Render}
	if os.write_entire_file(output_file, output) != nil {return .Write_SVG}
	return .None
}

Frame :: struct {
	name:   string,
	prefix: string,
	last:   bool,
	root:   bool,
	leave:  bool,
}

to_ascii :: proc(input: graph.Graph) -> string {
	if len(input.order) == 0 {return "(empty graph)\n"}
	builder: strings.Builder
	stack := make([dynamic]Frame)
	active := make(map[string]bool)
	visited := make(map[string]bool)
	defer delete(stack)
	defer delete(active)
	defer delete(visited)
	append(&stack, Frame{name = input.order[0], root = true})
	for len(stack) > 0 {
		frame := pop(&stack)
		if frame.leave {
			active[frame.name] = false
			continue
		}
		strings.write_string(&builder, frame.prefix)
		if !frame.root {
			strings.write_string(&builder, "`-- " if frame.last else "|-- ")
		}
		strings.write_string(&builder, frame.name)
		if active[frame.name] {
			strings.write_string(&builder, " [cycle]\n")
			continue
		}
		if visited[frame.name] {
			strings.write_string(&builder, " [shared]\n")
			continue
		}
		strings.write_byte(&builder, '\n')
		visited[frame.name] = true
		active[frame.name] = true
		append(&stack, Frame{name = frame.name, leave = true})
		prefix := frame.prefix
		if !frame.root {prefix = fmt.aprintf("%s%s", prefix, "    " if frame.last else "|   ")}
		children := input.nodes[frame.name].dependencies
		for index := len(children) - 1; index >= 0; index -= 1 {
			append(&stack, Frame{name = children[index], prefix = prefix, last = index == len(children) - 1})
		}
	}
	return strings.to_string(builder)
}
