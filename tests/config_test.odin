package tests

import "../src/config"
import "core:fmt"
import "core:strings"
import "core:testing"

VALID ::
	"package,requests\n" +
	"repository,https://pypi.org\n" +
	"test_mode,false\n" +
	"output_file,bin/graph.svg\n" +
	"ascii_tree,false\n" +
	"filter,\n"

@(test)
valid_config :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator

	cfg, err := config.parse(VALID)
	testing.expect(t, err == .None, config.ERROR_STRING[err])
	testing.expect(t, cfg.package_name == "requests")
	testing.expect(t, !cfg.test_mode && !cfg.ascii_tree && cfg.filter == "")
	quoted, _ := strings.replace_all(VALID, "package,requests", "\"package\",\"requests\"")
	_, err = config.parse(quoted)
	testing.expect(t, err == .None, config.ERROR_STRING[err])
	enabled, _ := strings.replace_all(VALID, "ascii_tree,false", "ascii_tree,true")
	cfg, err = config.parse(enabled)
	testing.expect(t, err == .None && cfg.ascii_tree)
}

@(test)
invalid_parameters :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator

	cases := [][2]string {
		{"package,requests", "package,"},
		{"package,requests", "package,bad/name"},
		{"repository,https://pypi.org", "repository,ftp://pypi.org"},
		{"repository,https://pypi.org", "repository,https:///missing"},
		{"repository,https://pypi.org", "repository,https://host:99999"},
		{"test_mode,false", "test_mode,yes"},
		{"output_file,bin/graph.svg", "output_file,graph.png"},
		{"output_file,bin/graph.svg", "output_file,/nonexistent-gravel-dir/graph.svg"},
		{"ascii_tree,false", "ascii_tree,1"},
		{"filter,", "filter,bad/name"},
	}
	for item in cases {
		input, _ := strings.replace_all(VALID, item[0], item[1])
		_, err := config.parse(input)
		testing.expect(t, err != .None, item[1])
	}
	for key in config.KEYS {
		rows := strings.split_lines(VALID)
		input := ""
		for row in rows {
			if !strings.has_prefix(row, fmt.aprintf("%s,", key)) {
				input = fmt.aprintf("%s%s\n", input, row)
			}
		}
		_, err := config.parse(input)
		testing.expect(t, err == .Missing_Parameter, key)
	}
}

@(test)
invalid_csv :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator

	cases := []string {
		"",
		"package,\"unterminated",
		VALID + "unknown,x\n",
		VALID + "package,other\n",
		"package,one,two\n",
	}
	for input in cases {
		_, err := config.parse(input)
		testing.expect(t, err != .None, input)
	}
}

@(test)
test_repository :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator

	input, _ := strings.replace_all(VALID, "package,requests", "package,A")
	input, _ = strings.replace_all(input, "test_mode,false", "test_mode,true")
	input, _ = strings.replace_all(input, "https://pypi.org", "examples/repository.csv")
	cfg, err := config.parse(input)
	testing.expect(t, err == .None && cfg.test_mode, config.ERROR_STRING[err])
	input, _ = strings.replace_all(input, "package,A", "package,a")
	_, err = config.parse(input)
	testing.expect(t, err == .Invalid_Package)
	_, err = config.load("nonexistent-gravel-config.csv")
	testing.expect(t, err == .Config_Read)
	cfg.package_name = "A"
	cfg.repository = "nonexistent-gravel-repository.csv"
	testing.expect(t, config.validate(cfg) == .Repository_Not_File)
}

@(test)
error_messages :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator

	for err in config.Error {
		message, exists := config.ERROR_STRING[err]
		testing.expect(t, exists)
		testing.expect(t, (err == .None) == (message == ""))
	}
}
