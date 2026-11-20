#!/usr/bin/env bash
set -euo pipefail

mkdir -p .zed
python3 -m venv .zed/comparison-env
python=.zed/comparison-env/bin/python
"$python" -m pip install --disable-pip-version-check \
    pipdeptree==4.2.15 python-dateutil==4.0.0 typing-inspection==0.4.5 click==8.5.1 \
    > .zed/comparison-install.log 2>&1
for name in python-dateutil typing-inspection click; do
    ./bin/gravel "examples/$name.csv" > ".zed/gravel-$name.txt"
    .zed/comparison-env/bin/pipdeptree --warn silence --packages "$name" \
        --encoding ascii --output text > ".zed/pipdeptree-$name.txt"
    .zed/comparison-env/bin/pipdeptree --warn silence --packages "$name" \
        --output graphviz-svg > ".zed/pipdeptree-$name.svg"
    printf '\n%s: gravel\n' "$name"
    cat ".zed/gravel-$name.txt"
    printf '%s: pipdeptree\n' "$name"
    cat ".zed/pipdeptree-$name.txt"
done
