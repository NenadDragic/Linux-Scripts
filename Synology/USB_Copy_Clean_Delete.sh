#!/bin/bash
# Version:      2.5
# Date:         2026-10-12
# Test Run:     2026-10-12 (Run, v2.4)
# Developper:   Nenad(a)dragic(.)com

# USB_Copy_Clean_Delete - samlet opgave. Erstatter "Backup USB Disk", "Delete the oldest backups - Count 3"
# og "Disk Used size - NetBackup".
# Ligger som fil på NAS'en og kaldes fra en DSM-opgave (bruger root), der sætter parametrene:
#     export MODE=Dryrun      # Dryrun = vis kun, hvad der ville ske | Run = udfør
#     export KEEP=3           # backups, der beholdes pr. mappe
#     export LOG_DAYS=0       # slet logfiler ældre end N dage (0 = slået fra)
#     export NOPRUNE=""       # mapper uden oprydning, mellemrumsadskilt, fx "Ubuntu_Learning Ubuntu_MISC"
#     bash /volume1/root-scripts/USB_Copy_Clean_Delete.sh
# Mangler en parameter, bruges standardværdien nedenfor (MODE er som standard Dryrun).
#
#  1. Flytter alle mapper fra USB-disken til NetBackup (usbshare/<mappe>/ -> NetBackup/<mappe>/)
#     og giver nye filer og mapper den ACL, de arver fra mappen over (som de gamle backups har)
#  2. Beholder de KEEP nyeste backups (YYYY-MM-DD*.zip og YYYY-MM-DD*.gz, sorteret efter navn)
#     i hver mappe og sletter resten - men kun hvis den nyeste backup består en integritetstest
#  3. Sletter logfiler i NetBackup/Log, der er ældre end LOG_DAYS dage (0 = slået fra)
#  4. Viser pladsforbrug
# Alle trin køres, også hvis et tidligere trin fejler. Det er sikkert, fordi rsync skriver
# til en skjult midlertidig fil og først omdøber, når filen er hel - en halv kopi tæller
# derfor aldrig som backup.
# Output skrives også til /tmp/USB_Copy_Clean_Delete.log, så en kørsel kan følges med:
#     tail -f /tmp/USB_Copy_Clean_Delete.log
# Exit: 0 = OK, 1 = et trin fejlede, 2 = forkert opsætning, 3 = Dryrun
#       Dryrun afslutter med 3, så DSM sender resultatet pr. mail, og så en opgave,
#       der ved en fejl står på Dryrun, ikke kører lydløst uden at gøre noget.

# Kræver bash. Køres filen via sh (bash i POSIX-tilstand), slås POSIX-tilstanden fra.
[ -n "$BASH_VERSION" ] || { echo "FEJL: skal køres af bash"; exit 2; }
set +o posix

# ======== PARAMETRE - sættes i DSM-opgaven; værdierne her er standarder ========
MODE=${MODE:-Dryrun}
KEEP=${KEEP:-3}
LOG_DAYS=${LOG_DAYS:-0}
read -r -a NOPRUNE_DIRS <<< "${NOPRUNE-}"
USB_MARKER=${USB_MARKER-.netbackup-usb}   # Markørfil i roden af den rigtige USB-disk ("" = intet tjek)
USB=${USB:-/volumeUSB1/usbshare}
DST=${DST:-/volume1/NetBackup}
# ================================================================================

# Mapper i roden af USB, der aldrig flyttes. Navne, der starter med @ eller ., springes altid over.
SKIP_USB=('#recycle' 'System Volume Information' '$RECYCLE.BIN' 'lost+found')

# Kun filer, der starter med en dato og ender på .zip eller .gz, betragtes som backups - alt andet røres aldrig
DATE_GLOB='[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]*'

# -rlt i stedet for -a: rsync ændrer aldrig ejer, gruppe eller rettigheder på NetBackups mapper
#   (chmod fjerner DSM's ACL). -t er nødvendig, fordi sletningen fra USB sammenligner størrelse + mtime.
# -u: overskriv aldrig en nyere fil i NetBackup - den bliver liggende på USB og meldes som fejl
RSYNC_OPTS=(-rlt -u --exclude='@eaDir' --exclude='#recycle')

case ${MODE,,} in
    dryrun) DRY=1 ;;
    run)    DRY=0 ;;
    *)      echo "FEJL: MODE skal være Dryrun eller Run (er: '$MODE')"; exit 2 ;;
