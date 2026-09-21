#!/usr/bin/env bash
#
# wd-backup-sync.sh — kopiér NAS-shares til det krypterede WD Elements-drev.
#
#   /mnt/NetBackup  ->  <drev>/NetBackup
#   /mnt/Dragic     ->  <drev>/Dragic
#   /mnt/DashCam    ->  <drev>/DashCam
#
# Scriptet låser drevet op og monterer det, hvis det ikke allerede er monteret,
# kopierer hvert job med rsync og viser samlet fremdrift undervejs.
#
# Fremdriftens tællere vises med dansk tusindtalsseparator:
#   (xfr#23262, ir-chk=6513/151321) -> (xfr#23.262, ir-chk=6.513/151.321)
# Slå det fra med --raatal, hvis du vil have rsyncs rå output.
#
# Brug:   sudo ./wd-backup-sync.sh [tilvalg]
# Hjælp:  ./wd-backup-sync.sh --hjaelp
#
# Nenad Dragic — Debian-Laptop

set -uo pipefail

# ─── Drevet ──────────────────────────────────────────────────────────────────
DISK_BYID="/dev/disk/by-id/usb-WD_Elements_25A3_4230315738365444-0:0"
LUKS_UUID="f77e78ad-3189-4e36-b912-82e42359049e"
FS_UUID="8154462f-dffc-481a-b95f-37f048a3236a"
MAPNAME="wd-backup"                  # navn når scriptet selv åbner drevet
KEYFILE="/root/wd-backup.key"        # bruges hvis den findes, ellers spørges om kode
FALLBACK_MOUNT="/mnt/backup"         # monteringspunkt når scriptet selv monterer

# ─── Kopijobs: kilde:målmappe-på-drevet ──────────────────────────────────────
JOBS=(
  "/mnt/NetBackup:NetBackup"
  "/mnt/Dragic:Dragic"
  "/mnt/DashCam:DashCam"
)

# ─── Udeladelser ─────────────────────────────────────────────────────────────
EXCLUDES=(
  --exclude='#recycle/'      # Synologys papirkurv
  --exclude='@eaDir/'        # Synologys miniaturer og indeks
  --exclude='#snapshot/'
  --exclude='.DS_Store'
  --exclude='Thumbs.db'
  --exclude='lost+found/'
)

# ─── Tilvalg ─────────────────────────────────────────────────────────────────
TORLOEB=0; SPEJL=0; LUK=0; KUN=""; MAAL_OVERRIDE=""; PLADS=0; RAATAL=0

RED=$'\033[0;31m'; GRN=$'\033[0;32m'; YEL=$'\033[0;33m'
BLU=$'\033[0;34m'; BLD=$'\033[1m'; NC=$'\033[0m'
[[ -t 1 ]] || { RED=""; GRN=""; YEL=""; BLU=""; BLD=""; NC=""; }

WE_MOUNTED=0
WE_OPENED=0
MOUNT=""
LOG=""

hjaelp() {
  cat <<EOF
${BLD}wd-backup-sync.sh${NC} — kopiér NAS-shares til det krypterede WD-drev

  sudo $0 [tilvalg]

Tilvalg:
  --torloeb, -n     Tørløb. Viser hvad der ville blive kopieret, rører intet.
  --spejl           Sletter filer på drevet, som ikke længere findes på kilden.
                    Uden dette tilføjes og opdateres der kun (sikrest).
  --kun NAVN        Kør kun ét job, fx: --kun DashCam
  --luk             Afmontér og lås drevet, når kopien er færdig.
  --plads           Mål kildernes størrelse først, og sammenlign med fri plads.
  --maal STI        Brug denne sti som mål i stedet for det monterede drev.
  --raatal          Vis rsyncs tal råt, uden dansk tusindtalsseparator.
  --hjaelp, -h      Denne tekst.

Jobs:
$(for j in "${JOBS[@]}"; do printf '  %-18s -> <drev>/%s\n' "${j%%:*}" "${j##*:}"; done)

Log skrives til ~/wd-backup-logs/. Kør gerne i tmux, så jobbet overlever,
at terminalvinduet lukkes:  tmux new -s backup
EOF
}

log() { printf '%s  %s\n' "$(date '+%F %T')" "$1" >>"$LOG"; }
info() { printf '%s\n' "${BLU}==>${NC} $1"; log "$1"; }
ok()   { printf '%s\n' "${GRN}==>${NC} $1"; log "OK: $1"; }
advar(){ printf '%s\n' "${YEL}==> ADVARSEL:${NC} $1"; log "ADVARSEL: $1"; }
fejl() { printf '%s\n' "${RED}==> FEJL:${NC} $1" >&2; [[ -n $LOG ]] && log "FEJL: $1"; }
doed() { fejl "$1"; exit 1; }

