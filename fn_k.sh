#!/bin/bash

# Sends Fn+K press + release.
curl -s -X POST "http://localhost:8080/pressandrelease" \
  -H "Content-Type: application/json" \
  -d '{"type":"keyboard","code":14,"modifiers":{"apple_fn":true}}'