esac
[[ $KEEP =~ ^[1-9][0-9]*$ ]] || { echo "FEJL: KEEP skal være et tal på mindst 1 (er: '$KEEP')"; exit 2; }
[[ $LOG_DAYS =~ ^[0-9]+$ ]]  || { echo "FEJL: LOG_DAYS skal være et tal (er: '$LOG_DAYS')"; exit 2; }
(( EUID == 0 )) || { echo "FEJL: skal køres som root"; exit 2; }
[[ -d $DST ]]   || { echo "FEJL: $DST findes ikke"; exit 1; }

exec 9>/tmp/USB_Copy_Clean_Delete.lock
flock -n 9 || { echo "FEJL: USB_Copy_Clean_Delete kører allerede"; exit 1; }

# Output går både til DSM (mail) og til /tmp/USB_Copy_Clean_Delete.log
exec > >(tee /tmp/USB_Copy_Clean_Delete.log) 2>&1

shopt -s nullglob

if   command -v unzip >/dev/null 2>&1; then ZIPTEST=unzip
elif command -v 7z    >/dev/null 2>&1; then ZIPTEST=7z
else ZIPTEST=
fi

in_list() {
    local x=$1 s; shift
    for s; do [[ $x == "$s" ]] && return 0; done
    return 1
}

# Tester hele filen - store backups tager tid
backup_ok() {
    case $1 in
        *.gz)  gzip -t "$1" >/dev/null 2>&1 ;;
        *.zip) case $ZIPTEST in
                   unzip) unzip -tqq "$1" >/dev/null 2>&1 ;;
                   7z)    7z t "$1" >/dev/null 2>&1 ;;
                   *)     [[ -s $1 ]] ;;   # intet testværktøj - kræv kun, at filen ikke er tom
               esac ;;
        *)     return 1 ;;
    esac
}

# rsync fjerner DSM's nedarvede ACL på de filer og mapper, den opretter - de bliver root-only.
# Genskaber nedarvningen for alt under $1 (inkl. $1), der mangler ACL ("Linux mode").
# find lister mapper før deres indhold, så en ny mappe får sin ACL, før dens filer arver fra den.
fix_acl() {
    local p n=0 err=0
    command -v synoacltool >/dev/null 2>&1 || { echo "synoacltool findes ikke - ACL springes over"; return 0; }
    while IFS= read -r -d '' p; do
        synoacltool -get "$p" 2>&1 | grep -q 'Linux mode' || continue
        if (( DRY )); then n=$((n+1)); continue; fi
        if synoacltool -enforce-inherit "$p" >/dev/null 2>&1; then n=$((n+1))
        else echo "FEJL: kunne ikke sætte ACL på $p"; err=1
        fi
    done < <(find "$1" \( -name '@eaDir' -o -name '#recycle' -o -name '@tmp' \) -prune -o -print0)
    if (( n )); then
        if (( DRY )); then echo "${1##*/}: $n fil(er)/mappe(r) i NetBackup mangler ACL"
        else               echo "${1##*/}: ACL nedarvet på $n fil(er)/mappe(r)"
        fi
    fi
    return $err
}

