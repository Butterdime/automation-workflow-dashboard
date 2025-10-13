#!/usr/bin/env bash
# open-and-run.sh
# Opens a new Terminal window and executes the environment setup script in the specified project directory.

PROJECT_DIR="/Users/puvansivanasan/Documents/APP BUILDING/automation-workflow-dashboard"
SCRIPT_PATH="$PROJECT_DIR/environment-setup.sh"

echo "Checking for environment-setup.sh in $PROJECT_DIR..."
if [[ ! -f "$SCRIPT_PATH" ]]; then
  echo "Error: environment-setup.sh not found in $PROJECT_DIR"
  exit 1
fi

echo "Opening new Terminal window to run environment-setup.sh..."
osascript <<EOF2
 tell application "Terminal"
  activate
  do script "cd '$PROJECT_DIR' && bash 'environment-setup.sh'; exec bash"
 end tell
EOF2
