#!/bin/bash

# Send Consumer Control usage 0x01AE (AL Keyboard Layout).
# This toggles the on-screen keyboard on iPadOS.
curl -s -X POST "http://localhost:8080/pressandrelease" \
  -H "Content-Type: application/json" \
  -d '{"type":"consumer","code":430}'
