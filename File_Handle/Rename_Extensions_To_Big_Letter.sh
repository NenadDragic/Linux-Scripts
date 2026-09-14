#!/bin/bash
# --- Dependency check (auto-inserted) ---
_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
while [ "$_d" != "/" ] && [ ! -f "$_d/lib/require_tools.sh" ]; do _d="$(dirname "$_d")"; done
if [ ! -f "$_d/lib/require_tools.sh" ]; then
    echo "FEJL: Kunne ikke finde lib/require_tools.sh (delt dependency-checker)." >&2
    exit 1
fi
# shellcheck source=/dev/null
source "$_d/lib/require_tools.sh"
unset _d
require_tools rename

# Finding files in the current directory and its subdirectories whose names have lowercase file extensions and renaming them to have uppercase file extensions...

#find . -type f -iname '*.[a-z]*' -execdir rename -n 's/\.([a-z]+)/.\U$1/' {} \;
rename 'y/a-z/A-Z/' *
