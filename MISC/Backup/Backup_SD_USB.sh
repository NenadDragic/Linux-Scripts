#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# === RSYNC BACKUP SCRIPT v6 ===
# Læser Hostname fra Backup.cfg, kører rsync og logger lokalt,
# forsøger robust append/merge/cp til NFS-daglog og skriver status på NFS (med lokal fallback).
#
# Ændring i v6: Erstatter ustabil process substitution (>(stdbuf ...)) med synkron
# sed | tee -a pipeline, så logfilen er fuldt skrevet inden append til NFS-daglog.
# Derved undgås race condition der medførte tom/ufuldstændig logfil ved første kørsel.
#
# Brug: gem som Backup_NAS_Complete_v6.sh ; dos2unix Backup_NAS_Complete_v6.sh ; chmod +x Backup_NAS_Complete_v6.sh
# Kør som root: sudo ./Backup_NAS_Complete_v6.sh [dry-run]

# -----------------------
# Konfiguration
# -----------------------
SOURCE_DIR="/media/nenad/rootfs/"

# Find scriptdir og configfil
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
CFG_FILE="$SCRIPT_DIR/Backup_SD.cfg"
if [ ! -f "$CFG_FILE" ]; then
    CFG_FILE="/etc/Backup_SD.cfg"
fi

# Pre-flight: Tjek at cfg-filen eksisterer — ellers stop med det samme
if [ ! -f "$CFG_FILE" ]; then
    echo "FEJL: Konfigurationsfil 'Backup_SD.cfg' blev ikke fundet."
    echo "  Søgt i: $SCRIPT_DIR/Backup_SD.cfg"
    echo "  Søgt i: /etc/Backup_SD.cfg"
    echo "Opret filen ét af disse steder og sæt mindst: Hostname=<navn>"
    exit 1
fi

