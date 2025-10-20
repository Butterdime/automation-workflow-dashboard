#!/usr/bin/env bash
# install-and-update-tlutil.sh – Verified by copilot-master.sh
set -euo pipefail

# Ensure root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

if [ ! -f "update-tlutil.sh" ]; then
  echo "Error: update-tlutil.sh not found."
  exit 2
fi

cp update-tlutil.sh /usr/local/bin/update-tlutil
chmod +x /usr/local/bin/update-tlutil

open -a "TeX Live Utility"

tell_script=$(cat <<'APPLESCRIPT'
tell application "TeX Live Utility"
    activate
    refresh
    update all
    install package "lm"
end tell
APPLESCRIPT
)
osascript <<EOF
$tell_script
EOF

tlmgr info lm
which xelatex

if [ $? -eq 0 ]; then
  echo "Update completed"
else
  echo "Update failed"
fi
