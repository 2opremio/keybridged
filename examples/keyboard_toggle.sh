#!/usr/bin/env bash
set -euo pipefail

HOST="${HOST:-http://localhost:9876}"

# Apple keyboard toggle (consumer usage 0x01AE = 430).
curl -sS -X POST "${HOST}/pressandrelease" \
  -H "Content-Type: application/json" \
  -d '{"type":"consumer","code":430}'
