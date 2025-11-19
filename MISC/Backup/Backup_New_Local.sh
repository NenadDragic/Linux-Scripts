#!/bin/bash
set -euo pipefail

# === RSYNC BACKUP SCRIPT (FORBEDRET VERSION) ===
# Formål: Laver en daglig rsync-backup af hele systemet (/) til et NFS-share.
# Brug:    ./backup.sh          -> Kør backup
#          ./backup.sh dry-run -> Testkørsel uden ændringer

# --- KONFIGURATION ---
SOURCE_DIR="/"
DEST_BASE="/mnt/NetBackup/Debian_Laptop"

EXCLUDES=(
    "/dev"
    "/lost+found"
    "/media"
    "/mnt"
    "/opt"
    "/proc"
    "/run"
    "/snap"
    "/srv"
    "/sys"
    "/tmp"
    "/var/run"
    "/var/tmp"

   	"/boot/*"
    	"/home/nenad/.cache/*"
	"/snap/*.*"
)

# --- SLUT KONFIGURATION ---
# --- TJEK FOR ROOT ---
if [ "$EUID" -ne 0 ]; then
    echo "FEJL: Dette script skal køres som root."
    exit 1
fi

# --- TJEK FOR RSYNC ---
if ! command -v rsync &>/dev/null; then
    echo "FEJL: 'rsync' er ikke installeret."
    exit 1
fi

# --- DRY-RUN TILSTAND ---
DRY_RUN=""
if [[ "${1:-}" == "dry-run" ]]; then
    DRY_RUN="--dry-run"
    echo "--- KØRER DRY-RUN: INGEN FILER VIL BLIVE ÆNDRET ---"
fi

# --- TJEK DESTINATION ---
if [ ! -d "$DEST_BASE" ]; then
    echo "FEJL: Destinationsmappen $DEST_BASE eksisterer ikke eller er ikke monteret."
    exit 1
fi

# --- OPSÆT TID OG LOG ---
DATE=$(date +%Y-%m-%d)
DEST_PATH="$DEST_BASE/$DATE"
LOG_FILE="$DEST_PATH/rsync_backup_$DATE.log"

mkdir -p "$DEST_PATH"

# --- START LOG ---
{
    echo "=== RSYNC BACKUP START ==="
    date
    echo "Kilde:        $SOURCE_DIR"
    echo "Destination:  $DEST_PATH"
    echo "Dry-run:      ${DRY_RUN:-nej}"
    echo
} >> "$LOG_FILE"

echo "Starter rsync backup fra $SOURCE_DIR til $DEST_PATH"
echo "Log gemmes i: $LOG_FILE"

# --- RSYNC KØRSEL ---
# Bruger '--info=stats2' til at inkludere statistikker, der kan opsummeres.
rsync $DRY_RUN \
    -aHX \
    --numeric-ids \
    --delete-delay \
    --info=progress2,stats2 \
    --log-file="$LOG_FILE" \
    --prune-empty-dirs \
    --exclude-from=<(printf "%s\n" "${EXCLUDES[@]}") \
    "$SOURCE_DIR" \
    "$DEST_PATH"

# --- RESULTAT OG STATISTIK ---
rsync_exit=$?

# Afslutning i logfilen
{
    echo
    echo "=== RSYNC BACKUP SLUT: $(date) ==="
    echo
} >> "$LOG_FILE"

if [ $rsync_exit -eq 0 ]; then
    echo "--- SUCCESS ---"

    # --- EKSTRAHER OG VIS STATISTIK ---
    # Filtrer logfilen for de relevante statistiske linjer.
    # tail -n 2 sikrer, at vi får de sidste statistikker fra kørslen.
    STATS=$(grep -E 'Total transferred file size|Number of regular files transferred' "$LOG_FILE" | tail -n 2)
    
    # Uddrag værdierne. $NF (Number of Fields) er den sidste værdi på linjen.
    TOTAL_SIZE=$(echo "$STATS" | grep 'Total transferred file size' | awk '{print $NF}')
    FILE_COUNT=$(echo "$STATS" | grep 'Number of regular files transferred' | awk '{print $NF}')

    if [[ -n "$TOTAL_SIZE" && -n "$FILE_COUNT" ]]; then
        echo "✅ Backup fuldført: $DATE"
        echo "========================================="
        echo "📂 **Filer kopieret:** $FILE_COUNT"
        echo "📦 **Samlet størrelse:** $TOTAL_SIZE"
        echo "========================================="

        # Skriv statistik til logfilen for nem reference
        {
            echo "--- SAMMENFATNING ---"
            echo "Filer kopieret: $FILE_COUNT"
            echo "Samlet størrelse: $TOTAL_SIZE"
            echo "--------------------"
        } >> "$LOG_FILE"
    else
        echo "⚠️ Kunne ikke finde statistik i logfilen, men rsync meldte succes."
    fi

    echo "Se log for fuld detalje: $LOG_FILE"
    if [[ -n "$DRY_RUN" ]]; then
        echo "Bemærk: Dette var en **DRY-RUN** – ingen filer blev ændret."
    fi
else
    echo "--- FEJL ---"
    echo "rsync returnerede en fejl ($rsync_exit). Se logfilen for detaljer."
    if [[ -z "$DRY_RUN" ]]; then
        # Fjern evt. tom mappe ved fejl
        rmdir "$DEST_PATH" 2>/dev/null || true
    fi
    exit 1
fi

exit 0