# Læs Hostname fra Backup.cfg og trim CR/LF/spaces
HOSTNAME_FROM_CFG=""
if [ -f "$CFG_FILE" ]; then
    HOSTNAME_FROM_CFG=$(grep -E '^Hostname=' "$CFG_FILE" | head -n1 | cut -d'=' -f2- | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
fi

if [ -z "$HOSTNAME_FROM_CFG" ]; then
    echo "FEJL: Kunne ikke finde 'Hostname=' i $CFG_FILE. Ret Backup.cfg så den indeholder 'Hostname=Debian_Laptop' (fx)."
    exit 1
fi

# DEST_BASE="/mnt/NetBackup/${HOSTNAME_FROM_CFG}"
DEST_BASE="/media/nenad/Dragic/${HOSTNAME_FROM_CFG}"

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

# -----------------------
# Root check
# -----------------------
if [ "$(id -u)" -ne 0 ]; then
    echo "FEJL: Dette script skal køres som root."
    exit 1
fi

# -----------------------
# Krævede binærer
# -----------------------
for cmd in rsync tee sed flock mktemp stat runuser cp mv; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "FEJL: Kræver '$cmd' men det er ikke installeret."
        exit 1
    fi
done

# stdbuf valgfri
USE_STDBUF=true
if ! command -v stdbuf &>/dev/null; then
    USE_STDBUF=false
fi

# DRY-RUN?
DRY_RUN=""
if [ "${1:-}" = "dry-run" ]; then
    DRY_RUN="--dry-run"
    echo "--- KØRER DRY-RUN: INGEN FILER VIL BLIVE ÆNDRET ---"
fi

# Tjek at rodmount eksisterer (bekræfter at USB-disken er monteret)
MOUNT_ROOT="/media/nenad/Dragic"
if [ ! -d "$MOUNT_ROOT" ]; then
    echo "FEJL: Mountpunkt $MOUNT_ROOT eksisterer ikke — er USB-disken monteret?"
    exit 1
fi

# Opret $DEST_BASE (hostname-mappe) automatisk hvis den mangler
if [ ! -d "$DEST_BASE" ]; then
    echo "Info: Backup-mappe $DEST_BASE mangler — opretter den nu..."
    if ! mkdir -p "$DEST_BASE"; then
        echo "FEJL: Kunne ikke oprette $DEST_BASE."
        exit 1
    fi
    echo "Info: $DEST_BASE oprettet."
fi

# -----------------------
# Tid og logfiler (skal initieres før første logging)
# -----------------------
DATE=$(date +%Y-%m-%d)
DEST_PATH="$DEST_BASE/$DATE"

# NFS logmappe: /media/nenad/Dragic/Log/<HOSTNAME>/
LOG_DIR_NFS="/media/nenad/Dragic/Log/${HOSTNAME_FROM_CFG}"
mkdir -p "$LOG_DIR_NFS" 2>/dev/null || true
LOG_FILE_NFS="$LOG_DIR_NFS/rsync_backup_$DATE.log"
STATUS_FILE_NFS="$LOG_DIR_NFS/rsync_backup_$DATE.status"

# Lokal realtime log (midlertidig)
LOG_LOCAL_DIR="/var/log/rsync_backup"
mkdir -p "$LOG_LOCAL_DIR"
LOG_LOCAL_FILE="$LOG_LOCAL_DIR/rsync_backup_${DATE}_$$.log"

# Opret dato-destinationsmappe (hvis nødvendig)
if ! mkdir -p "$DEST_PATH"; then
    echo "FEJL: Kunne ikke oprette backup-destination $DEST_PATH."
    exit 1
fi

# -----------------------
# Write exclude-file to temp in local dir to avoid /dev/fd issues and CRLF
# -----------------------
EXCLUDE_FILE=$(mktemp "$LOG_LOCAL_DIR/rsync_excludes_XXXXXX") || EXCLUDE_FILE="/tmp/rsync_excludes_$DATE.$$"
printf "%s\n" "${EXCLUDES[@]}" | tr -d '\r' > "$EXCLUDE_FILE"

# -----------------------
# Lock for at undgå samtidige runs for samme dato
# -----------------------
LOCKFILE="/var/lock/rsync_backup_${DATE}.lock"
mkdir -p /var/lock
exec 9>"$LOCKFILE"
if ! flock -n 9; then
    echo "Et andet backup-job kører allerede for dato $DATE. Afslutter."
    rm -f "$EXCLUDE_FILE" 2>/dev/null || true
    exec 9>&- || true
    exit 1
fi

# Cleanup trap (fjerner kun exclude tempfil og frigiver lås; lokal log fjernes senere ved succes)
cleanup() {
    local rc=$?
    rm -f "$EXCLUDE_FILE" 2>/dev/null || true
    flock -u 9 2>/dev/null || true
    exec 9>&- 2>/dev/null || true
    return $rc
}
trap cleanup EXIT

START_TIME=$(date '+%Y-%m-%d %H:%M:%S')

# Header til lokal log
{
    echo
    echo "========================================="
    echo "=== RSYNC BACKUP START ==="
    echo "Tidspunkt: $START_TIME"
    echo "PID: $$"
    echo "Kilde: $SOURCE_DIR"
    echo "Destination: $DEST_PATH"
    echo "Dry-run: ${DRY_RUN:-nej}"
    echo "Local log: $LOG_LOCAL_FILE"
    echo "NFS log (daglig): $LOG_FILE_NFS"
    echo "Exclude-fil: $EXCLUDE_FILE"
    echo "-----------------------------------------"
} >> "$LOG_LOCAL_FILE"

echo "Starter rsync backup fra $SOURCE_DIR til $DEST_PATH"
echo "Lokal realtime log: $LOG_LOCAL_FILE"
echo "Daglig NFS-log: $LOG_FILE_NFS (append'es når rsync er færdig)"

# -----------------------
# Build rsync cmd array
# -----------------------
RSYNC_CMD=(rsync $DRY_RUN -aHX --numeric-ids --delete-delay --info=progress2,stats2 \
    --prune-empty-dirs --exclude-from="$EXCLUDE_FILE" \
    "$SOURCE_DIR" "$DEST_PATH")

# Use stdbuf prefix if available
if $USE_STDBUF; then
    STDBUF_PREFIX=(stdbuf -oL)
else
    STDBUF_PREFIX=()
fi

# -----------------------
# Run rsync pipeline
# v6 FIX: Bruger synkron sed | tee -a i stedet for process substitution (>(stdbuf ...)).
# Process substitution er ikke synkroniseret — bash venter ikke på den er færdig,
# hvilket medførte at logfilen var tom/ufuldstændig når append til NFS kørte bagefter.
# Med sed | tee -a er alle tre kommandoer i en synkron pipeline: bash venter på dem alle.
#
# PIPESTATUS-rækkefølge: [0]=rsync [1]=sed [2]=tee
# Vi fanger stadig rsync's exit code fra PIPESTATUS[0].
#
# Midlertidigt slå errexit/pipefail fra så scriptet ikke stopper ved rsync exit 23 o.l.
# -----------------------
set +e
set +o pipefail 2>/dev/null || true

"${STDBUF_PREFIX[@]}" "${RSYNC_CMD[@]}" 2>&1 \
    | sed -u 's/\r/\n/g' \
    | tee -a "$LOG_LOCAL_FILE"

# Capture rsync exit code (index 0 i pipeline)
rsync_exit=${PIPESTATUS[0]:-1}

# Restore strict mode
set -euo pipefail

END_TIME=$(date '+%Y-%m-%d %H:%M:%S')

# Footer til lokal log
{
    echo "-----------------------------------------"
    echo "=== RSYNC BACKUP SLUT ==="
    echo "Tidspunkt: $END_TIME"
    echo "Exit-kode: $rsync_exit"
    echo "========================================="
} >> "$LOG_LOCAL_FILE"

# -----------------------
# Append local log to NFS daily log (robust fallback: append -> merge temp -> cp unique -> attempt runuser append)
# -----------------------
append_success="false"
{
    echo
    echo "----- APPENDING LOCAL LOG TO NFS LOG -----"
    echo "Tidspunkt: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Local log: $LOG_LOCAL_FILE"
    echo "NFS log: $LOG_FILE_NFS"
    echo "------------------------------------------"
} >> "$LOG_LOCAL_FILE"

# Ensure NFS log dir exists (again)
mkdir -p "$LOG_DIR_NFS" 2>/dev/null || true

# 1) Prøv enkel append
if cat "$LOG_LOCAL_FILE" >> "$LOG_FILE_NFS" 2>>"$LOG_LOCAL_FILE"; then
    append_success="true"
    echo "Local log er append'et til $LOG_FILE_NFS"
    rm -f "$LOG_LOCAL_FILE" 2>/dev/null || true
else
    echo "ADVARSEL: Append fejlede som $(whoami). Prøver atomic merge fallback..." >> "$LOG_LOCAL_FILE"

    # Diagnostic info
    {
        echo "Diagnose: permissions og mount info:"
        stat -c "Owner: %U  Group: %G  Perms: %A" "$LOG_DIR_NFS" 2>/dev/null || true
        stat -c "Logfile: %n owner=%U group=%G perms=%A" "$LOG_FILE_NFS" 2>/dev/null || true
        mount | grep "/mnt/NetBackup" || true
        dmesg | tail -n 20 || true
    } >> "$LOG_LOCAL_FILE" 2>/dev/null

    # 2) Hvis NFS-logfilen findes og er læsbar, lav en midlertidig merged fil og mv den over (atomisk)
    TMP_MERGE=""
    if TMP_MERGE="$(mktemp "$LOG_DIR_NFS/rsync_log_merge_XXXXXX" 2>/dev/null)" 2>/dev/null || TMP_MERGE="$(mktemp 2>/dev/null)"; then
        if [ -r "$LOG_FILE_NFS" ]; then
            if cat "$LOG_FILE_NFS" "$LOG_LOCAL_FILE" > "$TMP_MERGE" 2>>"$LOG_LOCAL_FILE"; then
                if mv -f "$TMP_MERGE" "$LOG_FILE_NFS" 2>>"$LOG_LOCAL_FILE"; then
                    append_success="true"
                    echo "Local log merged ind i $LOG_FILE_NFS via temp+mv"
                    rm -f "$LOG_LOCAL_FILE" 2>/dev/null || true
                else
                    echo "Fejl: mv af $TMP_MERGE -> $LOG_FILE_NFS mislykkedes" >> "$LOG_LOCAL_FILE"
                    rm -f "$TMP_MERGE" 2>/dev/null || true
                fi
            else
                echo "Fejl: concat af $LOG_FILE_NFS + $LOG_LOCAL_FILE til $TMP_MERGE mislykkedes" >> "$LOG_LOCAL_FILE"
                rm -f "$TMP_MERGE" 2>/dev/null || true
            fi
        else
            # 3) Hvis original ikke læsbar/eksisterer, som fallback prøv at kopiere (cp) direkte til daglig fil
            echo "Original NFS-log ikke læsbar eller mangler; forsøger cp (overskriver/creator)..." >> "$LOG_LOCAL_FILE"
            if cp "$LOG_LOCAL_FILE" "$LOG_FILE_NFS" 2>>"$LOG_LOCAL_FILE"; then
                append_success="true"
                echo "Local log er kopieret til $LOG_FILE_NFS (cp fallback)"
                rm -f "$LOG_LOCAL_FILE" 2>/dev/null || true
            else
                echo "Fejl: cp fallback mislykkedes" >> "$LOG_LOCAL_FILE"
            fi
        fi
    else
        echo "Kunne ikke lave tmpfile i $LOG_DIR_NFS eller /tmp; forsøger cp fallback..." >> "$LOG_LOCAL_FILE"
        if cp "$LOG_LOCAL_FILE" "$LOG_FILE_NFS" 2>>"$LOG_LOCAL_FILE"; then
            append_success="true"
            echo "Local log er kopieret til $LOG_FILE_NFS (cp fallback)"
            rm -f "$LOG_LOCAL_FILE" 2>/dev/null || true
        else
            echo "Fejl: cp fallback mislykkedes" >> "$LOG_LOCAL_FILE"
        fi
    fi

    # 4) Endelig: hvis stadig fejler, forsøg at append som ejeren af log-kataloget (runuser)
    if [ "$append_success" != "true" ]; then
        owner=$(stat -c %U "$LOG_DIR_NFS" 2>/dev/null || true)
        if [ -n "$owner" ] && [ "$owner" != "root" ] && command -v runuser >/dev/null 2>&1; then
            echo "Forsøger append som ejer: $owner" >> "$LOG_LOCAL_FILE"
            if runuser -u "$owner" -- sh -c "cat '$LOG_LOCAL_FILE' >> '$LOG_FILE_NFS'" 2>>"$LOG_LOCAL_FILE"; then
                append_success="true"
                echo "Local log blev append'et til $LOG_FILE_NFS som $owner"
                rm -f "$LOG_LOCAL_FILE" 2>/dev/null || true
            else
                echo "Fallback append som $owner mislykkedes." >> "$LOG_LOCAL_FILE"
            fi
        else
            echo "Ingen egnet non-root ejer for fallback append fundet eller runuser ikke tilgængelig." >> "$LOG_LOCAL_FILE"
        fi
    fi

    # 5) Sidste, sikker cp-fallback: opret en unik fil i NFS-log-dir med lokal log (bevarer begge)
    if [ "$append_success" != "true" ]; then
        BASENAME=$(basename "$LOG_LOCAL_FILE")
        CP_TARGET="$LOG_DIR_NFS/$BASENAME"
        echo "Sidste fallback: kopierer lokal log til $CP_TARGET (unik fil) ..." >> "$LOG_LOCAL_FILE"
        if cp "$LOG_LOCAL_FILE" "$CP_TARGET" 2>>"$LOG_LOCAL_FILE"; then
            append_success="true"
            LOG_FILE_NFS="$CP_TARGET"
            echo "CP fallback success: lokal log kopieret til $CP_TARGET"
            rm -f "$LOG_LOCAL_FILE" 2>/dev/null || true
        else
            echo "Fejl: cp fallback mislykkedes; lokal log beholdes: $LOG_LOCAL_FILE" >> "$LOG_LOCAL_FILE"
        fi
    fi

    # Hvis stadig ikke success, behold lokal log og skriv advarsel
    if [ "$append_success" != "true" ]; then
        echo "ADVARSEL: Kunne ikke skrive/merge/log kopiere til NFS ($LOG_FILE_NFS). Lokal log beholdes: $LOG_LOCAL_FILE" >> "$LOG_LOCAL_FILE"
        {
            echo
            echo "!!! ADVARSEL: Kunne ikke appende/merge eller kopiere lokal log til NFS ($LOG_FILE_NFS)."
            echo "Kontroller permissions, NFS/CIFS server, mount options (root_squash/forceuid), og SELinux."
            echo "Som sidste udvej kan du manuelt kopiere $LOG_LOCAL_FILE til NFS."
            echo "-----------------------------------------"
        } >> "$LOG_LOCAL_FILE"
    fi
fi

# -----------------------
# Vælg logkilde for statistik
# -----------------------
if [ "$append_success" = "true" ]; then
    STATS_SOURCE="$LOG_FILE_NFS"
else
    STATS_SOURCE="$LOG_LOCAL_FILE"
fi

# Udtræk de øverste 11 linjer (header) fra logfilen
LOG_HEAD="$(head -n 11 "$STATS_SOURCE" 2>/dev/null || true)"

# Udtræk alt fra "Number of files:" og ned (statistik-blok)
LOG_TAIL="$(awk '/^Number of files:/ {found=1} found' "$STATS_SOURCE" 2>/dev/null || true)"

# -----------------------
# Result handling
# -----------------------
if [ "$rsync_exit" -eq 0 ]; then
    echo "--- SUCCESS ---"

    # v6 FIX: Brug en mere robust grep der matcher rsync's stats-output uanset whitespace-format.
    # rsync kan outputte tal med komma-separatorer (fx "49,196,532,484"), så vi bruger
    # en bredere match og udtrækker den SIDSTE kolonne (tail) som værdien.
    TOTAL_SIZE=$(grep -E '^Total transferred file size:' "$STATS_SOURCE" | tail -n1 | awk '{print $(NF-1), $NF}' || true)
    FILE_COUNT=$(grep -E '^Number of regular files transferred:' "$STATS_SOURCE" | tail -n1 | awk '{print $NF}' || true)

    if [ -n "$TOTAL_SIZE" ] && [ -n "$FILE_COUNT" ]; then
        echo "✅ Backup fuldført: $DATE"
        echo "📂 Filer kopieret: $FILE_COUNT"
        echo "📦 Samlet størrelse: $TOTAL_SIZE"

        {
            echo "--- BACKUP STATUS $DATE ---"
            echo "Status: SUCCESS"
            echo "Starttidspunkt: $START_TIME"
            echo "Sluttidspunkt: $END_TIME"
            echo "Filer kopieret: $FILE_COUNT"
            echo "Samlet størrelse: $TOTAL_SIZE"
            echo "NFS log: $LOG_FILE_NFS"
            echo "Append/CP til NFS succes: $append_success"
            echo
            echo "---- LOG UDSNIT (TOP 11 LINJER) ----"
            echo "$LOG_HEAD"
            echo
            echo "---- LOG UDSNIT (STATISTIK + NED) ----"
            echo "$LOG_TAIL"
            echo "---------------------------"
        } > "$STATUS_FILE_NFS" 2>/dev/null || {
            echo "Warning: Kunne ikke skrive $STATUS_FILE_NFS; skriver lokal status i ${LOG_LOCAL_FILE}.status" >> "$LOG_LOCAL_FILE" 2>/dev/null || true
            {
                echo "--- BACKUP STATUS $DATE (LOCAL-FALLBACK) ---"
                echo "Status: SUCCESS"
                echo "Starttidspunkt: $START_TIME"
                echo "Sluttidspunkt: $END_TIME"
                echo "Filer kopieret: $FILE_COUNT"
                echo "Samlet størrelse: $TOTAL_SIZE"
                echo "NFS log: $LOG_FILE_NFS"
                echo "Append/CP til NFS succes: $append_success"
                echo
                echo "---- LOG UDSNIT (TOP 11 LINJER) ----"
                echo "$LOG_HEAD"
                echo
                echo "---- LOG UDSNIT (STATISTIK + NED) ----"
                echo "$LOG_TAIL"
                echo "---------------------------"
            } > "${LOG_LOCAL_FILE}.status" 2>/dev/null || true
        }
    else
        echo "⚠️ Kunne ikke finde statistik i logfilen, men rsync meldte succes."
    fi

    if [ -n "$DRY_RUN" ]; then
        echo "Bemærk: Dette var en DRY-RUN – ingen filer blev ændret."
    fi

    exit 0
else
    echo "--- FEJL ---"
    echo "rsync returnerede en fejl ($rsync_exit). Se lokal logfil for detaljer: $LOG_LOCAL_FILE (hvis bevaret)."

    {
        echo "--- BACKUP STATUS $DATE ---"
        echo "Status: FAILED"
        echo "Starttidspunkt: $START_TIME"
        echo "Sluttidspunkt: $END_TIME"
        echo "rsync exit kode: $rsync_exit"
        echo "NFS log (intended): $LOG_FILE_NFS"
        echo "Append/CP til NFS succes: $append_success"
        echo "Local log (beholdes hvis append fejlede): $LOG_LOCAL_FILE"
        echo
        echo "---- LOG UDSNIT (TOP 11 LINJER) ----"
        echo "$LOG_HEAD"
        echo
        echo "---- LOG UDSNIT (STATISTIK + NED) ----"
        echo "$LOG_TAIL"
        echo "---------------------------"
    } > "$STATUS_FILE_NFS" 2>/dev/null || {
        echo "Warning: Kunne ikke skrive $STATUS_FILE_NFS; skriver lokal status i ${LOG_LOCAL_FILE}.status" >> "$LOG_LOCAL_FILE" 2>/dev/null || true
        {
            echo "--- BACKUP STATUS $DATE (LOCAL-FALLBACK) ---"
            echo "Status: FAILED"
            echo "Starttidspunkt: $START_TIME"
            echo "Sluttidspunkt: $END_TIME"
            echo "rsync exit kode: $rsync_exit"
            echo "Append/CP til NFS succes: $append_success"
            echo "Local log (beholdes hvis append fejlede): $LOG_LOCAL_FILE"
            echo
            echo "---- LOG UDSNIT (TOP 11 LINJER) ----"
            echo "$LOG_HEAD"
            echo
            echo "---- LOG UDSNIT (STATISTIK + NED) ----"
            echo "$LOG_TAIL"
            echo "---------------------------"
        } > "${LOG_LOCAL_FILE}.status" 2>/dev/null || true
    }

    # Fjern evt. tom destinations-mappe (men IKKE lokal log hvis append fejlede)
    if [ -z "${DRY_RUN:-}" ]; then
        rmdir "$DEST_PATH" 2>/dev/null || true
    fi

    exit 1
fi
