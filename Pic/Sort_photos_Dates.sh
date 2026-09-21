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
require_tools "heif-convert:libheif-examples" "exiftool:libimage-exiftool-perl"

# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

# Capture date (YYYY-MM-DD) of a file, read from its own metadata.
# Videos use Keys:CreationDate (local time, matches the photo's EXIF date for
# Live Photos) and fall back to QuickTime:CreateDate (UTC). Everything else
# uses EXIF:CreateDate. Prints nothing if the file has no date.
file_date() {
    local f="$1" d
    case "${f##*.}" in
        MOV|MP4|mov|mp4)
            d=$(exiftool -b -n -s -M -Keys:CreationDate "$f" 2>/dev/null)
            [ -z "$d" ] && d=$(exiftool -b -n -s -M -QuickTime:CreateDate "$f" 2>/dev/null)
            ;;
        *)
            d=$(exiftool -b -n -s -M -EXIF:createdate "$f" 2>/dev/null)
            ;;
    esac
    echo "$d" | cut -d' ' -f1 | tr ':' '-'
}

# Move a file into a folder without ever overwriting an existing file there.
move_file() {
    local src="$1" dir="$2"
    if [ -e "$dir/$(basename "$src")" ]; then
        echo "Warning: $dir/$(basename "$src") already exists – $src left in place"
        return 1
    fi
    mv "$src" "$dir/"
}

# Format seconds as HH:MM:SS
fmt_tid() {
    local t="$1"
    printf '%02d:%02d:%02d' $((t / 3600)) $(((t % 3600) / 60)) $((t % 60))
}

# Progress tag: [done/total | elapsed | ETA], based on when the step started.
# Usage: progress_tag <done (>=1)> <total> <step start in $SECONDS>
progress_tag() {
    local i="$1" total="$2" start="$3" elapsed eta
    elapsed=$((SECONDS - start))
    eta=$((elapsed * (total - i) / i))
    printf '[%d/%d | %s | ETA %s]' "$i" "$total" "$(fmt_tid "$elapsed")" "$(fmt_tid "$eta")"
}

SCRIPT_START=$SECONDS
n_renamed=0            # extensions changed to uppercase
n_heic_converted=0     # HEIC -> JPG conversions done
n_heic_reused=0        # HEIC whose same-date JPG already existed
n_heic_failed=0        # heif-convert errors
n_photos_sorted=0      # JPG/JPEG/PNG sorted into date/camera folders
n_videos_sorted=0      # MOV/MP4 sorted on their own (Step 5)
n_files_moved=0        # all files moved (photos + related + videos)
n_no_metadata=0        # skipped: camera model or date missing
n_date_mismatch=0      # related files left because of another capture date
n_move_problems=0      # not moved: name already taken / mv failed

# ─────────────────────────────────────────────
# STEP 2: Normalize file extensions to uppercase
#         Only processes: JPG, JPEG, PNG, MOV, HEIC, MP4, CR2
# ─────────────────────────────────────────────
for f in *.jpg *.jpeg *.png *.mov *.heic *.mp4 *.cr2 \
          *.JPG *.JPEG *.PNG *.MOV *.HEIC *.MP4 *.CR2; do
    [ -e "$f" ] || continue
    ext="${f##*.}"
    base="${f%.*}"
    upper_ext=$(echo "$ext" | tr 'a-z' 'A-Z')
    if [ "$ext" != "$upper_ext" ]; then
        mv "$f" "${base}.${upper_ext}"
        n_renamed=$((n_renamed + 1))
        echo "Renamed $f → ${base}.${upper_ext}"
    fi
done

