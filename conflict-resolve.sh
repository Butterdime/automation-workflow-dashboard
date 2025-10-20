#!/usr/bin/env bash
# conflict-resolve.sh
# 1. Accept a single argument: path to conflicted file (relative to $HOME).
# 2. Verify the file exists; exit with error if not.
# 3. Reveal the file in Finder (open -R).
# 4. Open the file in the default GUI editor (open).
# 5. Print instructions to:
#      • Locate and remove conflict markers: <<<<<<<, =======, >>>>>>>.
#      • Save the file.
#      • Run ‘git add <file>’ and ‘git rebase --continue’.

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <path-to-conflicted-file-relative-to-HOME>"
  exit 1
fi

FILE="$HOME/$1"

if [ ! -f "$FILE" ]; then
  echo "Error: File '$FILE' does not exist."
  exit 2
fi

open -R "$FILE"
open "$FILE"

echo "=============================="
echo "Manual Conflict Resolution Steps:"
echo "1. Locate and remove all conflict markers:"
echo "   <<<<<<<, =======, >>>>>>>"
echo "2. Save the file."
echo "3. In your terminal, run:"
echo "   git add \"$FILE\""
echo "   git rebase --continue"
echo "=============================="
