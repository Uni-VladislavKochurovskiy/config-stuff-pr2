#!/usr/bin/env bash
set -euo pipefail

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

for key in package repository test_mode output_file ascii_tree filter; do
    case "$key" in
        package) value='bad/name' ;;
        repository) value='ftp://pypi.org' ;;
        test_mode) value='yes' ;;
        output_file) value='graph.png' ;;
        ascii_tree) value='1' ;;
        filter) value='bad/name' ;;
    esac
    sed "s|^$key,.*|$key,$value|" examples/config.csv > "$tmp/config.csv"
    printf '\nInvalid %s:\n' "$key"
    if ./bin/gravel "$tmp/config.csv"; then
        echo 'Expected validation failure' >&2
        exit 1
    fi
done
