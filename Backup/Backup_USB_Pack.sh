#!/usr/bin/env bash
# --- Dependency check (samme mønster som Backup_NAS_Complete_v6.sh) ---
_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
while [ "$_d" != "/" ] && [ ! -f "$_d/lib/require_tools.sh" ]; do _d="$(dirname "$_d")"; done
if [ ! -f "$_d/lib/require_tools.sh" ]; then
    echo "FEJL: Kunne ikke finde lib/require_tools.sh (delt dependency-checker)." >&2
    exit 1
fi
# shellcheck source=/dev/null
source "$_d/lib/require_tools.sh"
unset _d
require_tools tar gzip find awk "flock:util-linux" "findmnt:util-linux" "getfattr:attr"

set -euo pipefail
IFS=$'\n\t'

# === BACKUP ARKIV SCRIPT v1 ===
# Pakker hver dato-mappe, som Backup_NAS_Complete_v6.sh har lavet, til ét arkiv,
# validerer arkivet mod mappen og sletter mappen FØRST når valideringen er bestået:
#
#   /mnt/usb/Backup/<Hostname>/YYYY-MM-DD/   ->   /mnt/usb/Backup/<Hostname>/YYYY-MM-DD.gz
#
# Arkivet er tar + gzip (en mappe kan ikke gzip'es direkte). Endelsen er ".gz" som ønsket;
# tar genkender selv formatet ved udpakning.
#
# Validering — ALT skal bestå, ellers bevares mappen og det ufærdige arkiv slettes:
#   0. Arkivet fsync'es og smides ud af pagecache, så der valideres mod det, der
#      faktisk ligger på USB-disken — ikke en kopi i RAM.
#   1. tar --list læser hele arkivet: gzip-CRC og tar-struktur skal være intakte,
#      og alle medlemmer skal ligge under YYYY-MM-DD/.
#   2. tar --compare: hvert medlem sammenlignes byte-for-byte med mappen, plus
#      rettigheder, uid/gid, mtime, størrelse, symlink-mål, hardlinks og device-numre.
#   3. Fuldstændighed: antal objekter i arkivet == antal i mappen (minus sockets, som
#      tar ikke kan gemme og som ikke indeholder data), og antal/samlet størrelse af
#      xattrs (fx security.capability) skal stemme — tar --compare tjekker ikke xattrs.
#
# Sikkerhed:
#   - Rører aldrig en dato, som backup-scriptet kører på (deler v6's låsefil
#     /var/lock/rsync_backup_<DATO>.lock og holder den, mens datoen behandles).
#   - Overskriver aldrig et eksisterende arkiv. Findes YYYY-MM-DD.gz allerede ved siden
#     af mappen, valideres det mod mappen; mappen slettes kun hvis de er identiske.
#   - Afbrydes scriptet (Ctrl-C), fjernes det ufærdige arkiv; mappen er urørt.
#   - Stopper hvis /mnt/usb/Backup ligger på rodfilsystemet (USB-disk ikke monteret).
#
# Brug:   sudo ./Backup_Archive_v1.sh [dry-run|-n] [-y]
#           dry-run, -n   Vis hvad der ville ske — intet ændres
#           -y, --yes     Spørg ikke om bekræftelse
# Gendan: sudo tar -xpf YYYY-MM-DD.gz --numeric-owner --xattrs --xattrs-include='*' -C <målmappe>
#         (uden --xattrs-include='*' gendanner tar kun user.* xattrs — fx mistes capabilities)

# -----------------------
# Konfiguration
# -----------------------
BACKUP_ROOT="${BACKUP_ROOT:-/mnt/usb/Backup}"   # samme rod som Backup_NAS_Complete_v6.sh
ARCHIVE_SUFFIX=".gz"                            # arkivnavn: YYYY-MM-DD.gz
LOG_DIR="$BACKUP_ROOT/Log/archive"
BACKUP_LOCK_DIR="/var/lock"                     # v6 låser /var/lock/rsync_backup_<DATO>.lock
SELF_LOCK="$BACKUP_LOCK_DIR/backup_archive.lock"
XATTR_NS_REGEX='^(user|security|trusted)\.'      # navnerum rsync -X kopierer (ACL'er kopieres ikke uden -A)

