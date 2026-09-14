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
require_tools "darktable-cli:darktable" "exiftool:libimage-exiftool-perl"

# Converts DNG files to JPG in best quality (darktable-cli), then runs
# Sort_photos_Dates.sh (sort into YYYY-MM-DD/CameraModel/), places DNG
# originals in a DNG/ subfolder next to their converted JPG, then runs
# Sort_photos_Types.sh inside every resulting YYYY-MM-DD/CameraModel/
# folder (sort into ORG/MOV/MP4/CR2/HEIC).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Tjek at hjaelpescriptsene ligger ved siden af dette script ------
for hjaelpescript in Sort_photos_Dates.sh Sort_photos_Types.sh; do
    if [ ! -f "$SCRIPT_DIR/$hjaelpescript" ]; then
        echo "ERROR: $hjaelpescript not found in $SCRIPT_DIR" >&2
        echo "Sort_Total.sh must be in the same folder as Sort_photos_Dates.sh and Sort_photos_Types.sh." >&2
        echo "Run e.g.: bash ~/git/Linux-Scripts/MISC/Pic/Sort_Total.sh" >&2
        exit 1
    fi
done

# ----------------------- Konfiguration -------------------------------
JPEG_KVALITET=97   # 1-100, 95-97 er reelt visuelt tabsfrit
SLET_DNG_EFTER=0   # 1 = slet DNG-originalen efter vellykket konvertering
# ---------------------------------------------------------------------

echo "=== Step 0: Converting DNG to JPG (best quality) ==="

# Find alle DNG-filer i den aktuelle mappe (uanset store/smaa bogstaver)
shopt -s nullglob nocaseglob
DNG_FILER=( *.dng )
shopt -u nullglob nocaseglob

# DNG-filer der skal placeres efter dato-sorteringen i Step 1
DNG_TIL_PLACERING=()

if [ ${#DNG_FILER[@]} -eq 0 ]; then
    echo "No DNG files found - skipping."
else
    for f in "${DNG_FILER[@]}"; do
        jpg="${f%.*}.jpg"

        # Spring konvertering over hvis JPG allerede findes (gen-koersel)
        if [ -e "$jpg" ] || [ -e "${f%.*}.JPG" ]; then
            echo "SKIPPING: JPG for $f already exists"
            DNG_TIL_PLACERING+=("$f")
            continue
        fi

        echo "Converting: $f -> $jpg"

        # Rigtig RAW-fremkaldelse i fuld oploesning.
        # --library ':memory:' sikrer at darktables database ikke roeres.
        if darktable-cli "$f" "$jpg" \
            --core \
            --conf plugins/imageio/format/jpeg/quality="$JPEG_KVALITET" \
            --library ':memory:' >/dev/null 2>&1; then

            # Kopier EXIF (dato, kameramodel, GPS mv.) fra DNG til JPG,
            # saa Sort_photos_Dates.sh kan sortere den korrekt
            exiftool -tagsfromfile "$f" -all:all -overwrite_original "$jpg" >/dev/null
            exiftool '-FileModifyDate<DateTimeOriginal' -overwrite_original "$jpg" >/dev/null 2>&1 || true

            if [ "$SLET_DNG_EFTER" -eq 1 ]; then
                rm -f "$f"
                echo "  Deleted DNG original: $f"
            else
                DNG_TIL_PLACERING+=("$f")
            fi
        else
            echo "  ERROR converting $f - leaving DNG untouched" >&2
            rm -f "$jpg"
        fi
    done
fi

echo "=== Step 1: Sorting by date and camera model ==="
bash "$SCRIPT_DIR/Sort_photos_Dates.sh"

echo "=== Step 1b: Placing DNG originals next to their converted JPGs ==="
for f in "${DNG_TIL_PLACERING[@]}"; do
    [ -e "$f" ] || continue
    base="${f%.*}"

    # Find hvor Step 1 lagde den konverterede JPG (YYYY-MM-DD/CameraModel/)
    jpg_sti="$(find . -mindepth 3 -maxdepth 3 -type f -iname "$base.jpg" -print -quit)"

    if [ -n "$jpg_sti" ]; then
        maalmappe="$(dirname "$jpg_sti")/DNG"
        mkdir -p "$maalmappe"
        mv "$f" "$maalmappe/"
        echo "Moved $f -> $maalmappe/"
    else
        echo "WARNING: Sorted JPG for $f not found - DNG left in place" >&2
    fi
done

echo "=== Step 2: Sorting file types within each date/camera folder ==="
find . -mindepth 2 -maxdepth 2 -type d -print0 | while IFS= read -r -d '' dir; do
    echo "--- $dir ---"
    (cd "$dir" && bash "$SCRIPT_DIR/Sort_photos_Types.sh")
done

echo "=== Cleaning up empty date directories ==="
find . -mindepth 1 -type d -empty -delete

echo "All tasks completed."
