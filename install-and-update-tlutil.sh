#!/usr/bin/env bash
# install-and-update-tlutil.sh
# 1. Require root.
# 2. Verify update-tlutil.sh exists.
# 3. Copy and chmod to /usr/local/bin/update-tlutil.
# 4. Launch TeX Live Utility GUI.
# 5. Run AppleScript to refresh, update tlmgr, install lm.
# 6. Run tlmgr info lm & which xelatex.
# 7. Echo “Update completed” or “Update failed”.

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

osascript <<EOF
tell application "TeX Live Utility"
  activate
  refresh
  update all
  install package "lm"
end tell
EOF

tlmgr info lm
which xelatex

if [ $? -eq 0 ]; then
  echo "Update completed"
else
  echo "Update failed"
fi
