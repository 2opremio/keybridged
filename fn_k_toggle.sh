#!/bin/bash

# Test Apple Fn modifier (shows 'k' if Fn is not honored).
# On iPadOS, Fn+K should toggle the on-screen keyboard.
curl -s -X POST "http://localhost:8080/pressandrelease" \
  -H "Content-Type: application/json" \
  -d '{"type":"keyboard","code":14,"modifiers":{"apple_fn":true}}'
