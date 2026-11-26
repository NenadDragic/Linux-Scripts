#!/usr/bin/env bash
# Version:      1.2
# Date:         2026-11-26
# Test Run:
# Developper:   Nenad(a)dragic(.)com

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
require_tools rsync "runuser:util-linux" "mountpoint:util-linux"

set -euo pipefail
IFS=$'\n\t'

# === RSYNC BACKUP SCRIPT v6 ===
# Bruger maskinens hostnavn, kører rsync og logger lokalt,
# forsøger robust append/merge/cp til dagsloggen på USB-disken og skriver status der (med lokal fallback).
# (Variabelnavne med _NFS er historiske fra NAS-versionen; de peger på USB-disken.)
#
# Ændring i v6: Erstatter ustabil process substitution (>(stdbuf ...)) med synkron
# sed | tee -a pipeline, så logfilen er fuldt skrevet inden append til dagsloggen.
# Derved undgås race condition der medførte tom/ufuldstændig logfil ved første kørsel.
#
#
# Ændring i v1.2: Logfilen indeholder ikke længere progress-linjer, men en liste over
# ændrede filer (--itemize-changes) + statistik. Progress vises kun på skærmen ved manuel
# kørsel. Status-filen bygges ud fra denne kørsels log (ikke hele dagsloggen). rsync
# exit 24 (filer forsvandt undervejs) tælles som succes med advarsel. Tomme mapper og
# mountpunkter (/dev, /proc, /sys, /run, /tmp, /mnt, /media) bevares, og /boot tages med.
#
# Brug: chmod +x Backup_USB.sh
# Kør som root: sudo ./Backup_USB.sh [dry-run]

# -----------------------
# Konfiguration
# -----------------------
SOURCE_DIR="/"

# Brug maskinens eget hostnavn (kort form, uden domæne)
HOSTNAME_FROM_CFG="$(hostname -s 2>/dev/null || cat /etc/hostname 2>/dev/null || true)"
HOSTNAME_FROM_CFG="$(printf '%s' "$HOSTNAME_FROM_CFG" | tr -d '\r\n[:space:]')"

if [ -z "$HOSTNAME_FROM_CFG" ]; then
    echo "FEJL: Kunne ikke bestemme maskinens hostnavn (hostname -s / /etc/hostname)."
    exit 1
fi

# DEST_BASE="/mnt/NetBackup/${HOSTNAME_FROM_CFG}"
DEST_BASE="/mnt/usb/Backup/${HOSTNAME_FROM_CFG}"

# Mapper der ender på /* bevares som tomme mapper i backuppen (vigtigt ved restore),
# kun deres indhold springes over.
EXCLUDES=(
    "/lost+found"
    "/opt"
    "/snap"
    "/srv"

    "/dev/*"
    "/media/*"
    "/mnt/*"
    "/proc/*"
    "/run/*"
    "/sys/*"
    "/tmp/*"
    "/var/tmp/*"

    # Swap-filer (op til flere GB, skal aldrig gendannes)
    "/swap.img"
    "/swapfile"

    # Caches (kan genskabes; /var/cache indeholder bl.a. hentede apt-pakker)
    "/var/cache/*"
    "/root/.cache/*"
    "/home/*/.cache/*"

    # Browser- og Electron-app-cacher (Chrome, Chromium, VS Code, Claude, Discord m.fl.).
    # Genskabes automatisk; ændrer sig konstant og giver ellers "file has vanished" (rsync kode 24).
    # Bemærk: Sessions, IndexedDB, Local Storage o.l. med rigtige data tages stadig med.
    # ** matcher på tværs af mapper, så det virker for alle apps og browserprofiler.
    "/home/*/.config/**/Cache/"
    "/home/*/.config/**/Code Cache/"
    "/home/*/.config/**/GPUCache/"
    "/home/*/.config/**/CacheStorage/"
    "/home/*/.config/**/ScriptCache/"
    "/home/*/.config/**/CachedData/"
    "/home/*/.config/**/*ShaderCache/"
    "/home/*/.config/**/*Dawn*Cache/"
    "/home/*/.config/*/Safe Browsing/"
)

