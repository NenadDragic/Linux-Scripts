#!/usr/bin/env bash
#
# WD_Backup.sh — kopiér NAS-shares til det krypterede WD Elements-drev.
#
#   /mnt/NetBackup  ->  <drev>/NetBackup
#   /mnt/Dragic     ->  <drev>/Dragic
#   /mnt/DashCam    ->  <drev>/DashCam
#
# Scriptet låser drevet op og monterer det, hvis det ikke allerede er monteret,
# kopierer hvert job med rsync og viser samlet fremdrift undervejs.
# NAS-shares, der ikke allerede er monteret, monteres via File_Handle/SMB.sh
# før kopieringen og afmonteres igen bagefter (kun dem scriptet selv monterede).
#
# Fremdriftens tællere vises med dansk tusindtalsseparator:
#   (xfr#23262, ir-chk=6513/151321) -> (xfr#23.262, ir-chk=6.513/151.321)
# Slå det fra med --raatal, hvis du vil have rsyncs rå output.
#
# --mangler tæller, hvor mange filer og hvor meget data der mangler at blive
# kopieret, uden at kopiere noget. --tael-foerst tæller først og kopierer så.
#
# Brug:   sudo ./WD_Backup.sh [tilvalg]
# Hjælp:  ./WD_Backup.sh --hjaelp
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
TORLOEB=0; SPEJL=0; LUK=0; KUN=""; MAAL_OVERRIDE=""; PLADS=0; RAATAL=0; MANGLER=0; KOPIER_EFTER=0
FEJLET=0

RED=$'\033[0;31m'; GRN=$'\033[0;32m'; YEL=$'\033[0;33m'
BLU=$'\033[0;34m'; BLD=$'\033[1m'; NC=$'\033[0m'
[[ -t 1 ]] || { RED=""; GRN=""; YEL=""; BLU=""; BLD=""; NC=""; }

WE_MOUNTED=0
WE_OPENED=0
declare -A TALT_TXT=() INTET_AT_GOERE=()
MOUNT=""
LOG=""