# ─── Læsbare tal i rsyncs fremdrift ──────────────────────────────────────────
# Sætter dansk tusindtalsseparator på tællerne. Læser strømmende og bevarer
# \r, så fremdriftslinjen stadig overskriver sig selv i terminalen. Filnavne
# røres ikke. Fuldendte linjer (dem der ender på \n) skrives også i loggen,
# så rsyncs sluttal står der bagefter.
paene_tal() {
  BACKUP_LOG="$LOG" perl -e '
    $| = 1;
    my $logfil = $ENV{BACKUP_LOG} || "";
    my $lf;
    if ($logfil ne "" && open($lf, ">>", $logfil)) {
      my $gl = select($lf); $| = 1; select($gl);
    } else {
      undef $lf;
    }

    sub grupper { my $n = reverse shift; $n =~ s/(\d{3})(?=\d)/$1./g; scalar reverse $n }
    sub dansk   { my $n = shift; $n =~ tr/,/./; $n =~ s/\.(\d{1,2})$/,$1/; $n }

    sub behandl {
      my $l = shift;
      # (xfr#23262, ir-chk=6513/151321) -> (xfr#23.262, ir-chk=6.513/151.321)
      $l =~ s{\((xfr\#[^)]*)\)}{ my $p = $1; $p =~ s/(\d+)/grupper($1)/ge; "($p)" }ge;
      # byte-tælleren forrest i fremdriftslinjen: 12,345,678 99% -> 12.345.678 99%
      $l =~ s{^(\s*)(\d{1,3}(?:,\d{3})+)(\s+\d+%)}{$1 . dansk($2) . $3}e;
      # rsyncs egne opsummeringslinjer til sidst
      $l =~ s{\b(\d{1,3}(?:,\d{3})+(?:\.\d+)?)\b}{dansk($1)}ge
        if $l =~ /^(sent|received|total size|Number of|Total |Literal data|Matched data|File list)/;
      print $l;
      print {$lf} $l if $lf && $l =~ /\n\z/;
    }

    my $buf = "";
    while (sysread(STDIN, my $c, 8192)) {
      $buf .= $c;
      behandl($1) while $buf =~ s/\A([^\r\n]*[\r\n])//;
    }
    behandl($buf) if length $buf;
  '
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --torloeb|--tørløb|-n) TORLOEB=1 ;;
    --spejl)               SPEJL=1 ;;
    --luk)                 LUK=1 ;;
    --plads)               PLADS=1 ;;
    --raatal|--råtal)      RAATAL=1 ;;
    --kun)                 KUN="${2:-}"; shift ;;
    --maal|--mål)          MAAL_OVERRIDE="${2:-}"; shift ;;
    --hjaelp|--hjælp|-h)   hjaelp; exit 0 ;;
    *) printf '%s\n' "Ukendt tilvalg: $1" >&2; hjaelp; exit 2 ;;
  esac
  shift
done

# ─── Log ─────────────────────────────────────────────────────────────────────
RUN_USER="${SUDO_USER:-${USER:-$(id -un)}}"
USER_HOME=$(getent passwd "$RUN_USER" | cut -d: -f6)
[[ -n "${USER_HOME:-}" ]] || USER_HOME="${HOME:-/tmp}"
LOGDIR="$USER_HOME/wd-backup-logs"
mkdir -p "$LOGDIR" 2>/dev/null || LOGDIR="/tmp"
LOG="$LOGDIR/wd-backup-$(date '+%Y%m%d-%H%M%S').log"
: >"$LOG"
chown "$RUN_USER": "$LOG" 2>/dev/null || true

# ─── Tjek af forudsætninger ──────────────────────────────────────────────────
for v in rsync findmnt; do
  command -v "$v" >/dev/null || doed "'$v' mangler. Installér med: sudo apt install $v"
done

# Uden perl kan tallene ikke pyntes — så kører vi bare råt videre.
if [[ $RAATAL -eq 0 ]] && ! command -v perl >/dev/null; then
  RAATAL=1
  advar "perl mangler — viser rsyncs tal råt. Installér med: sudo apt install perl"
fi

if [[ -z "$MAAL_OVERRIDE" && $EUID -ne 0 ]]; then
  doed "Kør scriptet med sudo — oplåsning, montering og læsning fra NAS-shares kræver root."
fi