TAR_META=(--numeric-owner --xattrs --xattrs-include='*')

# pigz (parallel gzip) bruges hvis den er installeret — samme gzip-format, markant hurtigere
if command -v pigz >/dev/null 2>&1; then
    TAR_COMP=(--use-compress-program=pigz)
    COMP_NAME="pigz (parallel gzip)"
else
    TAR_COMP=(--gzip)
    COMP_NAME="gzip (installér pigz for hurtigere pakning)"
fi

# Fremdrift fra tar — kun når der sidder et menneske ved terminalen (skrives til /dev/tty, ikke til loggen)
TAR_PROGRESS=()
if [ -t 1 ] && { : >/dev/tty; } 2>/dev/null; then
    TAR_PROGRESS=(--checkpoint=10000 "--checkpoint-action=ttyout=      %{%H:%M:%S}t  %T%*\r")
fi

# -----------------------
# Argumenter
# -----------------------
usage() {
    cat <<'EOF'
Brug: sudo ./Backup_Archive_v1.sh [dry-run|-n] [-y]

Pakker hver /mnt/usb/Backup/<Hostname>/YYYY-MM-DD/ til YYYY-MM-DD.gz (tar+gzip),
validerer arkivet mod mappen og sletter mappen kun hvis valideringen består.

  dry-run, -n, --dry-run   Vis planen — intet ændres
  -y, --yes                Spørg ikke om bekræftelse
  -h, --help               Denne hjælp

Miljøvariabel: BACKUP_ROOT (standard /mnt/usb/Backup)
EOF
}

DRY_RUN=false
ASSUME_YES=false
for arg in "$@"; do
    case "$arg" in
        -n|--dry-run) DRY_RUN=true ;;
        -y|--yes) ASSUME_YES=true ;;
        -h|--help) usage; exit 0 ;;
        *)
            # Ordet dry-run må skrives med store eller små bogstaver (Dry-run, DRY-RUN)
            if [ "${arg,,}" = "dry-run" ]; then
                DRY_RUN=true
            else
                echo "FEJL: Ukendt argument: $arg" >&2; usage >&2; exit 2
            fi
            ;;
    esac
done

# -----------------------
# Root check og pre-flight
# -----------------------
if [ "$(id -u)" -ne 0 ]; then
    echo "FEJL: Dette script skal køres som root."
    exit 1
fi

BACKUP_ROOT="${BACKUP_ROOT%/}"
case "$BACKUP_ROOT" in
    /?*) ;;
    *) echo "FEJL: BACKUP_ROOT skal være en absolut sti og ikke '/' (fik '${BACKUP_ROOT}')."; exit 1 ;;
esac

if [ ! -d "$BACKUP_ROOT" ]; then
    echo "FEJL: $BACKUP_ROOT eksisterer ikke — er USB-disken monteret?"
    exit 1
fi

# Ligger backup-roden på rodfilsystemet, er USB-disken sandsynligvis ikke monteret
FS_TARGET="$(findmnt -n -o TARGET -T "$BACKUP_ROOT" 2>/dev/null || true)"
if [ -z "$FS_TARGET" ] || [ "$FS_TARGET" = "/" ]; then
    echo "FEJL: $BACKUP_ROOT ligger på rodfilsystemet, ikke på en separat monteret disk."
    echo "      Er USB-disken monteret? Stopper for ikke at arbejde på forkert disk."
    exit 1
fi

# Kun én arkiv-kørsel ad gangen
mkdir -p "$BACKUP_LOCK_DIR"
exec 8>>"$SELF_LOCK"
if ! flock -n 8; then
    echo "FEJL: Et andet arkiv-job kører allerede ($SELF_LOCK). Afslutter."
    exit 1
fi

# -----------------------
# Hjælpefunktioner
# -----------------------
LOG_FILE=""
CURRENT_PARTIAL=""
WORK_DIR="$(mktemp -d "${TMPDIR:-/var/tmp}/backup_archive.XXXXXX")"

log() {
    local IFS=' ' m
    m="$(date '+%Y-%m-%d %H:%M:%S')  $*"
    printf '%s\n' "$m"
    if [ -n "$LOG_FILE" ]; then printf '%s\n' "$m" >> "$LOG_FILE" 2>/dev/null || true; fi
    return 0
}
warn() { log "ADVARSEL: $*"; }
err()  { log "FEJL: $*"; }

