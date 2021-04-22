#!/bin/bash
ref=$(git rev-parse --abbrev-ref HEAD)
url=$(git config --get remote.origin.url)
sha=$(git rev-parse HEAD)
cat <<EOF
{"ref":"$ref","url":"$url","sha":"$sha"}
EOF
