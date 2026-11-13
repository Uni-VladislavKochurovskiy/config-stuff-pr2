#+feature dynamic-literals

package config

Error :: enum {
	None,
	Config_Read,
	Invalid_CSV,
	Invalid_Field_Count,
	Unknown_Parameter,
	Duplicate_Parameter,
	Missing_Parameter,
	Invalid_Test_Mode,
	Invalid_ASCII_Tree,
	Invalid_Package,
	Repository_Not_File,
	Repository_Read,
	Invalid_URL,
	Invalid_Output_Extension,
	Invalid_Output_Characters,
	Invalid_Output_Path,
	Invalid_Filter,
}

ERROR_STRING := map[Error]string {
	.None                      = "",
	.Config_Read               = "config: cannot read configuration file",
	.Invalid_CSV               = "config: invalid CSV",
	.Invalid_Field_Count       = "config: each CSV row must contain exactly two fields",
	.Unknown_Parameter         = "config: unknown parameter",
	.Duplicate_Parameter       = "config: duplicate parameter",
	.Missing_Parameter         = "config: missing required parameter",
	.Invalid_Test_Mode         = "test_mode: expected true or false",
	.Invalid_ASCII_Tree        = "ascii_tree: expected true or false",
	.Invalid_Package           = "package: expected a Python package name, or uppercase Latin letters in test mode",
	.Repository_Not_File       = "repository: expected an existing test repository file",
	.Repository_Read           = "repository: cannot read test repository",
	.Invalid_URL               = "repository: expected an HTTP(S) URL with a DNS name or IPv4 host and optional port",
	.Invalid_Output_Extension  = "output_file: expected a filename with .svg extension",
	.Invalid_Output_Characters = "output_file: control characters are not allowed",
	.Invalid_Output_Path       = "output_file: parent directory must exist and target must not be a directory",
	.Invalid_Filter            = "filter: expected a package-name substring or an empty value",
}
