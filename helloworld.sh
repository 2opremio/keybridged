#!/bin/bash

chars=(
  "11:1"  # H
  "8:1"   # E
  "15:1"  # L
  "15:1"  # L
  "18:1"  # O
  "44:0"  # space
  "26:1"  # W
  "18:1"  # O
  "21:1"  # R
  "15:1"  # L
  "7:1"   # D
  "30:1"  # ! (shift+1)
)

for c in "${chars[@]}"; do
  IFS=: read -r code shift <<< "$c"
  curl -s -X POST "http://localhost:8080/pressandrelease" \
    -H "Content-Type: application/json" \
    -d "{\"code\":${code},\"modifiers\":{\"left_shift\":$( [ "$shift" -eq 1 ] && echo true || echo false )}}"
  sleep 0.05
done
