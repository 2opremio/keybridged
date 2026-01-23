#!/bin/bash

# Sends only Apple Fn (no key) press + release.
curl -s -X POST "http://localhost:8080/pressandrelease" \
  -H "Content-Type: application/json" \
  -d '{"type":"keyboard","code":0,"modifiers":{"apple_fn":true}}'