# Viser de første linjer af en fil på skærmen og skriver hele filen i loggen
log_file_excerpt() {
    local f=$1 max=${2:-15} n
    [ -s "$f" ] || return 0
    n=$(wc -l < "$f")
    head -n "$max" -- "$f" | sed 's/^/      | /'
    if [ "$n" -gt "$max" ]; then printf '      | ... (%s linjer i alt — se loggen)\n' "$n"; fi
    if [ -n "$LOG_FILE" ]; then sed 's/^/      | /' -- "$f" >> "$LOG_FILE" 2>/dev/null || true; fi
    return 0
}

clear_tty_line() { if [ ${#TAR_PROGRESS[@]} -gt 0 ]; then printf '\r\033[K' > /dev/tty 2>/dev/null || true; fi; return 0; }

hsize() { numfmt --to=iec --suffix=B --format='%.1f' -- "$1" 2>/dev/null || printf '%s B' "$1"; }

fmt_dur() { local s=$1; printf '%dt %02dm %02ds' $((s / 3600)) $((s % 3600 / 60)) $((s % 60)); }

cleanup() {
    clear_tty_line
    if [ -n "$CURRENT_PARTIAL" ] && [ -e "$CURRENT_PARTIAL" ]; then
        rm -f -- "$CURRENT_PARTIAL" 2>/dev/null || true
        log "Oprydning: fjernede ufærdigt arkiv $CURRENT_PARTIAL (mappen er urørt)"
    fi
    rm -rf -- "$WORK_DIR" 2>/dev/null || true
}
trap cleanup EXIT
trap 'echo; log "AFBRUDT (SIGINT). En mappe slettes aldrig før dens arkiv er valideret."; exit 130' INT
trap 'echo; log "AFBRUDT (SIGTERM). En mappe slettes aldrig før dens arkiv er valideret."; exit 143' TERM

# Status fra v6's statusfil: SUCCESS / FAILED / ukendt
backup_status() {
    local f="$BACKUP_ROOT/Log/$1/rsync_backup_$2.status" s=""
    if [ -r "$f" ]; then
        s="$(grep -m1 '^Status:' -- "$f" 2>/dev/null || true)"
        s="${s#Status: }"
    fi
    printf '%s' "${s:-ukendt}"
}

# 0 hvis Backup_NAS_Complete_v6.sh holder låsen for datoen (dvs. kører lige nu)
backup_running() {
    local lf="$BACKUP_LOCK_DIR/rsync_backup_$1.lock"
    [ -e "$lf" ] || return 1
    if flock -n "$lf" true 2>/dev/null; then return 1; fi
    return 0
}

is_empty_dir() { [ -z "$(find "$1" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; }

# Udskriver: "<objekter i alt> <heraf sockets> <bytes i regulære filer>"
count_entries() {
    LC_ALL=C find "$1" -printf '%y %s\n' \
        | LC_ALL=C awk '{ n++ } $1 == "s" { s++ } $1 == "f" { b += $2 }
                        END { printf "%d %d %.0f\n", n, s, b }'
}

# Læser NUL-separerede "<inode> <sti>" og udskriver kun første sti pr. inode (NUL-separeret)
first_path_per_inode() {
    local rec ino
    local -A seen=()
    while IFS= read -r -d '' rec; do
        ino="${rec%% *}"
        [ -n "${seen[$ino]+x}" ] && continue
        seen[$ino]=1
        printf '%s\0' "${rec#* }"
    done
}

# Udskriver: "<antal xattrs> <samlet værdi-størrelse i bytes>" for navnerummene i XATTR_NS_REGEX.
# Tælles pr. inode, fordi tar kun gemmer xattrs én gang for hardlinkede filer.
# Sockets udelades (tar gemmer dem ikke).
count_xattrs() {
    {
        LC_ALL=C find "$1" ! -type s \( -type d -o -links 1 \) -print0
        LC_ALL=C find "$1" ! -type s ! -type d -links +1 -printf '%i %p\0' | first_path_per_inode
    } | LC_ALL=C xargs -0 -r getfattr -P -h --absolute-names -d -e hex -m "$XATTR_NS_REGEX" -- 2> "$WORK_DIR/getfattr.err" \
        | LC_ALL=C awk '
            /^# file: / || /^$/ { next }
            {
                n++
                i = index($0, "=0x")
                if (i > 0) b += (length($0) - i - 2) / 2
            }
            END { printf "%d %.0f\n", n, b }'
}

# -----------------------
# Validering af arkiv mod mappe
# -----------------------
validate_archive() {
    local archive=$1 hostdir=$2 name=$3
    local dir="$hostdir/$name" tag="[${hostdir##*/}/$name]"
    local list="$WORK_DIR/list" t0 counts xcounts
    local members bad xa_n xa_b total sockets bytes dx_n dx_b expected

    # 0) Arkivet skal ligge på disken, og læsningen skal komme fra disken — ikke fra RAM
    if ! sync -- "$archive"; then
        err "$tag fsync af arkivet fejlede"
        return 1
    fi
    if ! dd if="$archive" iflag=nocache count=0 status=none 2>/dev/null; then
        warn "$tag kunne ikke tømme pagecache for arkivet — validering læser muligvis fra RAM"
    fi

    # 1) Læs hele arkivet: gzip-CRC, tar-struktur, medlemsliste og xattrs
    log "$tag validering 1/3: læser hele arkivet (gzip-CRC, struktur, xattrs)"
    t0=$SECONDS
    if ! LC_ALL=C tar --list -vv --full-time --quoting-style=escape --file="$archive" \
            "${TAR_COMP[@]}" "${TAR_META[@]}" "${TAR_PROGRESS[@]}" \
            > "$list" 2> "$WORK_DIR/list.err"; then
        clear_tty_line
        err "$tag arkivet kan ikke læses — korrupt eller ufuldstændigt"
        log_file_excerpt "$WORK_DIR/list.err"
        return 1
    fi
    clear_tty_line

    # Linjeformat (-vv --full-time):
    #   mode uid/gid størrelse YYYY-MM-DD HH:MM:SS.nnnnnnnnn navn[ -> mål | link to mål]
    #   (tar kapper afsluttende nuller i nanosekunderne og udfylder med mellemrum)
    #   "  x: <længde> <xattr-navn>"  for hver xattr på medlemmet ovenfor
    if ! LC_ALL=C awk -v pfx="$name/" -v ns="$XATTR_NS_REGEX" '
            /^  x: [0-9]+ / { if ($3 ~ ns) { xn++; xb += $2 }; next }
            {
                m++
                if (match($0, /^[^ ]+ +[^ ]+ +[^ ]+ +[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] +[0-9][0-9]:[0-9][0-9]:[0-9][0-9][.0-9]* +/)) {
                    if (substr($0, RLENGTH + 1, length(pfx)) != pfx) bad++
                } else {
                    bad++
                }
            }
            END { printf "%d %d %d %.0f\n", m, bad, xn, xb }' "$list" > "$WORK_DIR/list.sum"; then
        err "$tag kunne ikke analysere arkivets indholdsliste"
        return 1
    fi
    IFS=' ' read -r members bad xa_n xa_b < "$WORK_DIR/list.sum"
    if [ "$bad" -ne 0 ]; then
        err "$tag $bad medlem(mer) i arkivet ligger ikke under $name/ (eller kunne ikke tolkes)"
        return 1
    fi
    if [ "$members" -lt 1 ]; then
        err "$tag arkivet er tomt"
        return 1
    fi
    log "$tag   ok: arkivet er intakt, $members objekter ($(fmt_dur $((SECONDS - t0))))"

    # 2) Byte-for-byte sammenligning af hvert medlem mod mappen
    log "$tag validering 2/3: sammenligner hvert objekt byte-for-byte med mappen"
    t0=$SECONDS
    if ! LC_ALL=C tar --compare --file="$archive" --directory="$hostdir" \
            "${TAR_COMP[@]}" "${TAR_META[@]}" "${TAR_PROGRESS[@]}" \
            > "$WORK_DIR/cmp.out" 2>&1; then
        clear_tty_line
        err "$tag tar --compare fandt forskelle mellem arkiv og mappe"
        log_file_excerpt "$WORK_DIR/cmp.out"
        return 1
    fi
    clear_tty_line
    if [ -s "$WORK_DIR/cmp.out" ]; then
        err "$tag tar --compare gav uventede meddelelser — behandles som fejl"
        log_file_excerpt "$WORK_DIR/cmp.out"
        return 1
    fi
    log "$tag   ok: indhold, rettigheder, ejer, mtime og links er identiske ($(fmt_dur $((SECONDS - t0))))"

    # 3) Fuldstændighed: intet i mappen må mangle i arkivet
    #    (2) beviser at alle arkivmedlemmer findes i mappen; ens antal beviser at intet mangler.
    log "$tag validering 3/3: fuldstændighed (antal objekter og xattrs)"
    if ! counts="$(count_entries "$dir")"; then
        err "$tag kunne ikke tælle objekter i $dir"
        return 1
    fi
    IFS=' ' read -r total sockets bytes <<< "$counts"
    expected=$((total - sockets))
    if [ "$members" -ne "$expected" ]; then
        err "$tag arkivet har $members objekter, mappen har $expected (+ $sockets sockets)"
        return 1
    fi
    if ! xcounts="$(count_xattrs "$dir")"; then
        err "$tag getfattr fejlede på $dir"
        log_file_excerpt "$WORK_DIR/getfattr.err"
        return 1
    fi
    IFS=' ' read -r dx_n dx_b <<< "$xcounts"
    if [ "$xa_n" != "$dx_n" ] || [ "$xa_b" != "$dx_b" ]; then
        err "$tag xattrs stemmer ikke: arkiv $xa_n stk/$xa_b bytes, mappe $dx_n stk/$dx_b bytes"
        return 1
    fi
    log "$tag   ok: alle $expected objekter og $xa_n xattrs er med$( [ "$sockets" -gt 0 ] && printf ' (%s sockets udeladt — indeholder ingen data)' "$sockets" )"
    return 0
}

delete_dir() {
    local dir=$1 tag=$2
    log "$tag sletter mappen $dir"
    if ! rm -rf --one-file-system -- "$dir"; then
        err "$tag sletning fejlede delvist — arkivet er gyldigt; slet resten manuelt"
        return 1
    fi
    if [ -e "$dir" ]; then
        err "$tag mappen findes stadig efter sletning"
        return 1
    fi
    return 0
}

# Returnerer 0 = arkiveret og mappe slettet, 1 = fejl (mappe bevaret), 2 = sprunget over
process_locked() {
    local dir=$1
    local hostdir="${dir%/*}" name="${dir##*/}"
    local host="${hostdir##*/}"
    local tag="[$host/$name]"
    local archive="$hostdir/$name$ARCHIVE_SUFFIX"
    local partial="$hostdir/.$name$ARCHIVE_SUFFIX.partial"
    local status counts total sockets bytes avail t0 asize

    if is_empty_dir "$dir"; then
        warn "$tag mappen er tom (fx efter en dry-run af backup) — springes over"
        return 2
    fi

    status="$(backup_status "$host" "$name")"
    if [ "$status" != "SUCCESS" ]; then
        warn "$tag backup-status er '$status' — mappen arkiveres som den er"
    fi

    # Arkiv findes allerede: validér det mod mappen i stedet for at overskrive
    if [ -e "$archive" ]; then
        log "$tag $(basename "$archive") findes allerede — validerer det mod mappen"
        if validate_archive "$archive" "$hostdir" "$name"; then
            delete_dir "$dir" "$tag" || return 1
            log "$tag FÆRDIG — mappen var identisk med det eksisterende arkiv og er slettet"
            return 0
        fi
        err "$tag det eksisterende arkiv matcher IKKE mappen — begge bevares. Undersøg manuelt."
        return 1
    fi

    # Rester fra en tidligere afbrudt kørsel
    if [ -e "$partial" ]; then
        warn "$tag fjerner ufærdigt arkiv fra tidligere kørsel: $partial"
        if ! rm -f -- "$partial"; then
            err "$tag kunne ikke fjerne $partial"
            return 1
        fi
    fi

    # Opgørelse og pladscheck
    if ! counts="$(count_entries "$dir")"; then
        err "$tag kunne ikke opgøre indholdet af $dir"
        return 1
    fi
    IFS=' ' read -r total sockets bytes <<< "$counts"
    log "$tag $total objekter, $(hsize "$bytes") i filer (ukomprimeret)"
    avail="$(df -B1 --output=avail -- "$hostdir" 2>/dev/null | tail -n 1 | tr -d ' ' || true)"
    if [[ "$avail" =~ ^[0-9]+$ ]] && [ "$avail" -lt "$bytes" ]; then
        warn "$tag kun $(hsize "$avail") ledig. Arkivet bliver normalt mindre end mappen, men løber disken fuld, ryddes op og mappen bevares."
    fi

    # Pak
    log "$tag pakker med $COMP_NAME ..."
    CURRENT_PARTIAL="$partial"
    t0=$SECONDS
    if ! tar --create --file="$partial" --format=posix \
            "${TAR_COMP[@]}" "${TAR_META[@]}" "${TAR_PROGRESS[@]}" \
            --directory="$hostdir" -- "$name" 2> "$WORK_DIR/create.err"; then
        clear_tty_line
        err "$tag tar kunne ikke oprette arkivet — mappen bevares"
        log_file_excerpt "$WORK_DIR/create.err"
        rm -f -- "$partial"
        CURRENT_PARTIAL=""
        return 1
    fi
    clear_tty_line
    if [ -s "$WORK_DIR/create.err" ]; then
        log "$tag meddelelser fra tar (ikke fejl):"
        log_file_excerpt "$WORK_DIR/create.err" 5
    fi
    asize="$(stat -c %s -- "$partial" 2>/dev/null || echo 0)"
    log "$tag pakket: $(hsize "$asize") på $(fmt_dur $((SECONDS - t0)))"

    # Validér
    if ! validate_archive "$partial" "$hostdir" "$name"; then
        err "$tag validering FEJLEDE — arkivet kasseres, mappen bevares"
        rm -f -- "$partial"
        CURRENT_PARTIAL=""
        return 1
    fi

    # Endeligt navn — overskriv aldrig
    if [ -e "$archive" ]; then
        err "$tag $archive er dukket op undervejs — overskriver ikke, mappen bevares"
        rm -f -- "$partial"
        CURRENT_PARTIAL=""
        return 1
    fi
    if ! mv -T -- "$partial" "$archive"; then
        err "$tag kunne ikke omdøbe $partial til $archive — mappen bevares"
        return 1
    fi
    CURRENT_PARTIAL=""
    sync -- "$hostdir" 2>/dev/null || sync
    log "$tag arkiv gemt og valideret: $archive"

    delete_dir "$dir" "$tag" || return 1
    log "$tag FÆRDIG — mappen er erstattet af $(basename "$archive")"
    return 0
}

process_dir() {
    local dir=$1 rc=0
    local name="${dir##*/}" tag
    tag="[$(basename "$(dirname "$dir")")/$name]"

    # Sikkerhedsnet: stien skal være <rod>/<host>/YYYY-MM-DD, en rigtig mappe og ikke et symlink
    if [[ "$dir" != "$BACKUP_ROOT"/*/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] ]] || [ -L "$dir" ] || [ ! -d "$dir" ]; then
        err "$tag uventet sti, rører den ikke: $dir"
        return 1
    fi

    # Hold v6's lås for datoen, så backup-scriptet ikke kan skrive i mappen undervejs
    exec 9>>"$BACKUP_LOCK_DIR/rsync_backup_$name.lock"
    if ! flock -n 9; then
        exec 9>&-
        warn "$tag backup-scriptet kører på denne dato — springes over"
        return 2
    fi
    process_locked "$dir" || rc=$?
    flock -u 9 2>/dev/null || true
    exec 9>&-
    return "$rc"
}

# -----------------------
# Find dato-mapper: <rod>/<host>/YYYY-MM-DD/
# -----------------------
shopt -s nullglob
CANDIDATES=()
for hostdir in "$BACKUP_ROOT"/*/; do
    hostdir="${hostdir%/}"
    host="${hostdir##*/}"
    case "$host" in Log|lost+found) continue ;; esac
    if [ -L "$hostdir" ]; then
        warn "springer over $hostdir (symlink)"
        continue
    fi
    for d in "$hostdir"/*/; do
        d="${d%/}"
        name="${d##*/}"
        [[ "$name" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || continue
        [ "$(date -d "$name" +%F 2>/dev/null || true)" = "$name" ] || continue
        if [ -L "$d" ]; then
            warn "springer over $d (symlink)"
            continue
        fi
        CANDIDATES+=("$d")
    done
done

# -----------------------
# Plan
# -----------------------
echo
echo "=== BACKUP ARKIVERING v1 ==="
echo "Backup-rod:   $BACKUP_ROOT   (disk monteret på $FS_TARGET)"
echo "Komprimering: $COMP_NAME"
echo "Ledig plads:  $(hsize "$(df -B1 --output=avail -- "$BACKUP_ROOT" | tail -n 1 | tr -d ' ')")"
if $DRY_RUN; then echo "Tilstand:     DRY-RUN — intet ændres"; fi
echo

if [ ${#CANDIDATES[@]} -eq 0 ]; then
    echo "Ingen dato-mapper (YYYY-MM-DD) at arkivere under $BACKUP_ROOT."
    exit 0
fi

echo "Dato-mapper (pr. host, ældste først):"
for d in "${CANDIDATES[@]}"; do
    name="${d##*/}"
    host="$(basename "$(dirname "$d")")"
    st="$(backup_status "$host" "$name")"
    if backup_running "$name"; then
        action="springes over: backup kører lige nu"
    elif is_empty_dir "$d"; then
        action="springes over: tom mappe"
    elif [ -e "$(dirname "$d")/$name$ARCHIVE_SUFFIX" ]; then
        action="$name$ARCHIVE_SUFFIX findes — valideres; mappen slettes kun hvis identisk"
    else
        action="pakkes til $name$ARCHIVE_SUFFIX, valideres, mappen slettes"
    fi
    [ "$st" = "SUCCESS" ] || action="$action  (OBS: backup-status $st)"
    printf '  %-32s backup: %-8s -> %s\n' "$host/$name" "$st" "$action"
done
echo

if $DRY_RUN; then
    echo "DRY-RUN: intet er ændret."
    exit 0
fi

if ! $ASSUME_YES; then
    if [ ! -t 0 ]; then
        echo "FEJL: Ingen terminal til bekræftelse. Kør interaktivt eller brug -y."
        exit 1
    fi
    read -r -p "Fortsæt? Hver mappe slettes først når dens arkiv er valideret. [j/N] " answer
    case "${answer,,}" in
        j|ja|y|yes) ;;
        *) echo "Afbrudt — intet ændret."; exit 0 ;;
    esac
fi

# -----------------------
# Log
# -----------------------
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/archive_$(date +%Y-%m-%d_%H%M%S).log"
RUN_START=$SECONDS
log "=== BACKUP ARKIVERING START ==="
log "Rod: $BACKUP_ROOT  Komprimering: $COMP_NAME  Mapper: ${#CANDIDATES[@]}  PID: $$"

# -----------------------
# Behandl
# -----------------------
N_OK=0
N_SKIP=0
N_FAIL=0
for d in "${CANDIDATES[@]}"; do
    log "-----------------------------------------"
    rc=0
    process_dir "$d" || rc=$?
    case "$rc" in
        0) N_OK=$((N_OK + 1)) ;;
        2) N_SKIP=$((N_SKIP + 1)) ;;
        *) N_FAIL=$((N_FAIL + 1)) ;;
    esac
done

# -----------------------
# Resultat
# -----------------------
log "========================================="
log "=== BACKUP ARKIVERING SLUT ($(fmt_dur $((SECONDS - RUN_START)))) ==="
log "Arkiveret og mappe slettet: $N_OK"
log "Sprunget over:              $N_SKIP"
log "Fejlet (mappe bevaret):     $N_FAIL"
log "Ledig plads nu:             $(hsize "$(df -B1 --output=avail -- "$BACKUP_ROOT" | tail -n 1 | tr -d ' ')")"
log "Log: $LOG_FILE"

if [ "$N_FAIL" -gt 0 ]; then
    echo "--- FEJL --- Se loggen. Ingen mappe er slettet uden et valideret arkiv."
    exit 1
fi
echo "--- SUCCESS ---"
exit 0