move_usb() {
    local d name dirs=() left loose aclerr=0
    echo
    echo "=== 1. Flytter fra USB-disken ==="
    if ! grep -qs " $USB " /proc/mounts; then
        echo "USB-disken er ikke monteret ($USB) - springes over"
        return 0
    fi
    if [[ -n $USB_MARKER && ! -e $USB/$USB_MARKER ]]; then
        echo "FEJL: $USB mangler markørfilen $USB_MARKER - er det den rigtige disk? Intet flyttes"
        return 1
    fi

    for d in "$USB"/*/; do
        name=${d%/}; name=${name##*/}
        [[ $name == @* ]] && continue
        in_list "$name" "${SKIP_USB[@]}" && continue
        dirs+=("$name")
    done
    (( ${#dirs[@]} )) || { echo "Ingen mapper på USB - intet at flytte"; return 0; }
    echo "Mapper på USB: ${dirs[*]}"

    echo "--- Kopierer"
    for name in "${dirs[@]}"; do
        echo "--- $name"
        if (( DRY )); then
            rsync "${RSYNC_OPTS[@]}" -n -i "$USB/$name/" "$DST/$name/" \
                || { echo "FEJL under tørkørsel af $name"; return 1; }
            [[ -e $DST/$name ]] && fix_acl "$DST/$name"
            continue
        fi
        rsync "${RSYNC_OPTS[@]}" --stats -h "$USB/$name/" "$DST/$name/" \
            || { echo "FEJL under kopiering af $name - intet er slettet fra USB"; return 1; }
    done
    (( DRY )) && { echo "(Dryrun: intet kopieret eller slettet - trin 2 tæller derfor ikke filerne ovenfor med)"; return 0; }

    echo "--- Sletter fra USB"
    for name in "${dirs[@]}"; do
        # Sletter kun filer, der er overført nu eller allerede matcher i NetBackup (størrelse + mtime)
        rsync "${RSYNC_OPTS[@]}" --remove-source-files "$USB/$name/" "$DST/$name/" \
            || { echo "FEJL i slettefasen for $name"; return 1; }
        # Tomme undermapper fjernes - selve mappen (Log, <enhed>) beholdes
        find "$USB/$name" -mindepth 1 -depth -type d -empty -delete
        fix_acl "$DST/$name" || aclerr=1
        echo "$name: færdig"
    done

    echo "--- Kontrol"
    left=$(for name in "${dirs[@]}"; do
               find "$USB/$name" ! -type d ! -path '*/@eaDir/*' ! -path '*/#recycle/*'
           done)
    loose=$(find "$USB" -mindepth 1 -maxdepth 1 -type f ! -name '.*')
    [[ -n $loose ]] && printf 'Løse filer i roden af USB (flyttes ikke):\n%s\n' "$loose"
    if [[ -n $left ]]; then
        printf 'Disse filer ligger stadig på USB:\n%s\n' "$left"
        return 1
    fi
    (( aclerr )) && { echo "Alle mapper er flyttet, men ACL kunne ikke sættes på alt - se ovenfor"; return 1; }
    echo "Alle mapper er flyttet."
}

prune() {
    local rc=0 dir name files n f verb=sletter
    (( DRY )) && verb="ville slette"
    echo
    echo "=== 2. Rydder op i backups (beholder $KEEP nyeste pr. mappe; test: zip=${ZIPTEST:-kun størrelse}, gz=gzip) ==="
    (( ${#NOPRUNE_DIRS[@]} )) && echo "Uden oprydning: ${NOPRUNE_DIRS[*]}"
    for dir in "$DST"/*/; do
        name=${dir%/}; name=${name##*/}
        [[ $name == [@#.]* || $name == Log ]] && continue
        in_list "$name" "${NOPRUNE_DIRS[@]}" && continue

        # Navnene starter med YYYY-MM-DD, så navnesortering er kronologisk (mtime er kopieringstidspunktet)
        mapfile -d '' files < <(find "$dir" -mindepth 1 -maxdepth 1 -type f \
                                    \( -name "$DATE_GLOB.zip" -o -name "$DATE_GLOB.gz" \) -print0 | sort -z)
        n=${#files[@]}
        if (( n <= KEEP )); then
            echo "$name: $n backup(s) - intet at slette"
            continue
        fi
        echo "$name: tester nyeste backup ${files[n-1]##*/}"
        if ! backup_ok "${files[n-1]}"; then
            echo "FEJL: $name: nyeste backup ${files[n-1]##*/} fejler integritetstesten - intet slettes"
            rc=1
            continue
        fi
        for f in "${files[@]:0:n-KEEP}"; do
            echo "$name: $verb ${f##*/}"
            (( DRY )) || rm -f -- "$f" || rc=1
        done
    done
    return $rc
}

prune_logs() {
    echo
    if (( LOG_DAYS <= 0 )); then
        echo "=== 3. Logoprydning er slået fra (LOG_DAYS=0) ==="
        return 0
    fi
    echo "=== 3. Logfiler ældre end $LOG_DAYS dage ==="
    [[ -d $DST/Log ]] || return 0
    if (( DRY )); then
        find "$DST/Log" -type f -mtime +"$LOG_DAYS" ! -path '*/@eaDir/*' -printf 'ville slette %p\n'
    else
        find "$DST/Log" -type f -mtime +"$LOG_DAYS" ! -path '*/@eaDir/*' -printf 'sletter %p\n' -delete
    fi
}

report() {
    echo
    echo "=== 4. Pladsforbrug (første linje = total med samme udeladelser) ==="
    du -ha --max-depth=2 --exclude='@eaDir' --exclude='@tmp' "$DST" 2>/dev/null | sort -k2
    echo
    df -h "$DST"
}

echo "=== USB_Copy_Clean_Delete $(date '+%F %T') - MODE=$MODE KEEP=$KEEP LOG_DAYS=$LOG_DAYS ==="
(( DRY )) && echo "DRYRUN - intet kopieres eller slettes"

rc=0
move_usb   || rc=1
prune      || rc=1
prune_logs || rc=1
report

echo
if   (( rc ));  then echo "=== Afsluttet med fejl - se ovenfor ==="
elif (( DRY )); then echo "=== Dryrun færdig - sæt MODE=Run for at udføre ==="; rc=3
else                 echo "=== OK ==="
fi
exit $rc