# -----------------------
# Root check
# -----------------------
if [ "$(id -u)" -ne 0 ]; then
    echo "FEJL: Dette script skal køres som root."
    exit 1
fi

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
MOUNT_ROOT="/mnt/usb/Backup"
if [ ! -d "$MOUNT_ROOT" ]; then
    echo "FEJL: Mountpunkt $MOUNT_ROOT eksisterer ikke — er USB-disken monteret?"
    exit 1
fi
# Mappen findes også, når disken IKKE er monteret (Backup_USB_Mount.sh opretter den).
# Uden dette tjek ville hele backuppen blive skrevet til rodfilsystemet og fylde systemdisken.
if ! mountpoint -q "$MOUNT_ROOT"; then
    echo "FEJL: $MOUNT_ROOT er ikke et monteringspunkt — USB-disken er ikke monteret (kør Backup_USB_Mount.sh)."
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

# Logmappe på USB-disken: /mnt/usb/Backup/Log/<HOSTNAME>/
LOG_DIR_NFS="/mnt/usb/Backup/Log/${HOSTNAME_FROM_CFG}"
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
# Lock for at undgå samtidige runs (fast navn, så en kørsel kl. 23:59 og 00:01 ikke overlapper)
# -----------------------
LOCKFILE="/var/lock/rsync_backup.lock"
mkdir -p /var/lock
exec 9>"$LOCKFILE"
if ! flock -n 9; then
    echo "Et andet backup-job kører allerede. Afslutter."
    rm -f "$EXCLUDE_FILE" 2>/dev/null || true
    exec 9>&- || true
    exit 1
fi

# Ryd gamle lokale logs og exclude-filer op (efterladt af afbrudte eller fejlede kørsler)
find "$LOG_LOCAL_DIR" -maxdepth 1 -type f \
    \( -name 'rsync_backup_*' -o -name 'rsync_excludes_*' \) \
    -mtime +30 -delete 2>/dev/null || true

# Cleanup trap: fjerner exclude tempfil, frigiver lås, og fjerner den lokale log
# hvis den er kommet sikkert over på backup-disken (ellers beholdes den).
append_success="false"
cleanup() {
    local rc=$?
    rm -f "$EXCLUDE_FILE" 2>/dev/null || true
    if [ "${append_success:-false}" = "true" ]; then
        rm -f "$LOG_LOCAL_FILE" 2>/dev/null || true
    fi
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
    echo "USB log (daglig): $LOG_FILE_NFS"
    echo "Exclude-fil: $EXCLUDE_FILE"
    echo "-----------------------------------------"
} >> "$LOG_LOCAL_FILE"

echo "Starter rsync backup fra $SOURCE_DIR til $DEST_PATH"
echo "Lokal realtime log: $LOG_LOCAL_FILE"
echo "Daglig log på USB-disken: $LOG_FILE_NFS (append'es når rsync er færdig)"

# -----------------------
# Build rsync cmd array
# -----------------------
# Progress vises kun når scriptet køres i en terminal (ikke fra cron). Progress-linjer
# skrives aldrig i logfilen — den får kun ændrede filer (--itemize-changes), fejl og statistik.
if [ -t 1 ]; then
    RSYNC_INFO="--info=progress2,stats2"
    SHOW_PROGRESS=1
else
    RSYNC_INFO="--info=stats2"
    SHOW_PROGRESS=0
fi

