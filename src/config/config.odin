package config

import "core:encoding/csv"
import "core:os"
import "core:path/filepath"
import "core:strings"

Config :: struct {
	package_name: string,
	repository:   string,
	test_mode:    bool,
	output_file:  string,
	ascii_tree:   bool,
	filter:       string,
}

KEYS :: [6]string{"package", "repository", "test_mode", "output_file", "ascii_tree", "filter"}

load :: proc(path: string) -> (Config, Error) {
	data, err := os.read_entire_file(path, context.allocator)
	if err != nil do return {}, .Config_Read
	defer delete(data)
	return parse(string(data))
}

parse :: proc(input: string) -> (Config, Error) {
	rows, err := csv.read_all_from_string(input)
	if err != nil {
		return {}, .Invalid_CSV
	}
	values := make(map[string]string)
	for row in rows {
		if len(row) != 2 {
			return {}, .Invalid_Field_Count
		}
		key := strings.trim_space(row[0])
		known := false
		for candidate in KEYS {
			known = known || key == candidate
		}
		if !known {
			return {}, .Unknown_Parameter
		}
		if _, exists := values[key]; exists {
			return {}, .Duplicate_Parameter
		}
		values[key] = strings.clone(strings.trim_space(row[1]))
	}
	for key in KEYS {
		if _, exists := values[key]; !exists {
			return {}, .Missing_Parameter
		}
	}
	if values["test_mode"] != "true" && values["test_mode"] != "false" {
		return {}, .Invalid_Test_Mode
	}
	if values["ascii_tree"] != "true" && values["ascii_tree"] != "false" {
		return {}, .Invalid_ASCII_Tree
	}
	cfg := Config {
		package_name = values["package"],
		repository   = values["repository"],
		test_mode    = values["test_mode"] == "true",
		output_file  = values["output_file"],
		ascii_tree   = values["ascii_tree"] == "true",
		filter       = values["filter"],
	}
	return cfg, validate(cfg)
}

is_alnum :: proc(c: rune) -> bool {
	return c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c >= '0' && c <= '9'
}

valid_package :: proc(name: string, test_mode: bool) -> bool {
	if len(name) == 0 {return false}
	for c in name {
		if test_mode {
			if c < 'A' || c > 'Z' {return false}
		} else if !is_alnum(c) && c != '-' && c != '_' && c != '.' {
			return false
		}
	}
	return test_mode || is_alnum(rune(name[0])) && is_alnum(rune(name[len(name) - 1]))
}

valid_url :: proc(url: string) -> bool {
	rest: string
	if strings.has_prefix(url, "https://") {
		rest = url[8:]
	} else if strings.has_prefix(url, "http://") {
		rest = url[7:]
	} else {
		return false
	}
	for c in url {
		if c <= ' ' || c == 127 || c == '\\' {
			return false
		}
	}
	end := strings.index_any(rest, "/?#")
	authority := rest
	if end >= 0 {authority = rest[:end]}
	if len(authority) == 0 || strings.contains_any(authority, "@?#") {
		return false
	}
	host := authority
	if colon := strings.index_byte(authority, ':'); colon >= 0 {
		host = authority[:colon]
		port := authority[colon + 1:]
		if len(port) == 0 || len(port) > 5 {
			return false
		}
		number := 0
		for c in port {
			if c < '0' || c > '9' {
				return false
			}
			number = number * 10 + int(c - '0')
		}
		if number < 1 || number > 65535 {
			return false
		}
	}
	if len(host) == 0 {return false}
	for label in strings.split_iterator(&host, ".") {
		if len(label) == 0 || label[0] == '-' || label[len(label) - 1] == '-' {return false}
		for c in label {
			if !is_alnum(c) && c != '-' {return false}
		}
	}
	return true
}

validate :: proc(cfg: Config) -> Error {
	if !valid_package(cfg.package_name, cfg.test_mode) {
		return .Invalid_Package
	}
	if cfg.test_mode {
		if !os.is_file(cfg.repository) {return .Repository_Not_File}
		data, err := os.read_entire_file(cfg.repository, context.allocator)
		if err != nil {return .Repository_Read}
		delete(data)
	} else if !valid_url(cfg.repository) {
		return .Invalid_URL
	}
	if !strings.has_suffix(cfg.output_file, ".svg") || filepath.base(cfg.output_file) == ".svg" {
		return .Invalid_Output_Extension
	}
	for c in cfg.output_file {
		if c < ' ' || c == 127 {return .Invalid_Output_Characters}
	}
	if !os.is_dir(filepath.dir(cfg.output_file)) || os.is_dir(cfg.output_file) {
		return .Invalid_Output_Path
	}
	for c in cfg.filter {
		if !is_alnum(c) && c != '-' && c != '_' && c != '.' {
			return .Invalid_Filter
		}
	}
	return .None
}
