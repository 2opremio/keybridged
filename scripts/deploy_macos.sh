 #!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BINARY_PATH="$REPO_DIR/keybridged"
PLIST_PATH="$HOME/Library/LaunchAgents/com.keybridged.daemon.plist"
SERVICE_DOMAIN="gui/$(id -u)"
SERVICE_ID="com.keybridged.daemon"

echo "Building keybridged..."
cd "$REPO_DIR"
go build -o "$BINARY_PATH" ./cmd/keybridged

if [ ! -f "$BINARY_PATH" ]; then
    echo "Error: Build failed - binary not found"
    exit 1
fi

echo "Binary built successfully: $BINARY_PATH"

mkdir -p "$HOME/Library/LaunchAgents"

echo "Stopping existing service (if any)..."
"$SCRIPT_DIR/stop_macos.sh"

echo "Generating plist file at $PLIST_PATH..."
cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$SERVICE_ID</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BINARY_PATH</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$REPO_DIR</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/keybridged.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/keybridged.log</string>
</dict>
</plist>
EOF
chmod 644 "$PLIST_PATH"

echo "Loading and starting service..."
if launchctl bootstrap "$SERVICE_DOMAIN" "$PLIST_PATH"; then
    launchctl kickstart -k "$SERVICE_DOMAIN/$SERVICE_ID"
else
    echo "Bootstrap failed, trying legacy launchctl load..."
    launchctl load -w "$PLIST_PATH"
    launchctl start "$SERVICE_ID"
fi

echo "Service started successfully!"
echo ""
echo "To check status: launchctl list | grep $SERVICE_ID"
echo "To view logs: tail -f $HOME/Library/Logs/keybridged.log"
echo "To restart: ./scripts/deploy_macos.sh"

echo ""
echo "Tailing logs..."
tail -f "$HOME/Library/Logs/keybridged.log"