# ─── Find eller montér drevet ────────────────────────────────────────────────
findmount_fs() { findmnt -n -o TARGET --source "UUID=$FS_UUID" 2>/dev/null | head -n1; }

montér_drev() {
  MOUNT=$(findmount_fs)
  if [[ -n "$MOUNT" ]]; then
    info "Drevet er allerede monteret på $MOUNT"
    return 0
  fi

  [[ -b "${DISK_BYID}-part1" ]] || doed "WD-drevet er ikke tilsluttet (${DISK_BYID}-part1 findes ikke)."

  local mapper=""
  if [[ -b "/dev/mapper/luks-$LUKS_UUID" ]]; then
    mapper="/dev/mapper/luks-$LUKS_UUID"          # skrivebordet har åbnet det
  elif [[ -b "/dev/mapper/$MAPNAME" ]]; then
    mapper="/dev/mapper/$MAPNAME"
  else
    info "Låser drevet op ..."
    if [[ -r "$KEYFILE" ]]; then
      cryptsetup open --key-file "$KEYFILE" "${DISK_BYID}-part1" "$MAPNAME" \
        || doed "Kunne ikke låse op med nøglefilen $KEYFILE"
    else
      cryptsetup open "${DISK_BYID}-part1" "$MAPNAME" \
        || doed "Kunne ikke låse drevet op."
    fi
    WE_OPENED=1
    mapper="/dev/mapper/$MAPNAME"
  fi

  mkdir -p "$FALLBACK_MOUNT"
  mount "$mapper" "$FALLBACK_MOUNT" || doed "Kunne ikke montere $mapper på $FALLBACK_MOUNT"
  WE_MOUNTED=1
  MOUNT="$FALLBACK_MOUNT"
  ok "Drevet monteret på $MOUNT"
}

luk_drev() {
  [[ $WE_MOUNTED -eq 1 ]] || { advar "Drevet var monteret i forvejen — det lukkes ikke."; return; }
  sync
  umount "$MOUNT" && ok "Afmonteret $MOUNT"
  if [[ $WE_OPENED -eq 1 ]]; then
    cryptsetup close "$MAPNAME" && ok "Drevet er låst igen"
  fi
}

if [[ -n "$MAAL_OVERRIDE" ]]; then
  MOUNT="$MAAL_OVERRIDE"
  [[ -d "$MOUNT" ]] || doed "Målstien findes ikke: $MOUNT"
  advar "Bruger $MOUNT som mål i stedet for det krypterede drev."
else
  montér_drev
fi

# ─── Byg rsync-kommandoen ────────────────────────────────────────────────────
# -a  = -rlptgoD. ACL (-A) og xattr (-X) udelades med vilje: NAS-shares
#       udleverer dem ikke, og rsync fejler med "Permission denied (13)".
RSYNC=( rsync -aH --partial --human-readable --info=progress2 "${EXCLUDES[@]}" )
# Når fremdriften sendes gennem et rør, er stdout ikke længere en terminal, og
# rsync begynder at blokbuffre. --outbuf=N holder fremdriften løbende.
[[ $RAATAL  -eq 0 ]] && RSYNC+=( --outbuf=N )
[[ $SPEJL   -eq 1 ]] && RSYNC+=( --delete --delete-excluded )
[[ $TORLOEB -eq 1 ]] && RSYNC+=( --dry-run --itemize-changes )

printf '\n%s\n' "${BLD}WD-backup  ·  $(date '+%F %T')${NC}"
printf '%s\n'   "Mål:  $MOUNT"
printf '%s\n'   "Log:  $LOG"
[[ $TORLOEB -eq 1 ]] && printf '%s\n' "${YEL}TØRLØB — der bliver ikke skrevet noget${NC}"
[[ $SPEJL   -eq 1 ]] && printf '%s\n' "${RED}SPEJLING — filer der mangler på kilden, slettes på drevet${NC}"
printf '\n'
log "Start. Mål=$MOUNT tørløb=$TORLOEB spejl=$SPEJL kun=${KUN:-alle} råtal=$RAATAL"

