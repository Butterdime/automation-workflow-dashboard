#!/usr/bin/env bash
# commit-helper.sh
# Task:
# 1) Accept a commit message as an argument.
# 2) Stage all modified files.
# 3) Commit with the provided message.
# 4) Push to the current branch’s remote.
# 5) Print success or failure status.
#
# Usage:
#   ./commit-helper.sh "Your commit message"

set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 \"Your commit message\""
  exit 1
fi

MSG="$1"

echo "Staging all changes..."
git add -A

echo "Committing with message: $MSG"
git commit -m "$MSG"

BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Pushing to origin/$BRANCH"
if git push origin "$BRANCH"; then
  echo "Push successful ✅"
  exit 0
else
  echo "Push failed ❌"
  exit 1
fi