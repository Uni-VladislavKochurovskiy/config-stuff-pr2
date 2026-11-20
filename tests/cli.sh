#!/usr/bin/env bash
set -euo pipefail

binary=./bin/gravel
tmp=$(mktemp -d bin/cli.XXXXXX)
python3 tests/serve.py "$tmp/port" > "$tmp/server.log" 2>&1 &
server=$!
trap 'kill "$server" 2>/dev/null || true; wait "$server" 2>/dev/null || true; rm -rf "$tmp"' EXIT
for attempt in {1..100}; do
    test -s "$tmp/port" && break
    kill -0 "$server"
    sleep 0.05
done
port=$(cat "$tmp/port")
sed -e 's/^package,.*/package,root/' \
    -e "s|https://pypi.org|http://127.0.0.1:$port|" \
    -e "s|bin/dependencies.svg|$tmp/graph.svg|" \
    examples/config.csv > "$tmp/config.csv"
"$binary" "$tmp/config.csv" > "$tmp/actual"
printf 'SVG: %s/graph.svg\n' "$tmp" > "$tmp/expected"
diff -u "$tmp/expected" "$tmp/actual"
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
python3 - "$tmp/graph.svg" <<'CHECK'
import sys
import xml.etree.ElementTree as tree

root = tree.parse(sys.argv[1]).getroot()
assert root.tag == "{http://www.w3.org/2000/svg}svg"
titles = {node.text for node in root.iter("{http://www.w3.org/2000/svg}title")}
assert {"root", "child", "root->child"} <= titles
CHECK
for name in missing invalid mismatch; do
    sed "s/package,root/package,$name/" "$tmp/config.csv" > "$tmp/error.csv"
    if "$binary" "$tmp/error.csv" > "$tmp/stdout" 2> "$tmp/stderr"; then
        echo "Expected repository failure: $name" >&2
        exit 1
    fi
    test ! -s "$tmp/stdout"
    test -s "$tmp/stderr"
done
sed -e 's|examples/repository.csv|examples/graphs/diamond.csv|' \
    -e 's/package,A/package,D/' examples/test.csv > "$tmp/reverse.csv"
./bin/gravel-reverse "$tmp/reverse.csv" > "$tmp/reverse"
printf 'B\nA\nC\n' > "$tmp/expected"
diff -u "$tmp/expected" "$tmp/reverse"
mkdir "$tmp/tools"
printf '#!/bin/sh\nexit 1\n' > "$tmp/tools/dot"
chmod +x "$tmp/tools/dot"
sed "s|bin/test.svg|$tmp/preserved.svg|" examples/test.csv > "$tmp/render.csv"
printf 'preserved\n' > "$tmp/preserved.svg"
if PATH="$tmp/tools:$PATH" "$binary" "$tmp/render.csv" > "$tmp/stdout" 2> "$tmp/stderr"; then
    echo 'Expected Graphviz failure' >&2
    exit 1
fi
test "$(cat "$tmp/preserved.svg")" = preserved
test ! -s "$tmp/stdout"
test -s "$tmp/stderr"
printf 'CLI tests passed\n'
