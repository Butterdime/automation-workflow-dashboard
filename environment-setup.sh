#!/usr/bin/env bash
# open-and-run.sh
# Opens a new Terminal window and executes the environment setup script.

SCRIPT_PATH="$(pwd)/environment-setup.sh"

# Verify the setup script exists
if [[ ! -f "$SCRIPT_PATH" ]]; then
  echo "Error: environment-setup.sh not found in $(pwd)"
  exit 1
fi

# Use AppleScript to open a new Terminal window and run the script
osascript <<EOF
tell application "Terminal"
  activate
  do script "bash \"$SCRIPT_PATH\"; exec bash"
end tell
EOF
