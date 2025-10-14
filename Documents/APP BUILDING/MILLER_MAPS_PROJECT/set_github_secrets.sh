#!/usr/bin/env bash

# Script to add required GitHub Actions secrets for Butterdime/MILLER-MAP

# Prerequisites: gh CLI installed and authenticated with appropriate permissions

# Usage:
# 1. Create a .env file in the same directory with:
#    GH_PAT=your_personal_access_token
#    DOCKERHUB_USERNAME=Butterdime
#    DOCKERHUB_TOKEN=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ockerhub_token
#    FIREBASE_TOKEN=your_firebase_ci_cd_token
#    SSH_PRIVATE_KEY="-----BEGIN OPENSSH PRIVATE KEY-----\n...your key...\n-----END OPENSSH PRIVATE KEY-----"
# 2. Make this script executable: chmod +x set_github_secrets.sh
# 3. Run ./set_github_secrets.sh to launch a new terminal window that provisions all secrets.

# Determine OS for opening a new terminal
open_new_terminal() {
  local script_path="$1"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    osascript <<EOF
tell application "Terminal"
  do script "bash '$script_path'"
end tell
EOF
  elif command -v gnome-terminal &> /dev/null; then
    gnome-terminal -- bash -ic "bash '$script_path'; exec bash"
  elif command -v xterm &> /dev/null; then
    xterm -e "bash '$script_path'; bash"
  else
    echo "No supported terminal emulator found. Please run 'bash $script_path' manually."
  fi
}

# Main provisioning logic
provision_secrets() {
  set -o allexport
  source .env
  set +o allexport

  local repo="Butterdime/MILLER-MAP"

  echo "Setting GH_PAT..."
  gh secret set GH_PAT --repo "$repo" --body "$GH_PAT"

  echo "Setting DOCKERHUB_USERNAME..."
  gh secret set DOCKERHUB_USERNAME --repo "$repo" --body "$DOCKERHUB_USERNAME"

  echo "Setting DOCKERHUB_TOKEN..."
  gh secret set DOCKERHUB_TOKEN --repo "$repo" --body "$DOCKERHUB_TOKEN"

  echo "Setting FIREBASE_TOKEN..."
  gh secret set FIREBASE_TOKEN --repo "$repo" --body "$FIREBASE_TOKEN"

  echo "Setting SSH_PRIVATE_KEY..."
  gh secret set SSH_PRIVATE_KEY --repo "$repo" --body "$SSH_PRIVATE_KEY"

  echo "All required secrets have been configured successfully for $repo."
}

# Entry point
if [[ "${BASH_SOURCE[0]}" == "$(basename "$0")" ]]; then
  target_script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
  echo "Opening new terminal to provision secrets..."
  open_new_terminal "$target_script"
else
  provision_secrets
fi
