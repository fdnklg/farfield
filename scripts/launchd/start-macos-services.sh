#!/bin/zsh
set -euo pipefail

USER_ID="$(id -u)"
USER_APP_PLIST="$HOME/Library/LaunchAgents/com.farfield.app.plist"
USER_AWAKE_PLIST="$HOME/Library/LaunchAgents/com.farfield.awake.plist"
SYSTEM_TUNNEL_PLIST="/Library/LaunchDaemons/com.farfield.tunnel.plist"

if [[ ! -f "$USER_APP_PLIST" || ! -f "$USER_AWAKE_PLIST" || ! -f "$SYSTEM_TUNNEL_PLIST" ]]; then
  echo "Farfield services are not fully installed yet." >&2
  echo "Run scripts/launchd/install-macos-services.sh first." >&2
  exit 1
fi

launchctl enable "gui/${USER_ID}/com.farfield.app"
launchctl kickstart -k "gui/${USER_ID}/com.farfield.app"

launchctl enable "gui/${USER_ID}/com.farfield.awake"
launchctl kickstart -k "gui/${USER_ID}/com.farfield.awake"

sudo launchctl enable system/com.farfield.tunnel
sudo launchctl kickstart -k system/com.farfield.tunnel

echo "Started services: com.farfield.app, com.farfield.awake, com.farfield.tunnel"
