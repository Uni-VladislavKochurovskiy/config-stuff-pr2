package repository

import "../config"
import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"

Dependency :: struct {
	name:        string,
	requirement: string,
}

Package :: struct {
	name:         string,
	version:      string,
	dependencies: [dynamic]Dependency,
}

Error :: enum {
	None,
	Download,
	Invalid_Metadata,
	Invalid_Requirement,
	Name_Mismatch,
}

@(rodata)
ERROR_STRING := [Error]string {
	.None                = "",
	.Download            = "repository: download failed; check URL, package name, network and curl",
	.Invalid_Metadata    = "repository: invalid PyPI JSON metadata",
	.Invalid_Requirement = "repository: invalid dependency name in Requires-Dist",
	.Name_Mismatch       = "repository: returned package name does not match request",
}

normalize :: proc(name: string) -> string {
	result: [dynamic]byte
	separator := false
	for character in name {
		character := character
		if character == '-' || character == '_' || character == '.' {
			if !separator {append(&result, '-')}
			separator = true
		} else {
			if character >= 'A' && character <= 'Z' {character += 'a' - 'A'}
			append(&result, byte(character))
			separator = false
		}
	}
	return string(result[:])
}

parse_requirement :: proc(requirement: string) -> (Dependency, Error) {
	requirement := strings.trim_space(requirement)
	end := 0
	for character in requirement {
		if !config.is_alnum(character) && character != '.' && character != '-' && character != '_' {break}
		end += 1
	}
	name := requirement[:end]
	if !config.valid_package(name, false) {return {}, .Invalid_Requirement}
	if end < len(requirement) && !strings.contains_rune(" [(@<>=!~;\t", rune(requirement[end])) {
		return {}, .Invalid_Requirement
	}
	return {normalize(name), strings.clone(requirement)}, .None
}

parse_metadata :: proc(data: []byte) -> (Package, Error) {
	value, err := json.parse(data)
	if err != .None {return {}, .Invalid_Metadata}
	defer json.destroy_value(value)
	root, root_ok := value.(json.Object)
	if !root_ok {return {}, .Invalid_Metadata}
	info, info_ok := root["info"].(json.Object)
	if !info_ok {return {}, .Invalid_Metadata}
	name, name_ok := info["name"].(json.String)
	version, version_ok := info["version"].(json.String)
	if !name_ok || !version_ok || !config.valid_package(string(name), false) || len(version) == 0 {
		return {}, .Invalid_Metadata
	}
	result := Package{name = normalize(string(name)), version = strings.clone(string(version))}
	requires, exists := info["requires_dist"]
	if !exists {return {}, .Invalid_Metadata}
	if _, empty := requires.(json.Null); empty {return result, .None}
	dependencies, array_ok := requires.(json.Array)
	if !array_ok {return {}, .Invalid_Metadata}
	for item in dependencies {
		text, text_ok := item.(json.String)
		if !text_ok {return {}, .Invalid_Metadata}
		dependency, dependency_error := parse_requirement(string(text))
		if dependency_error != .None {return {}, dependency_error}
		append(&result.dependencies, dependency)
	}
	slice.sort_by(result.dependencies[:], proc(a, b: Dependency) -> bool {
		return a.requirement < b.requirement
	})
	return result, .None
}

fetch :: proc(base_url, name: string) -> (Package, Error) {
	name := normalize(name)
	url := fmt.aprintf("%s/pypi/%s/json", strings.trim_right(base_url, "/"), name)
	defer delete(url)
	defer delete(name)
	command := []string {
		"curl", "--disable", "--fail", "--silent", "--show-error", "--location",
		"--proto", "=http,https", "--proto-redir", "=http,https",
		"--connect-timeout", "10", "--max-time", "60", "--max-filesize", "16777216", "--url", url,
	}
	state, output, errors, err := os.process_exec({command = command}, context.allocator)
	defer delete(output)
	defer delete(errors)
	if err != nil || !state.success || state.exit_code != 0 {return {}, .Download}
	result, metadata_error := parse_metadata(output)
	if metadata_error != .None {return {}, metadata_error}
	if result.name != name {return {}, .Name_Mismatch}
	return result, .None
}
