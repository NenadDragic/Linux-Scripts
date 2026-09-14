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
require_tools "heif-convert:libheif-examples" rename

# Big letters in extension (using tr)
for f in *; do
    new_name=$(echo "$f" | tr 'a-z' 'A-Z')
    mv "$f" "$new_name"
done

# Convert HEIC files to JPEG and rename them
for f in *.HEIC; do
    heif-convert -q 100 "$f" "${f%.HEIC}.JPG"
done

# Big letters in extension
rename 'y/a-z/A-Z/' *
