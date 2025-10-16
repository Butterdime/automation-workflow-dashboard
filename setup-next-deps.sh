#!/usr/bin/env bash
cd "$(dirname "$0")" || exit 1
if [ ! -f package.json ]; then
  echo "Initializing package.json…"
  npm init -y
fi
echo "Installing Next.js, React, and ReactDOM…"
npm install next react react-dom
echo "Installed versions:"
npm list next react react-dom
echo -e "\n✅ Dependencies added. Verify 'next', 'react', and 'react-dom' under \"dependencies\" in package.json."
