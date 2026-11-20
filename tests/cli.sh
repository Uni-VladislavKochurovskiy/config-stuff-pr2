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
sed -e 's/package,requests/package,root/' \
    -e "s|https://pypi.org|http://127.0.0.1:$port|" \
    examples/config.csv > "$tmp/config.csv"
"$binary" "$tmp/config.csv" > "$tmp/actual"
printf 'root: child\nchild:\n' > "$tmp/expected"
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
printf 'CLI tests passed\n'
