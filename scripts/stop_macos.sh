#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PLIST_PATH="$HOME/Library/LaunchAgents/com.keybridged.daemon.plist"
SERVICE_DOMAIN="gui/$(id -u)"
SERVICE_ID="com.keybridged.daemon"

if launchctl list | grep -q "$SERVICE_ID"; then
    echo "Stopping service..."
    launchctl bootout "$SERVICE_DOMAIN/$SERVICE_ID" 2>/dev/null || true
    launchctl remove "$SERVICE_ID" 2>/dev/null || true
else
    echo "Service not running."
fi

if [ -f "$PLIST_PATH" ]; then
    echo "Removing plist: $PLIST_PATH"
    rm -f "$PLIST_PATH"
fi

echo "Service stopped."
