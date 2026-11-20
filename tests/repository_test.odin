package tests

import "../src/repository"
import "core:testing"

@(test)
metadata :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	input := `{"info":{"name":"Some_Package","version":"1.2","requires_dist":[
		"Child.Name[extra]>=2; python_version < '3.12'", "other @ https://example.org/other.whl"]}}`
	metadata, err := repository.parse_metadata(transmute([]byte)input)
	testing.expect(t, err == .None)
	testing.expect(t, metadata.name == "some-package" && metadata.version == "1.2")
	testing.expect(t, len(metadata.dependencies) == 2)
	testing.expect(t, metadata.dependencies[0].name == "child-name")
	testing.expect(t, metadata.dependencies[1].name == "other")
	for body in ([]string{
		`{"info":{"name":"leaf","version":"1","requires_dist":null}}`,
		`{"info":{"name":"leaf","version":"1","requires_dist":[]}}`,
	}) {
		leaf, leaf_error := repository.parse_metadata(transmute([]byte)body)
		testing.expect(t, leaf_error == .None && len(leaf.dependencies) == 0)
	}
}

@(test)
metadata_errors :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	for body in ([]string{
		"{", "[]", `{}`, `{"info":{}}`,
		`{"info":{"name":"leaf","version":"1"}}`,
		`{"info":{"name":"leaf","version":"1","requires_dist":[42]}}`,
		`{"info":{"name":"leaf","version":"1","requires_dist":["???"]}}`,
	}) {
		_, err := repository.parse_metadata(transmute([]byte)body)
		testing.expect(t, err != .None, body)
	}
	for name in ([]string{"Hello...World", "Hello___World", "hello-WORLD"}) {
		testing.expect(t, repository.normalize(name) == "hello-world")
	}
}
