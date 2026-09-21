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
require_tools "exiftool:libimage-exiftool-perl"

# Converts DNG files to JPG by extracting the embedded full-size preview JPEG
# (exiftool), then runs
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

# ----------------------- Tid og fremdrift ----------------------------
# Sekunder -> HH:MM:SS
fmt_tid() {
    local t="$1"
    printf '%02d:%02d:%02d' $((t / 3600)) $(((t % 3600) / 60)) $((t % 60))
}

# Fremdriftstag: [faerdige/total | tid gaaet | ETA] ud fra hvornaar trinnet startede.
# Brug: progress_tag <faerdige (>=1)> <total> <trin-start i $SECONDS>
progress_tag() {
    local i="$1" total="$2" start="$3" elapsed eta
    elapsed=$((SECONDS - start))
    eta=$((elapsed * (total - i) / i))
    printf '[%d/%d | %s | ETA %s]' "$i" "$total" "$(fmt_tid "$elapsed")" "$(fmt_tid "$eta")"
}

TOTAL_START=$SECONDS
# ---------------------------------------------------------------------

# ----------------------- Konfiguration -------------------------------
SLET_DNG_EFTER=0   # 1 = slet DNG-originalen efter vellykket konvertering
# ---------------------------------------------------------------------

echo "=== Step 0: Converting DNG to JPG (embedded full-size preview) ==="
step_start=$SECONDS

# Find alle DNG-filer i den aktuelle mappe (uanset store/smaa bogstaver)
shopt -s nullglob nocaseglob
DNG_FILER=( *.dng )
shopt -u nullglob nocaseglob

# DNG-filer der skal placeres efter dato-sorteringen i Step 1
DNG_TIL_PLACERING=()

