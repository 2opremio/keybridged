#!/usr/bin/env bash
set -euo pipefail

HOST="${HOST:-http://localhost:8080}"

send_key() {
  local code="$1"
  local modifiers_json="$2"
  curl -sS -X POST "${HOST}/pressandrelease" \
    -H "Content-Type: application/json" \
    -d "{\"type\":\"keyboard\",\"code\":${code},\"modifiers\":${modifiers_json}}"
}

# "Hello world!" (each character sent separately)
send_key 11 '{"left_shift":true}'   # H
send_key 8  '{}'                    # e
send_key 15 '{}'                    # l
send_key 15 '{}'                    # l
send_key 18 '{}'                    # o
send_key 44 '{}'                    # space
send_key 26 '{}'                    # w
send_key 18 '{}'                    # o
send_key 21 '{}'                    # r
send_key 15 '{}'                    # l
send_key 7  '{}'                    # d
send_key 30 '{"left_shift":true}'   # !
