#!/usr/bin/env bash
set -euo pipefail

binary=./bin/gravel
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

"$binary" examples/config.csv > "$tmp/actual"
cat > "$tmp/expected" <<'EXPECTED'
package=requests
repository=https://pypi.org
test_mode=false
output_file=bin/dependencies.svg
ascii_tree=false
filter=
EXPECTED
diff -u "$tmp/expected" "$tmp/actual"
"$binary" examples/test.csv > "$tmp/test"
"$binary" --help > "$tmp/help"

for case in no_args missing_file invalid_value; do
    args=()
    case "$case" in
        missing_file) args=("$tmp/missing.csv") ;;
        invalid_value)
            sed 's/ascii_tree,false/ascii_tree,yes/' examples/config.csv > "$tmp/invalid.csv"
            args=("$tmp/invalid.csv")
            ;;
    esac
    if "$binary" "${args[@]}" > "$tmp/stdout" 2> "$tmp/stderr"; then
        echo "Expected failure: $case" >&2
        exit 1
    fi
    test ! -s "$tmp/stdout"
    test -s "$tmp/stderr"
done
printf 'CLI tests passed\n'
