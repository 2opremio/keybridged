#!/usr/bin/env bash
set -euo pipefail

HOST="${HOST:-http://localhost:9876}"

curl -sS -X POST "${HOST}/pressandrelease" \
  -H "Content-Type: application/json" \
  -d '{"type":"keyboard","code":0,"modifiers":{"apple_fn":true}}'
