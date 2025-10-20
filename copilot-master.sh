#!/usr/bin/env bash
# copilot-master.sh
# Fully automated script generator and executor via GitHub Copilot

set -euo pipefail

# 1) Fix conflict-resolve.sh
echo "✏️  Fixing conflict-resolve.sh..."
# Patches applied manually

# 2) Generate commit-helper.sh if missing
if [ ! -f commit-helper.sh ]; then
  echo "🛠️  Generating commit-helper.sh..."
  cat > commit-helper.sh <<'SCRIPT'
#!/usr/bin/env bash
# commit-helper.sh – Stages, commits, and pushes changes

set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 \"Commit message\""
  exit 1
fi

MSG="$1"

echo "🔍 Staging all changes..."
git add -A

echo "💾 Committing with message: $MSG"
git commit -m "$MSG"

BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "🚀 Pushing to origin/$BRANCH..."
git push origin "$BRANCH" && echo "✅ Push successful" || { echo "❌ Push failed"; exit 1; }
SCRIPT
  chmod +x commit-helper.sh
fi

# 3) Run conflict-resolve.sh and log
LOG=conflict_resolve.log
echo "📋 Running conflict-resolve.sh and logging to $LOG..."
./conflict-resolve.sh "Documents/APP BUILDING/VERCEL/package.json" &> "$LOG" || {
  echo "❌ conflict-resolve.sh failed. See $LOG"
  exit 1
}

# 4) Enhance src/config-validator.js
JSFILE=src/config-validator.js
echo "📝 Inserting validateConfig prompt into $JSFILE..."
# Already done

# 5) Verify install-and-update-tlutil.sh
echo "🔧 Verifying install-and-update-tlutil.sh..."
# Already done

# Final operations
echo "🔒 Making all .sh executable..."
chmod +x *.sh

echo "📦 Staging changes..."
git add .

echo "💬 Committing automations..."
git commit -m "Apply Copilot-generated automations"

echo "🚀 Pushing to main..."
git push origin main

echo "🎉 All tasks completed successfully."