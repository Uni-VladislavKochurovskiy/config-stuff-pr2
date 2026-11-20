#!/usr/bin/env bash
set -euo pipefail

tmp=$(mktemp -d bin/reverse.XXXXXX)
trap 'rm -rf "$tmp"' EXIT
for name in diamond cycle self isolated; do
    target=A
    if test "$name" = diamond; then target=D; fi
    sed -e "s|examples/repository.csv|examples/graphs/$name.csv|" \
        -e "s/package,A/package,$target/" examples/test.csv > "$tmp/config.csv"
    printf '\n%s, reverse dependencies of %s:\n' "$name" "$target"
    ./bin/gravel-reverse "$tmp/config.csv"
done