# ─────────────────────────────────────────────
# STEP 3: Convert HEIC to JPEG
# ─────────────────────────────────────────────
# Different photos often share the same file number (IMG_0020.HEIC and
# IMG_0020.JPG from different phones/years). If a JPG with the same name
# already exists it is only reused when it has the same capture date (= same
# photo); otherwise the converted file gets the unique name <name>_HEIC.JPG so
# the existing JPG is never overwritten.
shopt -s nullglob
heic_files=( *.HEIC )
shopt -u nullglob
n_heic=${#heic_files[@]}
[ "$n_heic" -gt 0 ] && echo "=== Converting $n_heic HEIC file(s) to JPG ==="
step_start=$SECONDS
i=0
for f in "${heic_files[@]}"; do
    i=$((i + 1))
    [ -e "$f" ] || continue
    base="${f%.HEIC}"
    out="${base}.JPG"
    if [ -e "$out" ] || [ -e "${base}.JPEG" ]; then
        existing="$out"; [ -e "$existing" ] || existing="${base}.JPEG"
        heicDate=$(file_date "$f")
        if [ -n "$heicDate" ] && [ "$heicDate" = "$(file_date "$existing")" ]; then
            n_heic_reused=$((n_heic_reused + 1))
            echo "$(progress_tag "$i" "$n_heic" "$step_start") Skipping: $existing already exists (same capture date as $f)"
            continue
        fi
        out="${base}_HEIC.JPG"
    fi
    # heif-convert prints a long "decoding image... x%" line per file; only show
    # its output if the conversion fails.
    if heif_out=$(heif-convert -q 100 "$f" "$out" 2>&1); then
        n_heic_converted=$((n_heic_converted + 1))
        echo "$(progress_tag "$i" "$n_heic" "$step_start") Converted $f → $out"
    else
        n_heic_failed=$((n_heic_failed + 1))
        echo "Error: heif-convert failed for $f:" >&2
        echo "$heif_out" >&2
    fi
done

# Normalize again – heif-convert outputs lowercase .jpg
for f in *.jpg *.jpeg; do
    [ -e "$f" ] || continue
    ext="${f##*.}"
    base="${f%.*}"
    upper_ext=$(echo "$ext" | tr 'a-z' 'A-Z')
    if [ "$ext" != "$upper_ext" ]; then
        mv "$f" "${base}.${upper_ext}"
        n_renamed=$((n_renamed + 1))
        echo "Renamed $f → ${base}.${upper_ext}"
    fi
done

# ─────────────────────────────────────────────
# STEP 4: Sort all JPG/JPEG/PNG + related files
#         into date/camera folder structure
# ─────────────────────────────────────────────
shopt -s nocaseglob nullglob
photo_files=( *.JPG *.JPEG *.PNG )
shopt -u nullglob
n_photos=${#photo_files[@]}
[ "$n_photos" -gt 0 ] && echo "=== Sorting $n_photos photo(s) into date/camera folders ==="
step_start=$SECONDS
i=0

for filename in "${photo_files[@]}"; do
    i=$((i + 1))
    [ -e "$filename" ] || continue

    # Strip extension to get base name
    baseFilename=$(basename "$filename" .JPG)
    baseFilename=$(basename "$baseFilename" .JPEG)
    baseFilename=$(basename "$baseFilename" .PNG)

    # Extract camera model from EXIF (replace non-alphanumeric with _)
    cameraModel=$(exiftool -b -n -s -M -EXIF:Model "$filename" \
        | tr -d '[:space:]' \
        | sed 's/[^a-zA-Z0-9]/_/g')

    # Extract creation date (YYYY-MM-DD)
    creationDate=$(exiftool -b -n -s -M -EXIF:createdate "$filename" \
        | cut -d' ' -f1 | tr ':' '-')

    if [ -z "$cameraModel" ] || [ -z "$creationDate" ]; then
        n_no_metadata=$((n_no_metadata + 1))
        echo "$(progress_tag "$i" "$n_photos" "$step_start") Warning: Could not extract metadata from $filename – skipping"
        continue
    fi

    targetDir="${creationDate}/${cameraModel}"
    mkdir -p "$targetDir"

    # Move the image itself
    if move_file "$filename" "$targetDir"; then
        n_photos_sorted=$((n_photos_sorted + 1))
        n_files_moved=$((n_files_moved + 1))
        echo "$(progress_tag "$i" "$n_photos" "$step_start") Moved $filename → $targetDir/"
    else
        n_move_problems=$((n_move_problems + 1))
        echo "Error: Failed to move $filename"
    fi

    # Also move related files with the same base name (MOV, HEIC, ...), but only
    # if their own capture date matches – same file number on another day is a
    # different photo. Files named <name>_DNG / <name>_HEIC belong to <name>.
    relBase="${baseFilename%_DNG}"
    relBase="${relBase%_HEIC}"
    for ext in JPG JPEG PNG MOV HEIC MP4 CR2; do
        related="${relBase}.${ext}"
        [ "$related" = "$filename" ] && continue
        [ -e "$related" ] || continue

        relDate=$(file_date "$related")
        if [ "$relDate" != "$creationDate" ]; then
            n_date_mismatch=$((n_date_mismatch + 1))
            echo "Skipping $related: capture date '${relDate:-none}' differs from $filename ($creationDate)"
            continue
        fi

        if move_file "$related" "$targetDir"; then
            n_files_moved=$((n_files_moved + 1))
            echo "Moved $related → $targetDir/"
        else
            n_move_problems=$((n_move_problems + 1))
            echo "Error: Failed to move $related"
        fi
    done
done

shopt -u nocaseglob

# ─────────────────────────────────────────────
# STEP 5: Sort remaining MOV and MP4 files
#         (those not paired with a photo of the same capture date in Step 4)
#         (PNG is already handled as its own anchor in Step 4)
# ─────────────────────────────────────────────
shopt -s nullglob
video_files=( *.MOV *.MP4 )
shopt -u nullglob
n_videos=${#video_files[@]}
[ "$n_videos" -gt 0 ] && echo "=== Sorting $n_videos remaining video(s) ==="
step_start=$SECONDS
i=0

for filename in "${video_files[@]}"; do
    i=$((i + 1))
    [ -e "$filename" ] || continue

    # Read metadata from video via QuickTime
    cameraModel=$(exiftool -b -n -s -M -QuickTime:Model "$filename" \
        | tr -d '[:space:]' \
        | sed 's/[^a-zA-Z0-9]/_/g')

    # Fallback to Make if Model is empty
    if [ -z "$cameraModel" ]; then
        cameraModel=$(exiftool -b -n -s -M -QuickTime:Make "$filename" \
            | tr -d '[:space:]' \
            | sed 's/[^a-zA-Z0-9]/_/g')
    fi

    creationDate=$(exiftool -b -n -s -M -QuickTime:CreateDate "$filename" \
        | cut -d' ' -f1 | tr ':' '-')

    if [ -z "$cameraModel" ] || [ -z "$creationDate" ]; then
        n_no_metadata=$((n_no_metadata + 1))
        echo "$(progress_tag "$i" "$n_videos" "$step_start") Warning: Could not extract metadata from $filename – skipping"
        continue
    fi

    targetDir="${creationDate}/${cameraModel}"
    mkdir -p "$targetDir"

    if move_file "$filename" "$targetDir"; then
        n_videos_sorted=$((n_videos_sorted + 1))
        n_files_moved=$((n_files_moved + 1))
        echo "$(progress_tag "$i" "$n_videos" "$step_start") Moved $filename → $targetDir/"
    else
        n_move_problems=$((n_move_problems + 1))
        echo "Error: Failed to move $filename"
    fi
done

# ─────────────────────────────────────────────
# STEP 6: Clean up empty directories
# ─────────────────────────────────────────────
find . -mindepth 1 -type d -empty -delete

echo
echo "─── Sort_photos_Dates.sh summary ───"
echo "HEIC → JPG:      $n_heic_converted converted, $n_heic_reused reused an existing JPG, $n_heic_failed failed"
echo "Sorted:          $n_photos_sorted photo(s), $n_videos_sorted standalone video(s) ($n_files_moved files moved in total)"
echo "Not sorted:      $n_no_metadata without metadata, $n_move_problems not moved (name taken / error)"
echo "Pairing:         $n_date_mismatch same-name file(s) had another capture date (not paired, sorted on their own)"
echo "Time:            $(fmt_tid $((SECONDS - SCRIPT_START)))"
echo "All tasks completed."