n_dng=${#DNG_FILER[@]}
n_dng_konverteret=0
n_dng_sprunget_over=0
n_dng_fejlet=0

if [ "$n_dng" -eq 0 ]; then
    echo "No DNG files found - skipping."
else
    echo "Found $n_dng DNG file(s)."
    i=0
    for f in "${DNG_FILER[@]}"; do
        i=$((i + 1))
        tag="$(progress_tag "$i" "$n_dng" "$step_start")"

        # Unikt navn (<navn>_DNG.jpg): filnumre gentages paa tvaers af telefoner/aar,
        # saa IMG_0020.DNG maa ikke ende som (og overskrive) en anden IMG_0020.JPG.
        jpg="${f%.*}_DNG.jpg"

        # Spring konvertering over hvis JPG allerede findes (gen-koersel)
        if [ -e "$jpg" ] || [ -e "${f%.*}_DNG.JPG" ]; then
            echo "$tag SKIPPING: JPG for $f already exists"
            n_dng_sprunget_over=$((n_dng_sprunget_over + 1))
            DNG_TIL_PLACERING+=("$f")
            continue
        fi

        echo "$tag Converting: $f -> $jpg"

        # Apple ProRAW (iPhone) kan ikke laeses af darktable 4.2 (LJPEG predictor 7),
        # saa vi tager det indlejrede JPEG-preview i fuld oploesning. Det har allerede
        # dato, kameramodel og GPS, saa Sort_photos_Dates.sh kan sortere den.
        # -m ignorerer den harmloese "Not decoding some large array(s)"-advarsel.
        if exiftool -m -b -PreviewImage "$f" > "$jpg" 2>/dev/null && [ -s "$jpg" ]; then

            exiftool '-FileModifyDate<DateTimeOriginal' -overwrite_original "$jpg" >/dev/null 2>&1 || true
            n_dng_konverteret=$((n_dng_konverteret + 1))

            if [ "$SLET_DNG_EFTER" -eq 1 ]; then
                rm -f "$f"
                echo "  Deleted DNG original: $f"
            else
                DNG_TIL_PLACERING+=("$f")
            fi
        else
            echo "  ERROR: no embedded preview in $f - leaving DNG untouched" >&2
            n_dng_fejlet=$((n_dng_fejlet + 1))
            rm -f "$jpg"
        fi
    done
fi
echo "  Step 0 done in $(fmt_tid $((SECONDS - step_start)))"

echo "=== Step 1: Sorting by date and camera model ==="
step_start=$SECONDS
bash "$SCRIPT_DIR/Sort_photos_Dates.sh"
echo "  Step 1 done in $(fmt_tid $((SECONDS - step_start)))"

echo "=== Step 1b: Placing DNG originals next to their converted JPGs ==="
step_start=$SECONDS
n_dng_placeret=0
n_dng_ikke_fundet=0
for f in "${DNG_TIL_PLACERING[@]}"; do
    [ -e "$f" ] || continue
    base="${f%.*}"

    # Find hvor Step 1 lagde den konverterede JPG (YYYY-MM-DD/CameraModel/)
    jpg_sti="$(find . -mindepth 3 -maxdepth 3 -type f -iname "${base}_DNG.jpg" -print -quit)"

    if [ -n "$jpg_sti" ]; then
        maalmappe="$(dirname "$jpg_sti")/DNG"
        mkdir -p "$maalmappe"
        mv "$f" "$maalmappe/"
        n_dng_placeret=$((n_dng_placeret + 1))
        echo "Moved $f -> $maalmappe/"
    else
        n_dng_ikke_fundet=$((n_dng_ikke_fundet + 1))
        echo "WARNING: Sorted JPG for $f not found - DNG left in place" >&2
    fi
done
echo "  Step 1b done in $(fmt_tid $((SECONDS - step_start)))"

echo "=== Step 1c: Removing _DNG/_HEIC suffix from JPG names in the final folders ==="
step_start=$SECONDS
n_omdoebt=0
n_omdoebt_optaget=0
# Nu hvor filerne ligger i deres endelige YYYY-MM-DD/CameraModel/ mappe, kan
# de midlertidige unikke navne (IMG_0020_DNG.JPG) blive til IMG_0020.JPG igen.
# Findes IMG_0020.JPG allerede i mappen, beholdes suffikset (ingen overskrivning).
# (process substitution i stedet for pipe, saa taellerne overlever loekken)
while IFS= read -r -d '' sti; do
    mappe="$(dirname "$sti")"
    navn="$(basename "$sti")"
    endelse="${navn##*.}"
    stamme="${navn%.*}"
    stamme="${stamme%_DNG}"
    stamme="${stamme%_HEIC}"
    nyt_navn="${stamme}.${endelse}"

    if [ -e "$mappe/$nyt_navn" ]; then
        n_omdoebt_optaget=$((n_omdoebt_optaget + 1))
        echo "WARNING: $mappe/$nyt_navn already exists - keeping $navn" >&2
    else
        mv "$sti" "$mappe/$nyt_navn"
        n_omdoebt=$((n_omdoebt + 1))
        echo "Renamed $navn -> $nyt_navn in $mappe/"
    fi
done < <(find . -mindepth 3 -maxdepth 3 -type f \( -iname '*_DNG.jpg' -o -iname '*_HEIC.jpg' \) -print0)
echo "  Step 1c done in $(fmt_tid $((SECONDS - step_start)))"

echo "=== Step 2: Sorting file types within each date/camera folder ==="
step_start=$SECONDS
mapfile -d '' -t MAPPER < <(find . -mindepth 2 -maxdepth 2 -type d -print0)
n_mapper=${#MAPPER[@]}
i=0
for dir in "${MAPPER[@]}"; do
    i=$((i + 1))
    echo "--- $(progress_tag "$i" "$n_mapper" "$step_start") $dir ---"
    (cd "$dir" && bash "$SCRIPT_DIR/Sort_photos_Types.sh")
done
echo "  Step 2 done in $(fmt_tid $((SECONDS - step_start)))"

echo "=== Cleaning up empty date directories ==="
find . -mindepth 1 -type d -empty -delete

echo
echo "=========================== Summary ==========================="
echo "DNG -> JPG:          $n_dng_konverteret converted, $n_dng_sprunget_over skipped (JPG existed), $n_dng_fejlet failed (of $n_dng)"
echo "DNG originals:       $n_dng_placeret placed in DNG/ folders, $n_dng_ikke_fundet left in place"
echo "JPG suffix removed:  $n_omdoebt renamed, $n_omdoebt_optaget kept suffix (name taken)"
echo "Folders sorted:      $n_mapper (date/camera folders, by file type)"
echo "Total time:          $(fmt_tid $((SECONDS - TOTAL_START)))"
echo "==============================================================="
echo "All tasks completed."