# ─── Valgfrit pladstjek ──────────────────────────────────────────────────────
if [[ $PLADS -eq 1 ]]; then
  info "Måler kildernes størrelse (kan tage et stykke tid over netværket) ..."
  total=0
  for job in "${JOBS[@]}"; do
    src="${job%%:*}"; navn="${job##*:}"
    [[ -n "$KUN" && "$KUN" != "$navn" ]] && continue
    [[ -d "$src" ]] || continue
    kb=$(du -sk --exclude='#recycle' --exclude='@eaDir' "$src" 2>/dev/null | cut -f1)
    total=$(( total + ${kb:-0} ))
    printf '    %-14s %s\n' "$navn" "$(numfmt --to=iec --from-unit=1024 "${kb:-0}")"
  done
  fri=$(df -k --output=avail "$MOUNT" | tail -n1)
  printf '    %-14s %s\n' "I alt" "$(numfmt --to=iec --from-unit=1024 "$total")"
  printf '    %-14s %s\n\n' "Fri plads" "$(numfmt --to=iec --from-unit=1024 "$fri")"
  log "Pladstjek: kilder=${total}K fri=${fri}K"
  if (( total > fri )); then
    doed "Der er ikke plads nok på drevet."
  fi
fi

# ─── Kør jobbene ─────────────────────────────────────────────────────────────
declare -a RESULTAT=()
start_alle=$SECONDS

for job in "${JOBS[@]}"; do
  src="${job%%:*}"
  navn="${job##*:}"
  dst="$MOUNT/$navn"

  if [[ -n "$KUN" && "$KUN" != "$navn" ]]; then
    continue
  fi

  printf '%s\n' "${BLD}── $navn ──────────────────────────────────────────${NC}"

  if [[ ! -d "$src" ]]; then
    advar "$src findes ikke — springer over."
    RESULTAT+=("$navn|SPRUNGET OVER|kilden findes ikke")
    printf '\n'; continue
  fi

  if ! mountpoint -q "$src" 2>/dev/null; then
    advar "$src er ikke et monteringspunkt. Er sharen fra NAS'en faldet af?"
  fi

  if [[ -z "$(ls -A "$src" 2>/dev/null)" ]]; then
    advar "$src er tom — springer over, så en tom kilde ikke kan tømme drevet."
    RESULTAT+=("$navn|SPRUNGET OVER|kilden er tom")
    printf '\n'; continue
  fi

  [[ $TORLOEB -eq 1 ]] || mkdir -p "$dst" || { fejl "Kunne ikke oprette $dst"; continue; }

  info "$src/  ->  $dst/"
  start=$SECONDS

  # PIPESTATUS[0] er rsyncs egen kode — $? ville med et rør kunne komme fra
  # perl i stedet, og så blev 23/24 læst forkert.
  if [[ $RAATAL -eq 1 ]]; then
    "${RSYNC[@]}" "$src/" "$dst/" 2> >(tee -a "$LOG" >&2)
    rc=$?
  else
    "${RSYNC[@]}" "$src/" "$dst/" 2> >(tee -a "$LOG" >&2) | paene_tal
    rc=${PIPESTATUS[0]}
  fi

  varighed=$(( SECONDS - start ))
  tid=$(printf '%02d:%02d:%02d' $((varighed/3600)) $((varighed%3600/60)) $((varighed%60)))

  case $rc in
    0)  ok  "$navn færdig på $tid";                      RESULTAT+=("$navn|OK|$tid") ;;
    24) ok  "$navn færdig på $tid (filer forsvandt undervejs — normalt på en live-share)"
                                                         RESULTAT+=("$navn|OK|$tid") ;;
    23) advar "$navn: delvis overførsel, rsync-kode 23 — se loggen for hvilke filer"
                                                         RESULTAT+=("$navn|DELVIS|$tid") ;;
    20) advar "$navn afbrudt af brugeren (rsync-kode 20)"; RESULTAT+=("$navn|AFBRUDT|$tid")
        break ;;
    *)  fejl "$navn fejlede med rsync-kode $rc";          RESULTAT+=("$navn|FEJL $rc|$tid") ;;
  esac
  printf '\n'
done

# ─── Opsummering ─────────────────────────────────────────────────────────────
samlet=$(( SECONDS - start_alle ))
printf '%s\n' "${BLD}Opsummering${NC}"
printf '  %-14s %-14s %s\n' "JOB" "STATUS" "TID"
for r in "${RESULTAT[@]}"; do
  IFS='|' read -r n s t <<<"$r"
  farve="$GRN"; [[ "$s" == OK ]] || farve="$YEL"
  printf '  %-14s %s%-14s%s %s\n' "$n" "$farve" "$s" "$NC" "$t"
  log "RESULTAT $n $s $t"
done
printf '\n  Samlet tid: %02d:%02d:%02d\n' $((samlet/3600)) $((samlet%3600/60)) $((samlet%60))
printf '  Fri plads på drevet: %s\n' "$(df -h --output=avail "$MOUNT" | tail -n1 | tr -d ' ')"
printf '  Log: %s\n\n' "$LOG"

[[ $LUK -eq 1 ]] && luk_drev

exit 0