#!/usr/bin/env bash
set -euo pipefail

tmp=$(mktemp -d bin/graphs.XXXXXX)
trap 'rm -rf "$tmp"' EXIT
for name in diamond cycle self isolated; do
    sed "s|examples/repository.csv|examples/graphs/$name.csv|" \
        examples/test.csv > "$tmp/config.csv"
    printf '\n%s:\n' "$name"
    ./bin/gravel "$tmp/config.csv"
done
sed -e 's|examples/repository.csv|examples/graphs/diamond.csv|' \
    -e 's/^filter,$/filter,B/' examples/test.csv > "$tmp/config.csv"
printf '\nWithout B:\n'
./bin/gravel "$tmp/config.csv"