hjaelp() {
  cat <<EOF
${BLD}WD_Backup.sh${NC} — kopiér NAS-shares til det krypterede WD-drev

  sudo $0 [tilvalg]

Tilvalg:
  --torloeb, -n     Tørløb. Viser hvad der ville blive kopieret, rører intet.
  --mangler         Tæl hvor mange filer og hvor meget data der mangler at blive
                    kopieret, pr. job og i alt. Rører intet. Med --spejl tælles
                    også de filer, der ville blive slettet — inkl. filer på
                    drevet, der matcher en udeladelse (@eaDir, #recycle ...).
  --tael-foerst     Som --mangler, men kopierer bagefter. Koster en ekstra
                    gennemgang af alle filer, før kopieringen går i gang.
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
#
# Er fremdriftslinjen bredere end terminalen (fx tmux på en telefon), brækker
# den om, og \r kan ikke længere overskrive den: hver opdatering bliver en ny
# linje, og alt ovenover ruller væk. Derfor gøres linjen smallere på skærmen:
# fyld-mellemrum fjernes, derefter hastighed og tid, og til sidst klippes den.
# Loggen får altid den fulde linje.
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

    # Terminalens bredde, 0 hvis stdout ikke er en terminal (TIOCGWINSZ, Linux).
    sub bredde {
      my $ws = "\0" x 8;
      ioctl(STDOUT, 0x5413, $ws) or return 0;
      my (undef, $c) = unpack("S2", $ws); $c || 0
    }
    sub tilpas {
      my ($t, $b) = @_;
      $t =~ s/^\s+//; $t =~ s/\s+$//; $t =~ s/\s{2,}/ /g;
      return $t if length($t) < $b;
      $t =~ s/ \S+\/s(?= )//;               # hastighed
      return $t if length($t) < $b;
      $t =~ s/ \d+:\d\d:\d\d(?= |$)//;      # tid
      return $t if length($t) < $b;
      substr($t, 0, $b - 1)
    }

    sub behandl {
      my $l = shift;
      # (xfr#23262, ir-chk=6513/151321) -> (xfr#23.262, ir-chk=6.513/151.321)
      $l =~ s{\((xfr\#[^)]*)\)}{ my $p = $1; $p =~ s/(\d+)/grupper($1)/ge; "($p)" }ge;
      # byte-tælleren forrest i fremdriftslinjen: 12,345,678 99% -> 12.345.678 99%
      $l =~ s{^(\s*)(\d{1,3}(?:,\d{3})+)(\s+\d+%)}{$1 . dansk($2) . $3}e;
      # rsyncs egne opsummeringslinjer til sidst
      $l =~ s{\b(\d{1,3}(?:,\d{3})+(?:\.\d+)?)\b}{dansk($1)}ge
        if $l =~ /^(sent|received|total size|Number of|Total |Literal data|Matched data|File list)/;
      my $b = bredde();
      if ($b > 0 && $l =~ /\A(\s*[\d.,]+[KMGTP]?\s+\d+%[^\r\n]*)([\r\n])\z/) {
        print tilpas($1, $b), "\e[K", $2;
      } else {
        print $l;
      }
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

# ─── Hjælpere til optællingen (--mangler) ────────────────────────────────────
# Fremdrift under optællingen. rsync kører med --no-inc-recursive, så den
# først gennemgår hele kilden ("N files..." for hver 100 filer), derefter
# melder den totalen ("N files to consider") og skriver en ##-linje for hver
# fil, den sammenligner (--info=name2). Filteret tæller linjerne og viser en
# statuslinje på stderr, når VIS_STATUS=1. Alt andet (--stats) sendes videre
# på stdout, så scriptet kan læse tallene bagefter.
tael_status() {
  perl -e '
    use utf8;          # så length() tæller tegn, ikke bytes (å, ·)
    $| = 1;
    my $vis = $ENV{VIS_STATUS} ? 1 : 0;
    my ($fase, $fundet, $total, $tjekket, $mf, $mb, $slet, $aendr, $sletalt) = (0) x 9;
    my $t0 = time; my $t2 = $t0; my $sidst = -1;

    sub grp { my $n = reverse shift; $n =~ s/(\d{3})(?=\d)/$1./g; scalar reverse $n }
    sub hum {
      my $b = shift; my @u = ("B", "K", "M", "G", "T", "P"); my $i = 0;
      while ($b >= 1024 && $i < $#u) { $b /= 1024; $i++ }
      my $t = $i ? sprintf("%.1f", $b) : sprintf("%d", $b); $t =~ tr/./,/; "$t$u[$i]"
    }
    sub hms { my $x = shift; sprintf("%d:%02d:%02d", $x / 3600, ($x % 3600) / 60, $x % 60) }
    sub bredde {
      my $ws = "\0" x 8;
      ioctl(STDERR, 0x5413, $ws) or return 80;
      my (undef, $c) = unpack("S2", $ws); $c || 80
    }
    # Første variant, der kan stå på én linje uden at brække om.
    sub foerste_der_passer {
      my $b = bredde();
      for my $v (@_) { return $v if length($v) < $b }
      substr($_[-1], 0, $b - 1)
    }

    sub vis {
      my $tving = shift;
      return unless $vis;
      my $nu = time;
      return if !$tving && $nu == $sidst;
      $sidst = $nu;
      my $l;
      if ($fase < 2) {
        my $f = grp($fundet); my $t = hms($nu - $t0);
        $l = foerste_der_passer(
          "  Gennemgår kilden: $f filer fundet · $t",
          "  Kilden: $f filer · $t",
          "  $f filer");
      } else {
        my $pct = $total ? int(100 * $tjekket / $total) : 0;
        my $gaaet = $nu - $t2; my $eta = "";
        $eta = " · ~" . hms(int($gaaet * ($total - $tjekket) / $tjekket))
          if $tjekket > 0 && $gaaet >= 5 && $total > $tjekket;
        my $m = grp($mf) . " filer, " . hum($mb);
        my $af = "(" . grp($tjekket) . "/" . grp($total) . ")";
        $l = foerste_der_passer(
          "  Sammenligner: $pct % $af · mangler $m$eta" . ($eta ? " tilbage" : ""),
          "  Sammenligner: $pct % · mangler $m$eta",
          "  $pct % · mangler $m$eta",
          "  $pct % · $m$eta",
          "  $pct % · $m");
      }
      # syswrite: ét write() pr. opdatering, uden om Perls buffere. Med et
      # :encoding-lag på STDERR blev linjen holdt tilbage og kun skrevet ud i
      # bidder, når bufferen var fuld — så terminalen viste fx "Gennemgå".
      my $ud = "\r\e[K$l"; utf8::encode($ud); syswrite(STDERR, $ud);
    }

    my $buf = "";
    while (sysread(STDIN, my $c, 65536)) {
      $buf .= $c;
      while ($buf =~ s/\A([^\r\n]*)[\r\n]//) {
        my $l = $1;
        if ($l =~ /^##(.{11})\|(\d+)\|(.*)$/) {
          my ($i, $len, $navn) = ($1, $2, $3);
          if ($i =~ /^\*deleting/) { $sletalt++; $slet++ unless $navn =~ m{/$} }
          else {
            $tjekket++;
            if ($i =~ /^>f/) { $mf++; $mb += $len }
            # Første tegn "." = uændret eller kun attributter, og "h" uden
            # flag er et hardlink, der allerede er på plads. Alt andet (>, c,
            # nye hardlinks) skal en rigtig kørsel oprette eller skrive.
            $aendr++ if $i !~ /^\./ && $i !~ /^h.\s*$/;
          }
          vis(0);
        } elsif ($l =~ /^\s*(\d+) files\.\.\.\s*$/) {
          $fundet = $1; $fase = 1; vis(0);
        } elsif ($l =~ /^(\d+) files to consider\s*$/) {
          $total = $1; $fase = 2; $t2 = time; vis(1);
        } elsif ($l !~ /^building file list/) {
          print "$l\n";
        }
      }
    }
    print "$buf\n" if length $buf;
    print "##AENDRINGER $aendr\n##SLETNINGER $sletalt\n";
    syswrite(STDERR, "\r\e[K") if $vis;
  '
}

# Tusindtalsseparator uden at afhænge af locale (sudo nulstiller den ofte).
tusind() {
  local n=${1:-0} r=""
  while (( ${#n} > 3 )); do r=".${n: -3}$r"; n=${n:0:${#n}-3}; done
  printf '%s' "$n$r"
}
bytes_iec() { numfmt --to=iec "${1:-0}" | tr . ,; }

# Første tal på den --stats-linje, der begynder med $2.
stat_tal() {
  awk -v k="$2" 'index($0, k) == 1 { sub(/^[^:]*: */, ""); sub(/[^0-9].*/, ""); print; exit }' <<<"$1"
}
# Antal almindelige filer på linjen, der begynder med $2, fx
# "Number of deleted files: 7 (reg: 4, dir: 3)" -> 4. Det første tal på den
# slags linjer tæller også mapper med, og det er ikke det, vi vil vise.
stat_reg() {
  awk -v k="$2" 'index($0, k) == 1 { if (match($0, /reg: [0-9]+/)) print substr($0, RSTART + 5, RLENGTH - 5); exit }' <<<"$1"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --torloeb|--tørløb|-n) TORLOEB=1 ;;
    --mangler|--status)    MANGLER=1 ;;
    --tael-foerst|--tæl-først) MANGLER=1; KOPIER_EFTER=1 ;;
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

# ─── Montér NAS-shares ───────────────────────────────────────────────────────
# Kun de shares, der ikke allerede er monteret, monteres — og kun dem afmonteres
# igen bagefter. SMB.sh returnerer 0 selv ved fejl, så resultatet tjekkes med
# mountpoint.
SMB_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../File_Handle/SMB.sh"
declare -a SHARES_MOUNTED=()

afmontér_shares() {
  local navn
  for navn in "${SHARES_MOUNTED[@]}"; do
    if bash "$SMB_SCRIPT" "$navn" umount >>"$LOG" 2>&1; then
      info "Share $navn afmonteret"
    else
      advar "Kunne ikke afmontere share $navn"
    fi
  done
  SHARES_MOUNTED=()
}

montér_shares() {
  local job src navn
  for job in "${JOBS[@]}"; do
    src="${job%%:*}"; navn="${job##*:}"
    [[ -n "$KUN" && "$KUN" != "$navn" ]] && continue
    if mountpoint -q "$src" 2>/dev/null; then
      info "Share $navn er allerede monteret på $src"
      continue
    fi
    info "Monterer share $navn ..."
    bash "$SMB_SCRIPT" "$navn" mount >>"$LOG" 2>&1
    if mountpoint -q "$src" 2>/dev/null; then
      SHARES_MOUNTED+=("$navn")
      ok "Share $navn monteret på $src"
    else
      advar "Kunne ikke montere share $navn — jobbet springes over."
    fi
  done
}

[[ -f "$SMB_SCRIPT" ]] || doed "Kan ikke finde $SMB_SCRIPT"
trap afmontér_shares EXIT
montér_shares

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
# KOPIERER=1, når der bagefter skal kopieres (alt andet end ren --mangler).
KOPIERER=1; [[ $MANGLER -eq 1 && $KOPIER_EFTER -eq 0 ]] && KOPIERER=0
[[ $KOPIERER -eq 0 ]] && printf '%s\n' "${YEL}OPTÆLLING — der bliver ikke kopieret eller slettet noget${NC}"
[[ $KOPIER_EFTER -eq 1 ]] && printf '%s\n' "${BLU}Tæller først det manglende, kopierer derefter${NC}"
[[ $KOPIERER -eq 1 && $TORLOEB -eq 1 ]] && printf '%s\n' "${YEL}TØRLØB — der bliver ikke skrevet noget${NC}"
[[ $KOPIERER -eq 1 && $SPEJL   -eq 1 ]] && printf '%s\n' "${RED}SPEJLING — filer der mangler på kilden, slettes på drevet${NC}"
printf '\n'
log "Start. Mål=$MOUNT tørløb=$TORLOEB mangler=$MANGLER kopier_efter=$KOPIER_EFTER spejl=$SPEJL kun=${KUN:-alle} råtal=$RAATAL"

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

# ─── Optælling: hvad mangler at blive kopieret? (--mangler) ──────────────────
# rsync -n --stats bygger hele fillisten på begge sider og sammenligner
# størrelse og mtime præcis som en rigtig kørsel, men læser og skriver ingen
# fildata. "Number of regular files transferred" og "Total transferred file
# size" er dermed det, en rigtig kørsel ville kopiere lige nu. Filer, hvor kun
# rettigheder eller ejer afviger, tælles ikke med — de kopieres heller ikke,
# de får blot rettet attributterne.
if [[ $MANGLER -eq 1 ]]; then
  # --no-inc-recursive: hele fillisten bygges først, så totalen er kendt, og
  # fremdriften kan vises i procent. Koster lidt RAM (ca. 100 byte pr. fil).
  TAEL=( rsync -aH --dry-run --stats --no-human-readable --no-inc-recursive "${EXCLUDES[@]}" )
  [[ $SPEJL -eq 1 ]] && TAEL+=( --delete --delete-excluded )
  HAR_PERL=0; command -v perl >/dev/null && HAR_PERL=1
  [[ $HAR_PERL -eq 1 ]] && TAEL+=( '--info=flist2,name2' '--out-format=##%i|%l|%n' )
  VIS_STATUS=0; [[ -t 2 ]] && VIS_STATUS=1
  export VIS_STATUS

  declare -a LINJER=()

  sum_f=0; sum_fa=0; sum_b=0; sum_ba=0; sum_s=0; tael_fejl=0
  start_alle=$SECONDS

  for job in "${JOBS[@]}"; do
    src="${job%%:*}"; navn="${job##*:}"; dst="$MOUNT/$navn"
    [[ -n "$KUN" && "$KUN" != "$navn" ]] && continue

    if [[ ! -d "$src" ]]; then
      advar "$src findes ikke — springer over."; continue
    fi
    if ! mountpoint -q "$src" 2>/dev/null; then
      advar "$src er ikke et monteringspunkt. Er sharen fra NAS'en faldet af?"
    fi
    if [[ -z "$(ls -A "$src" 2>/dev/null)" ]]; then
      advar "$src er tom — springer over."; continue
    fi

    info "Tæller $navn (kan tage minutter) ..."
    t0=$SECONDS
    if [[ $HAR_PERL -eq 1 ]]; then
      ud=$("${TAEL[@]}" "$src/" "$dst/" 2> >(tee -a "$LOG" >&2) | tael_status
           exit "${PIPESTATUS[0]}")
    else
      ud=$("${TAEL[@]}" "$src/" "$dst/" 2> >(tee -a "$LOG" >&2))
    fi
    rc=$?
    printf '%s\n' "$ud" >>"$LOG"

    case $rc in
      0|24) ;;
      23) advar "$navn: nogle filer kunne ikke læses (rsync-kode 23) — tallene er et minimum." ;;
      *)  fejl "$navn: optællingen fejlede med rsync-kode $rc"; tael_fejl=1; continue ;;
    esac

    f=$(stat_tal "$ud" "Number of regular files transferred:")
    b=$(stat_tal "$ud" "Total transferred file size:")
    fa=$(stat_reg "$ud" "Number of files:")
    ba=$(stat_tal "$ud" "Total file size:")
    s=$(stat_reg "$ud" "Number of deleted files:")
    if [[ -z "$f" || -z "$b" ]]; then
      fejl "$navn: kunne ikke læse rsyncs --stats — se loggen."; tael_fejl=1; continue
    fi
    f=${f:-0}; b=${b:-0}; fa=${fa:-0}; ba=${ba:-0}; s=${s:-0}

    sum_f=$(( sum_f + f )); sum_fa=$(( sum_fa + fa ))
    sum_b=$(( sum_b + b )); sum_ba=$(( sum_ba + ba )); sum_s=$(( sum_s + s ))
    LINJER+=("$navn|$f|$fa|$b|$ba|$s")
    TALT_TXT[$navn]="$(tusind "$f") filer, $(bytes_iec "$b")"
    # Intet at gøre = optællingen lykkedes fuldt ud (ikke kode 23), og rsync
    # fandt hverken filer, mapper, links eller sletninger. Kræver perl-filteret.
    aendr=$(awk '/^##AENDRINGER /{print $2}' <<<"$ud")
    sletalt=$(awk '/^##SLETNINGER /{print $2}' <<<"$ud")
    if [[ $rc -ne 23 && "${aendr:-x}" == 0 && "${sletalt:-x}" == 0 ]]; then
      INTET_AT_GOERE[$navn]=1
    fi
    ok "$navn talt op på $(( SECONDS - t0 )) s"
    log "MANGLER $navn filer=$f/$fa bytes=$b/$ba slettes=$s"
  done

  printf '\n%s\n' "${BLD}Mangler at blive kopieret${NC}  (mangler/i alt)"
  # Kolonnen SLET (filer der slettes) vises kun med --spejl.
  if [[ $SPEJL -eq 1 ]]; then
    printf '  %-10s %17s %13s %7s\n' "JOB" "FILER" "DATA" "SLET"
  else
    printf '  %-10s %17s %13s\n' "JOB" "FILER" "DATA"
  fi
  for r in "${LINJER[@]}" "I ALT|$sum_f|$sum_fa|$sum_b|$sum_ba|$sum_s"; do
    IFS='|' read -r n f fa b ba s <<<"$r"
    [[ "$n" == "I ALT" && ${#LINJER[@]} -lt 2 ]] && continue
    kol_f="$(tusind "$f")/$(tusind "$fa")"
    kol_b="$(bytes_iec "$b")/$(bytes_iec "$ba")"
    if [[ $SPEJL -eq 1 ]]; then
      printf '  %-10s %17s %13s %7s\n' "$n" "$kol_f" "$kol_b" "$(tusind "$s")"
    else
      printf '  %-10s %17s %13s\n' "$n" "$kol_f" "$kol_b"
    fi
  done
  samlet=$(( SECONDS - start_alle ))
  printf '\n  Optællingen tog %02d:%02d:%02d\n' $((samlet/3600)) $((samlet%3600/60)) $((samlet%60))
  printf '  Fri plads på drevet: %s\n' "$(df -h --output=avail "$MOUNT" | tail -n1 | tr -d ' ')"
  printf '  Log: %s\n\n' "$LOG"

  if [[ $KOPIER_EFTER -eq 0 ]]; then
    [[ $LUK -eq 1 ]] && luk_drev
    exit "$tael_fejl"
  fi
  info "Kopierer nu det manglende ..."
  printf '\n'
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

  printf '%s\n' "${BLD}── $navn ──────────────────────────${NC}"

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

  if [[ $KOPIER_EFTER -eq 1 && -n "${INTET_AT_GOERE[$navn]:-}" ]]; then
    ok "$navn: intet mangler ifølge optællingen — springer over."
    RESULTAT+=("$navn|INTET NYT|-")
    printf '\n'; continue
  fi

  [[ $TORLOEB -eq 1 ]] || mkdir -p "$dst" || { fejl "Kunne ikke oprette $dst"; continue; }

  info "$src/  ->  $dst/"
  [[ -n "${TALT_TXT[$navn]:-}" ]] && info "Mangler ifølge optællingen: ${TALT_TXT[$navn]}"
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
printf '  %-10s %-13s %-8s %s\n' "JOB" "STATUS" "TID" "$( [[ $KOPIER_EFTER -eq 1 ]] && echo MANGLEDE )"
for r in "${RESULTAT[@]}"; do
  IFS='|' read -r n s t <<<"$r"
  farve="$GRN"; [[ "$s" == OK || "$s" == "INTET NYT" ]] || { farve="$YEL"; FEJLET=1; }
  printf '  %-10s %s%-13s%s %-8s %s\n' "$n" "$farve" "$s" "$NC" "$t" "${TALT_TXT[$n]:-}"
  log "RESULTAT $n $s $t ${TALT_TXT[$n]:-}"
done
printf '\n  Samlet tid: %02d:%02d:%02d\n' $((samlet/3600)) $((samlet%3600/60)) $((samlet%60))
printf '  Fri plads på drevet: %s\n' "$(df -h --output=avail "$MOUNT" | tail -n1 | tr -d ' ')"
printf '  Log: %s\n\n' "$LOG"

[[ $LUK -eq 1 ]] && luk_drev

# Afslutningskode: 0 kun hvis mindst ét job kørte, og alle kørte uden fejl.
# Så kan cron eller et andet script se, om backuppen lykkedes.
if [[ ${#RESULTAT[@]} -eq 0 ]]; then
  advar "Intet job blev kørt${KUN:+ — ukendt jobnavn for --kun: $KUN}."
  exit 1
fi
if [[ $FEJLET -eq 1 ]]; then
  advar "Mindst ét job blev ikke gennemført uden fejl — se opsummeringen og loggen."
  exit 1
fi
exit 0
