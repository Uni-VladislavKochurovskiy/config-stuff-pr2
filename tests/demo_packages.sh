#!/usr/bin/env bash
set -euo pipefail

for name in python-dateutil typing-inspection click; do
    printf '\n%s:\n' "$name"
    ./bin/gravel "examples/$name.csv"
done