RSYNC_CMD=(rsync ${DRY_RUN:+"$DRY_RUN"} -aHX --numeric-ids --delete-delay "$RSYNC_INFO" \
    --itemize-changes --exclude-from="$EXCLUDE_FILE" \
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
# hvilket medførte at logfilen var tom/ufuldstændig når append til dagsloggen kørte bagefter.
# Med sed | tee -a er alle tre kommandoer i en synkron pipeline: bash venter på dem alle.
#
# v1.2: tee er erstattet af awk, som sorterer linjerne:
#   - progress-linjer  -> kun skærmen (overskriver samme linje med \r)
#   - itemize-linjer   -> kun logfilen (én linje pr. ændret/slettet fil)
#   - alt andet        -> både skærm og logfil (fejl, advarsler, statistik)
#
# PIPESTATUS-rækkefølge: [0]=rsync [1]=sed [2]=awk
# Vi fanger stadig rsync's exit code fra PIPESTATUS[0].
#
# Midlertidigt slå errexit/pipefail fra så scriptet ikke stopper ved rsync exit 23 o.l.
# -----------------------
set +e
set +o pipefail 2>/dev/null || true

"${STDBUF_PREFIX[@]}" "${RSYNC_CMD[@]}" 2>&1 \
    | sed -u 's/\r/\n/g' \
    | awk -v logf="$LOG_LOCAL_FILE" -v showprog="$SHOW_PROGRESS" '
        # Tomme linjer opstår mellem \r-progress og almindelige linjer; spring dem over når progress er slået til
        showprog == 1 && $0 == "" { next }
        /^ *[0-9][0-9,]* +[0-9]+% / { printf "\r%s", $0; fflush(); inprog = 1; next }
        /^([<>ch.][fdLDS]|\*deleting )/ { print >> logf; fflush(logf); next }
        {
            if (inprog) { printf "\n"; inprog = 0 }
            print; fflush()
            print >> logf; fflush(logf)
        }
        END { if (inprog) printf "\n" }'

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
# Append local log to daily log on the USB drive (robust fallback: append -> merge temp -> cp unique -> attempt runuser append)
# -----------------------
{
    echo
    echo "----- APPENDING LOCAL LOG TO USB LOG -----"
    echo "Tidspunkt: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Local log: $LOG_LOCAL_FILE"
    echo "USB log: $LOG_FILE_NFS"
    echo "------------------------------------------"
} >> "$LOG_LOCAL_FILE"

# Ensure log dir on the USB drive exists (again)
mkdir -p "$LOG_DIR_NFS" 2>/dev/null || true

# 1) Prøv enkel append
if cat "$LOG_LOCAL_FILE" >> "$LOG_FILE_NFS" 2>>"$LOG_LOCAL_FILE"; then
    append_success="true"
    echo "Local log er append'et til $LOG_FILE_NFS"
else
    echo "ADVARSEL: Append fejlede som $(whoami). Prøver atomic merge fallback..." >> "$LOG_LOCAL_FILE"

    # Diagnostic info
    {
        echo "Diagnose: permissions og mount info:"
        stat -c "Owner: %U  Group: %G  Perms: %A" "$LOG_DIR_NFS" 2>/dev/null || true
        stat -c "Logfile: %n owner=%U group=%G perms=%A" "$LOG_FILE_NFS" 2>/dev/null || true
        mount | grep "$MOUNT_ROOT" || true
        dmesg | tail -n 20 || true
    } >> "$LOG_LOCAL_FILE" 2>/dev/null

    # 2) Hvis dagsloggen findes og er læsbar, lav en midlertidig merged fil og mv den over (atomisk)
    TMP_MERGE=""
    if TMP_MERGE="$(mktemp "$LOG_DIR_NFS/rsync_log_merge_XXXXXX" 2>/dev/null)" 2>/dev/null || TMP_MERGE="$(mktemp 2>/dev/null)"; then
        if [ -r "$LOG_FILE_NFS" ]; then
            if cat "$LOG_FILE_NFS" "$LOG_LOCAL_FILE" > "$TMP_MERGE" 2>>"$LOG_LOCAL_FILE"; then
                if mv -f "$TMP_MERGE" "$LOG_FILE_NFS" 2>>"$LOG_LOCAL_FILE"; then
                    append_success="true"
                    echo "Local log merged ind i $LOG_FILE_NFS via temp+mv"
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
            echo "Dagsloggen på USB-disken er ikke læsbar eller mangler; forsøger cp (overskriver/opretter)..." >> "$LOG_LOCAL_FILE"
            if cp "$LOG_LOCAL_FILE" "$LOG_FILE_NFS" 2>>"$LOG_LOCAL_FILE"; then
                append_success="true"
                echo "Local log er kopieret til $LOG_FILE_NFS (cp fallback)"
            else
                echo "Fejl: cp fallback mislykkedes" >> "$LOG_LOCAL_FILE"
            fi
        fi
    else
        echo "Kunne ikke lave tmpfile i $LOG_DIR_NFS eller /tmp; forsøger cp fallback..." >> "$LOG_LOCAL_FILE"
        if cp "$LOG_LOCAL_FILE" "$LOG_FILE_NFS" 2>>"$LOG_LOCAL_FILE"; then
            append_success="true"
            echo "Local log er kopieret til $LOG_FILE_NFS (cp fallback)"
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
            else
                echo "Fallback append som $owner mislykkedes." >> "$LOG_LOCAL_FILE"
            fi
        else
            echo "Ingen egnet non-root ejer for fallback append fundet eller runuser ikke tilgængelig." >> "$LOG_LOCAL_FILE"
        fi
    fi

    # 5) Sidste, sikker cp-fallback: opret en unik fil i logmappen med lokal log (bevarer begge)
    if [ "$append_success" != "true" ]; then
        BASENAME=$(basename "$LOG_LOCAL_FILE")
        CP_TARGET="$LOG_DIR_NFS/$BASENAME"
        echo "Sidste fallback: kopierer lokal log til $CP_TARGET (unik fil) ..." >> "$LOG_LOCAL_FILE"
        if cp "$LOG_LOCAL_FILE" "$CP_TARGET" 2>>"$LOG_LOCAL_FILE"; then
            append_success="true"
            LOG_FILE_NFS="$CP_TARGET"
            echo "CP fallback success: lokal log kopieret til $CP_TARGET"
        else
            echo "Fejl: cp fallback mislykkedes; lokal log beholdes: $LOG_LOCAL_FILE" >> "$LOG_LOCAL_FILE"
        fi
    fi

    # Hvis stadig ikke success, behold lokal log og skriv advarsel
    if [ "$append_success" != "true" ]; then
        echo "ADVARSEL: Kunne ikke skrive/merge/log kopiere til USB-disken ($LOG_FILE_NFS). Lokal log beholdes: $LOG_LOCAL_FILE" >> "$LOG_LOCAL_FILE"
        {
            echo
            echo "!!! ADVARSEL: Kunne ikke appende/merge eller kopiere lokal log til USB-disken ($LOG_FILE_NFS)."
            echo "Kontroller at USB-disken er monteret og skrivbar (permissions, ledig plads, mount-options)."
            echo "Som sidste udvej kan du manuelt kopiere $LOG_LOCAL_FILE til USB-disken."
            echo "-----------------------------------------"
        } >> "$LOG_LOCAL_FILE"
    fi
fi

# -----------------------
# Logkilde for statistik
# v1.2: Brug altid DENNE kørsels lokale log (den slettes først i cleanup-trap'en).
# Dagsloggen på disken kan indeholde flere kørsler, så head/awk ville ellers vise
# header fra dagens første kørsel og statistik fra alle kørsler.
# -----------------------
STATS_SOURCE="$LOG_LOCAL_FILE"

# Udtræk de øverste 11 linjer (header) fra logfilen
LOG_HEAD="$(head -n 11 "$STATS_SOURCE" 2>/dev/null || true)"

# Udtræk alt fra "Number of files:" og ned (statistik-blok)
LOG_TAIL="$(awk '/^Number of files:/ {found=1} found' "$STATS_SOURCE" 2>/dev/null || true)"

# Advarsler/fejl fra rsync (fx "file has vanished") — med i status-filen
LOG_WARNINGS="$(grep -E '^(rsync: |rsync error|rsync warning|file has vanished)' "$STATS_SOURCE" 2>/dev/null | head -n 50 || true)"

# -----------------------
# Result handling
# Exit 24 = "nogle filer forsvandt før de kunne overføres" (fx browser-/database-filer
# der ændres mens backuppen kører). Selve backuppen er gennemført → succes med advarsel.
# -----------------------
if [ "$rsync_exit" -eq 0 ] || [ "$rsync_exit" -eq 24 ]; then
    if [ "$rsync_exit" -eq 24 ]; then
        STATUS_LABEL="SUCCESS (ADVARSEL: nogle filer forsvandt under kopiering, rsync kode 24)"
        echo "--- SUCCESS (med advarsel: rsync kode 24, filer forsvandt undervejs) ---"
    else
        STATUS_LABEL="SUCCESS"
        echo "--- SUCCESS ---"
    fi

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
            echo "Status: $STATUS_LABEL"
            echo "rsync exit kode: $rsync_exit"
            echo "Starttidspunkt: $START_TIME"
            echo "Sluttidspunkt: $END_TIME"
            echo "Filer kopieret: $FILE_COUNT"
            echo "Samlet størrelse: $TOTAL_SIZE"
            echo "USB log: $LOG_FILE_NFS"
            echo "Append/CP til USB succes: $append_success"
            echo
            echo "---- LOG UDSNIT (TOP 11 LINJER) ----"
            echo "$LOG_HEAD"
            echo
            if [ -n "$LOG_WARNINGS" ]; then
                echo "---- ADVARSLER / FEJL FRA RSYNC ----"
                echo "$LOG_WARNINGS"
                echo
            fi
            echo "---- LOG UDSNIT (STATISTIK + NED) ----"
            echo "$LOG_TAIL"
            echo "---------------------------"
        } > "$STATUS_FILE_NFS" 2>/dev/null || {
            echo "Warning: Kunne ikke skrive $STATUS_FILE_NFS; skriver lokal status i ${LOG_LOCAL_FILE}.status" >> "$LOG_LOCAL_FILE" 2>/dev/null || true
            {
                echo "--- BACKUP STATUS $DATE (LOCAL-FALLBACK) ---"
                echo "Status: $STATUS_LABEL"
                echo "rsync exit kode: $rsync_exit"
                echo "Starttidspunkt: $START_TIME"
                echo "Sluttidspunkt: $END_TIME"
                echo "Filer kopieret: $FILE_COUNT"
                echo "Samlet størrelse: $TOTAL_SIZE"
                echo "USB log: $LOG_FILE_NFS"
                echo "Append/CP til USB succes: $append_success"
                echo
                echo "---- LOG UDSNIT (TOP 11 LINJER) ----"
                echo "$LOG_HEAD"
                echo
                if [ -n "$LOG_WARNINGS" ]; then
                    echo "---- ADVARSLER / FEJL FRA RSYNC ----"
                    echo "$LOG_WARNINGS"
                    echo
                fi
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
        echo "USB log (tilsigtet): $LOG_FILE_NFS"
        echo "Append/CP til USB succes: $append_success"
        echo "Local log (beholdes hvis append fejlede): $LOG_LOCAL_FILE"
        echo
        echo "---- LOG UDSNIT (TOP 11 LINJER) ----"
        echo "$LOG_HEAD"
        echo
        if [ -n "$LOG_WARNINGS" ]; then
            echo "---- ADVARSLER / FEJL FRA RSYNC ----"
            echo "$LOG_WARNINGS"
            echo
        fi
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
            echo "Append/CP til USB succes: $append_success"
            echo "Local log (beholdes hvis append fejlede): $LOG_LOCAL_FILE"
            echo
            echo "---- LOG UDSNIT (TOP 11 LINJER) ----"
            echo "$LOG_HEAD"
            echo
            if [ -n "$LOG_WARNINGS" ]; then
                echo "---- ADVARSLER / FEJL FRA RSYNC ----"
                echo "$LOG_WARNINGS"
                echo
            fi
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
