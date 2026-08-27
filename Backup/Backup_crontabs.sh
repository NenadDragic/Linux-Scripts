#!/usr/bin/env bash
#
# backup_crontabs.sh — gemmer hver brugers crontab i sin egen fil.
#
#   Filnavn:  crontab_<brugernavn>_<YYYY-MM-DD>.txt
#   Indhold:  rå crontab, dvs. kan gendannes med:
#             crontab -u <bruger> crontab_<bruger>_<dato>.txt
#
# Kræver root for at kunne læse andre brugeres crontabs.
#
set -euo pipefail

OUTDIR="/var/backups/crontabs"
KEEP_DAYS=0          # 0 = ryd ikke op
INCLUDE_SYSTEM=0     # -s: tag også /etc/crontab og /etc/cron.d/*
DRY_RUN=0
QUIET=0
USERS=()
DATE="$(date +%F)"

usage() {
    cat <<EOF
Brug: ${0##*/} [-d katalog] [-u bruger]... [-k dage] [-s] [-n] [-q] [-h]

  -d KATALOG   Output-katalog (standard: $OUTDIR)
  -u BRUGER    Kun denne bruger (kan gentages). Standard: alle brugere i NSS/passwd
  -k DAGE      Slet backupfiler ældre end DAGE dage i output-kataloget
  -s           Gem også system-cron (/etc/crontab + /etc/cron.d/*)
  -n           Dry-run: vis hvad der ville ske, skriv ingenting
  -q           Stille (kun fejl)
  -h           Denne hjælp
EOF
}

log()  { (( QUIET )) || printf '%s\n' "$*"; }
err()  { printf '%s: FEJL: %s\n' "${0##*/}" "$*" >&2; }
warn() { printf '%s: ADVARSEL: %s\n' "${0##*/}" "$*" >&2; }

while getopts ":d:u:k:snqh" opt; do
    case "$opt" in
        d) OUTDIR="$OPTARG" ;;
        u) USERS+=("$OPTARG") ;;
        k) KEEP_DAYS="$OPTARG" ;;
        s) INCLUDE_SYSTEM=1 ;;
        n) DRY_RUN=1 ;;
        q) QUIET=1 ;;
        h) usage; exit 0 ;;
        :)  err "-$OPTARG kræver et argument"; usage >&2; exit 2 ;;
        \?) err "ukendt option: -$OPTARG";     usage >&2; exit 2 ;;
    esac
done

[[ "$KEEP_DAYS" =~ ^[0-9]+$ ]] || { err "-k skal være et helt tal"; exit 2; }
command -v crontab >/dev/null || { err "crontab-kommandoen blev ikke fundet"; exit 3; }

# Brugerliste: getent fanger både lokale og evt. AD/LDAP-brugere
if (( ${#USERS[@]} == 0 )); then
    mapfile -t USERS < <(getent passwd | cut -d: -f1 | sort -u)
fi

# Uden root kan man kun læse sin egen crontab
if (( EUID != 0 )); then
    warn "kører ikke som root — begrænser til brugeren $(id -un)"
    USERS=("$(id -un)")
    INCLUDE_SYSTEM=0
fi

umask 077
if (( ! DRY_RUN )); then
    mkdir -p -- "$OUTDIR"
    chmod 700 -- "$OUTDIR"
fi

written=0
skipped=0

save() {   # save <filnavn-del> <indhold>
    local name="$1" content="$2" outfile
    # gør brugernavnet filnavns-sikkert (fx DOMAIN\bruger fra AD)
    name="${name//[^A-Za-z0-9._@-]/_}"
    outfile="$OUTDIR/crontab_${name}_${DATE}.txt"
    if (( DRY_RUN )); then
        log "[dry-run] ville skrive $outfile"
    else
        printf '%s\n' "$content" > "$outfile"
        chmod 600 -- "$outfile"
        log "Skrev $outfile"
    fi
    (( ++written ))
}

for user in "${USERS[@]}"; do
    # crontab -l fejler hvis brugeren ikke har nogen crontab
    if ! content="$(crontab -l -u "$user" 2>/dev/null)"; then
        (( ++skipped )); continue
    fi
    # spring over crontabs der kun består af tomme linjer/kommentarer
    if ! grep -qvE '^[[:space:]]*(#|$)' <<<"$content"; then
        (( ++skipped )); continue
    fi
    save "$user" "$content"
done

if (( INCLUDE_SYSTEM )); then
    sys=""
    for f in /etc/crontab /etc/cron.d/*; do
        [[ -f "$f" ]] || continue
        sys+="### $f"$'\n'"$(cat -- "$f")"$'\n\n'
    done
    [[ -n "$sys" ]] && save "system" "$sys"
fi

if (( KEEP_DAYS > 0 && ! DRY_RUN )); then
    while IFS= read -r old; do
        log "Slettede gammel backup: $old"
    done < <(find "$OUTDIR" -maxdepth 1 -type f \
                  -name 'crontab_*_[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].txt' \
                  -mtime +"$KEEP_DAYS" -print -delete)
fi

if (( DRY_RUN )); then
    log "Færdig (dry-run): $written fil(er) ville blive skrevet, $skipped bruger(e) uden crontab."
else
    log "Færdig: $written fil(er) skrevet, $skipped bruger(e) uden crontab sprunget over."
fi
