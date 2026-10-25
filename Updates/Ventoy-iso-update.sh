#!/usr/bin/env bash
#
# ventoy-iso-update.sh
#   Henter nye ISO-udgaver, verificerer dem kryptografisk mod udgiverens
#   fastlåste (pinned) nøgle-fingerprint og kopierer dem til Ventoy-nøglen.
#   Intet lægges på nøglen, før verifikationen er bestået, og kopien på
#   nøglen læses tilbage og sammenlignes med den verificerede fil.
#
# Version : 1.3 (2026-10-16)
# Udvikler: Nenad(a)dragic(.)com
#
# Brug:
#   ventoy-iso-update.sh [--run] [--only LISTE] [--allow-unsigned] [--no-copy]
#                        [--delete-old] [--clean-staging] [--dest DIR]
#                        [--staging DIR] [--list] [-h|--help]
#
#   (uden --run)      Dry-run. Henter kun små filer (nøgler, signaturer,
#                     checksums), verificerer dem og viser, hvad der ville ske.
#                     Intet ISO hentes, intet kopieres.
#   --run             Hent, verificér og kopiér.
#   --only LISTE      Kommasepareret liste af elementer eller grupper
#                     (se --list). Fx: --only tails,qubes  eller  --only fedora
#   --allow-unsigned  Tag også distroer med, der IKKE udgiver signaturer
#                     (deepin, elementary, pop, zorin). De verificeres kun mod
#                     en SHA-256 hentet over HTTPS eller fastlåst i scriptet.
#   --no-copy         Hent og verificér i staging, men kopiér ikke til nøglen.
#   --delete-old      Slet ældre versioner på nøglen efter vellykket kopi.
#                     Uden flaget listes de kun.
#   --clean-staging   Slet den hentede ISO i staging efter vellykket kopi.
#   --dest DIR        ISO-mappe på Ventoy (standard: /media/$USER/Ventoy/ISOs)
#   --staging DIR     Arbejdsmappe (standard: ~/Downloads/iso-staging)
#   --list            Vis elementer, grupper og versioner, og afslut.
#
# Ikke med (bevidst):
#   - Windows: Microsoft udleverer kun tidsbegrænsede downloadlinks.
#   - KDE neon: Desktop User Edition er p.t. ikke tilgængelig fra KDE.
#   - FreeBSD, Kali, Kodachi: kan tilføjes på samme måde ved behov.
#
# Exit-koder: 0 = alt OK/klar, 1 = mindst én fejl, 2 = brugsfejl.
#
set -Eeuo pipefail

# ---------------------------------------------------------------------------
# Versioner – opdatér her ved nye udgivelser.
# Debian, Fedora, Manjaro, openSUSE og Pop!_OS finder selv nyeste fil.
# ---------------------------------------------------------------------------
FEDORA_VER="45"                   # Fedora 45 er planlagt til 2026-10-20
MINT_VER="22.3"
MX_VER="25.3"
PARROT_VER="7.4"
QUBES_VER="4.3.2"
SOLUS_DATE="2026-04-18"
TAILS_VER="7.15"
UBUNTU_SERIES="26.04"
UBUNTU_VER="26.04.1"
POP_SERIES="24.04"
DEEPIN_VER="25.2.0"
# Manjaro: bruges kun, hvis den nyeste ikke kan findes på manjaro.org
MANJARO_KDE_FALLBACK="https://download.manjaro.org/kde/26.1.0/manjaro-kde-26.1.0-260812-linux71.iso"

# Usignerede distroer med fastlåst SHA-256 (fra udgiverens HTTPS-side 2026-10-16).
# Ved ny version: opdatér navn OG hash fra den officielle side.
ELEMENTARY_ISO="elementaryos-8.1-stable-amd64.20260219.iso"
ELEMENTARY_SHA256="bda93040d08c05911fb159f8150bf8f4ef2db6567ef6e2acd197cb6f395d3446"
#   kilde: https://elementary.io/docs/installation
ZORIN_VER="18.1"
ZORIN_SHA256="44649b97bd307fc4c8529205d098ebbf98575a1e1ba2ee7d7005b697af1721d5"
#   kilde: https://help.zorin.com/docs/getting-started/check-the-integrity-of-your-copy-of-zorin-os/

# ---------------------------------------------------------------------------
# Fastlåste nøgle-fingerprints (primærnøgle). Kilder:
#   Debian  : debian.org/CD/verify (Debian CD signing key 2011 og 2009)
#   Fedora  : fedoraproject.org/security (én nøgle pr. version)
#   Manjaro : forum.manjaro.org, "Manjaro Build Server"
#   Mint    : linuxmint-installation-guide.readthedocs.io/en/latest/verify.html
#   MX      : mxlinux.org/wiki/system/signed-iso-files (Xfce: Dolphin Oracle)
#   openSUSE: get.opensuse.org/tumbleweed
#   Parrot  : udstederfingerprint i den signerede 7.3-hashfil; nøgle-ID'et
#             7A8286AF0E81EE4A er det samme, som Parrots APT-arkiv bruger
#   Qubes   : doc.qubes-os.org/.../verifying-signatures (Master Signing Key)
#   Solus   : discuss.getsol.us, "Solus (Release & Engineering)"
#   Tails   : tails.net/install/expert
#   Ubuntu  : ubuntu.com/tutorials/how-to-verify-ubuntu (CD Image Key 2012)
# Passer et fingerprint ikke, afvises filen. Sammenlign da med kilden.
# ---------------------------------------------------------------------------
FPR_DEBIAN=("DF9B9C49EAA9298432589D76DA87E80D6294BE9B"
            "10460DAD76165AD81FBC0CE9988021A964E6EA7D")
declare -A FPR_FEDORA=(
  [44]="36F612DCF27F7D1A48A835E4DBFCF71C6D9F90A6"
  [45]="4F50A6114CD5C6976A7F1179655A4B02F577861E"
)
FPR_MANJARO="3B794DE6D4320FCE594F4171279E7CF5D8D56EC8"
FPR_MINT="27DEB15644C6B3CF3BD7D291300F846BA25BAE09"
FPR_MX_XFCE="F62EDEAA3AE70A9C99DAC4189B68A1E8B9B6375C"
FPR_OPENSUSE="AD485664E901B867051AB15F35A2F86E29B700A4"
FPR_PARROT="B711822346552E4D92DA02DF7A8286AF0E81EE4A"
FPR_QUBES_MASTER="427F11FD0FAA4B080123F01CDDFA1A3E36879494"
FPR_SOLUS="F5F6685CAF5559771D9CCB92618EB3600BD32D59"
FPR_TAILS="A490D0F4D311A4153E2BB7CADBB802B258ACD84F"
FPR_UBUNTU="843938DF228D22F7B3742BC0D94AA3F0EFE21092"

SIGNED_ITEMS=(debian-dvd debian-live-cinnamon
              fedora-workstation fedora-kde fedora-server
              manjaro-kde mint-cinnamon mx-xfce opensuse-tw-kde
              parrot-home parrot-security qubes solus-budgie tails
              ubuntu-desktop ubuntu-server)
UNSIGNED_ITEMS=(deepin elementary pop zorin)
ALL_ITEMS=("${SIGNED_ITEMS[@]}" "${UNSIGNED_ITEMS[@]}")

# ---------------------------------------------------------------------------
# Standardindstillinger
# ---------------------------------------------------------------------------
RUN=0
NO_COPY=0
DELETE_OLD=0
CLEAN_STAGING=0
ALLOW_UNSIGNED=0
DEST="/media/${USER:-$(id -un)}/Ventoy/ISOs"
STAGING="${HOME}/Downloads/iso-staging"
SELECTED=()
RUN_TMP=""
LOG=""
ITEM_UNSIGNED=0
QUBES_RSK=""

# Returkoder fra elementerne (ud over 0 = OK og 1 = fejl)
RC_PLANNED=10
RC_SKIPPED=20

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
info() { printf '[INFO]      %s\n' "$*"; }
ok()   { printf '[OK]        %s\n' "$*"; }
warn() { printf '[ADVARSEL]  %s\n' "$*"; }
err()  { printf '[FEJL]      %s\n' "$*"; }
die()  { err "$*"; exit 1; }

usage() { sed -n '2,/^set -Eeuo/{/^set -Eeuo/d;s/^# \{0,1\}//;p}' "$0"; }

# ---------------------------------------------------------------------------
# Hentning
# ---------------------------------------------------------------------------
CURL_COMMON=(curl --fail --location --show-error --retry 3 --retry-delay 5
             --connect-timeout 20 --proto '=https')

# fetch_small URL OUT [any]
#   Små filer (nøgler, signaturer, checksums), maks. 10 MiB. Kun https,
#   medmindre "any" er givet: så må et spejl omdirigere til http. "any" bruges
#   kun til filer, hvis ægthed bagefter kontrolleres med en signatur.
#   "quiet" undertrykker fejlbeskeden (bruges ved forsøg med reservekilder).
fetch_small() {
  local redir='=https' mode=${3:-}
  [[ $mode == *any* ]] && redir='=http,https'
  if [[ $mode == *quiet* ]]; then
    "${CURL_COMMON[@]}" --silent --proto-redir "$redir" --max-filesize 10485760 \
        -o "$2" "$1" 2>/dev/null
    return
  fi
  "${CURL_COMMON[@]}" --silent --proto-redir "$redir" --max-filesize 10485760 \
      -o "$2" "$1" || { err "Kunne ikke hente $1"; return 1; }
}

# Store filer må omdirigeres til http-spejle: indholdet verificeres bagefter.
fetch_big() { # URL OUT  (henter til OUT.part og omdøber ved succes)
  local url=$1 out=$2
  info "Henter $(basename -- "$out")"
  if ! "${CURL_COMMON[@]}" --proto-redir '=http,https' --continue-at - \
        --progress-bar -o "$out.part" "$url" 2>&4; then
    err "Download fejlede: $url (delvis fil bevaret til genoptagelse)"
    return 1
  fi
  mv -f -- "$out.part" "$out"
}

fetch_page() { # URL -> stdout, kun https
  "${CURL_COMMON[@]}" --silent --proto-redir '=https' --max-filesize 10485760 "$1"
}

remote_size() { # URL -> menneskelæsbar størrelse; fejler hvis filen ikke findes
  local h s
  if ! h=$(curl --fail --location --silent --show-error --head --connect-timeout 20 \
             --proto '=https' --proto-redir '=http,https' "$1" 2>/dev/null); then
    # Nogle spejle afviser HEAD – prøv at hente den første byte i stedet.
    curl --fail --location --silent --connect-timeout 20 --proto '=https' \
         --proto-redir '=http,https' --range 0-0 -o /dev/null "$1" 2>/dev/null || return 1
    echo "ukendt størrelse"
    return 0
  fi
  s=$(awk 'tolower($1)=="content-length:" {s=$2} END {gsub(/\r/,"",s); print s}' <<<"$h")
  if [[ $s =~ ^[0-9]+$ ]]; then numfmt --to=iec --suffix=B "$s"; else echo "ukendt størrelse"; fi
}

# ---------------------------------------------------------------------------
# OpenPGP
# ---------------------------------------------------------------------------
new_gnupghome() {
  local d
  d=$(mktemp -d -p "$RUN_TMP" gnupg.XXXXXX) || return 1
  chmod 700 "$d"
  printf '%s\n' "$d"
}

# gpg --import giver fejlkode, så snart ét element i filen afvises (fx en
# ødelagt tredjepartssignatur fra en keyserver), selv om nøglen kom ind.
# Exit-koden ignoreres derfor – det er assert_pinned_key, der afgør sagen.
import_keys() { # HOMEDIR KEYFILE
  gpg --batch --no-tty --homedir "$1" --import "$2" >/dev/null 2>&1 || true
}

# Kontrollerer, at præcis én nøgle i keyringen har PIN's nøgle-ID, og at det er PIN.
assert_pinned_key() { # HOMEDIR PIN
  local home=$1 pin=$2 kid=${2: -16} f n=0 found=0
  while read -r f; do
    [[ ${f: -16} == "$kid" ]] && n=$((n + 1))
    [[ $f == "$pin" ]] && found=1
  done < <(gpg --batch --homedir "$home" --with-colons --list-keys 2>/dev/null \
            | awk -F: '$1=="pub"{p=1; next} $1=="fpr" && p {print $10; p=0}')
  (( found == 1 && n == 1 ))
}

# key_from_sources HOMEDIR WORKDIR PIN [URL...]
#   Henter nøglen med det fastlåste fingerprint. Prøver først de angivne URL'er
#   og derefter tre keyservere. Ægtheden afgøres alene af fingerprintet, så
#   kilden og transporten er underordnet.
key_from_sources() {
  local h=$1 w=$2 pin=$3 url f i=0
  shift 3
  for url in "$@" \
      "https://keyserver.ubuntu.com/pks/lookup?op=get&options=mr&search=0x${pin}" \
      "https://keys.openpgp.org/vks/v1/by-fingerprint/${pin}" \
      "https://pgpkeys.eu/pks/lookup?op=get&options=mr&search=0x${pin}"; do
    i=$((i + 1))
    f="$w/key-${pin: -16}-$i.asc"
    if ! fetch_small "$url" "$f" any,quiet; then
      info "Nøglekilde svarede ikke: $url"
      continue
    fi
    import_keys "$h" "$f"
    if assert_pinned_key "$h" "$pin"; then
      (( i > 1 )) && info "Nøglen ${pin} hentet fra reservekilde: $url"
      return 0
    fi
    info "Svaret fra $url indeholdt ikke nøglen $pin"
  done
  err "Kunne ikke skaffe nøglen med fingerprint $pin fra nogen kilde"
  return 1
}

# gpg_signers HOMEDIR SIG [DATA] [OUT]
#   Udskriver primærnøgle-fingerprint for hver gyldig signatur. Fejler, hvis
#   der ingen gyldig signatur er, eller hvis en signatur er BAD/tilbagekaldt.
#   Med OUT (clearsigned fil) skrives den signerede tekst – og kun den – til OUT.
gpg_signers() {
  local home=$1 sig=$2 data=${3:-} out=${4:-} status
  status=$(mktemp -p "$RUN_TMP" status.XXXXXX)
  if [[ -n $out ]]; then
    rm -f -- "$out"
    gpg --batch --no-tty --homedir "$home" --status-file "$status" \
        --yes --output "$out" --decrypt "$sig" >/dev/null 2>&1 || true
  else
    gpg --batch --no-tty --homedir "$home" --status-file "$status" \
        --verify "$sig" "$data" >/dev/null 2>&1 || true
  fi
  if grep -Eq '^\[GNUPG:\] (BADSIG|REVKEYSIG)' "$status"; then
    return 1
  fi
  awk '$1=="[GNUPG:]" && $2=="VALIDSIG" { print ($12 != "" ? $12 : $3); n++ }
       END { exit (n > 0 ? 0 : 1) }' "$status"
}

# gpg_verify HOMEDIR "PIN [PIN...]" SIG [DATA] [OUT]
#   OK hvis mindst én gyldig signatur stammer fra en af de fastlåste nøgler.
gpg_verify() {
  local home=$1 pins=$2 signers p
  signers=$(gpg_signers "$home" "${@:3}") || return 1
  for p in $pins; do
    grep -qx -- "$p" <<<"$signers" && return 0
  done
  return 1
}

# ---------------------------------------------------------------------------
# Checksums
# ---------------------------------------------------------------------------
hash_of() { # ALGO FILE
  "${1}sum" -- "$2" | awk '{print $1}'
}

check_hash() { # ALGO FILE EXPECTED
  local got
  got=$(hash_of "$1" "$2") || return 1
  [[ ${got,,} == "${3,,}" ]]
}

# Læser filen tilbage (O_DIRECT hvis muligt, så sidecachen ikke snyder).
readback_sha256() { # FILE
  local s
  if s=$(dd if="$1" iflag=direct bs=4M status=none 2>/dev/null | sha256sum); then
    printf '%s\n' "${s%% *}"
  else
    hash_of sha256 "$1"
  fi
}

# GNU-format: "hash  navn" / "hash *navn" / "hash  sti/navn"
sum_names() { # FILE
  awk 'NF>=2 && $1 ~ /^[0-9a-fA-F]+$/ {n=$2; sub(/^\*/,"",n); sub(/.*\//,"",n); print n}' "$1"
}
# Bemærk: ingen {n}-intervaller i awk – ikke alle mawk-udgaver understøtter dem.
sum_from_sha256sums() { # FILE NAME
  awk -v n="$2" 'NF>=2 && length($1)==64 && $1 ~ /^[0-9a-fA-F]+$/ {
                   m=$2; sub(/^\*/,"",m); sub(/.*\//,"",m)
                   if (m==n) {print $1; f=1; exit}
                 }
                 END {exit (f ? 0 : 1)}' "$1"
}
first_sha256() { # FILE -> første SHA-256 i filen
  awk 'length($1)==64 && $1 ~ /^[0-9a-fA-F]+$/ {print $1; exit}' "$1"
}

# Fedora: "SHA256 (navn) = hash"
fedora_names() { # VERIFIED_CHECKSUM
  awk '$1=="SHA256" && $3=="=" {n=$2; sub(/^\(/,"",n); sub(/\)$/,"",n); print n}' "$1"
}
fedora_sum() { # VERIFIED_CHECKSUM NAME
  awk -v n="($2)" '$1=="SHA256" && $2==n && $3=="=" {print $4; f=1; exit}
                   END {exit (f ? 0 : 1)}' "$1"
}

# Parrot: afsnit "md5", "sha256", "sha512" … efterfulgt af "hash  navn"
parrot_sum() { # VERIFIED_FILE ALGO NAME
  awk -v a="$2" -v n="$3" '
    /^(md5|sha1|sha224|sha256|sha384|sha512)[[:space:]]*$/ {sec=$1; next}
    sec==a && $2==n {print $1; f=1; exit}
    END {exit (f ? 0 : 1)}' "$1"
}

# ---------------------------------------------------------------------------
# Fælles flow
# ---------------------------------------------------------------------------
item_dir() { # ITEM
  local d="$STAGING/$1"
  mkdir -p -- "$d" && printf '%s\n' "$d"
}

# Genbrug en tidligere hentet fil, hvis den består; ellers hent (igen).
# get_verified URL OUT VERIFY_CMD...
get_verified() {
  local url=$1 out=$2
  shift 2
  if [[ -f $out ]]; then
    info "Genbruger tidligere hentet $(basename -- "$out") – verificerer"
    if "$@"; then return 0; fi
    warn "Den hentede fil bestod ikke – henter forfra"
    rm -f -- "$out" "$out.part"
  fi
  fetch_big "$url" "$out" || return 1
  info "Verificerer $(basename -- "$out")"
  if "$@"; then return 0; fi
  err "$(basename -- "$out") bestod IKKE verifikationen – filen slettes"
  rm -f -- "$out"
  return 1
}

list_old() { # DIR GLOB KEEP -> én sti pr. linje
  local dir=$1 glob=$2 keep=$3 f
  [[ -d $dir ]] || return 0
  shopt -s nullglob
  # shellcheck disable=SC2206  # globbet skal udfoldes
  local files=( "$dir"/$glob )
  shopt -u nullglob
  for f in "${files[@]}"; do
    [[ $(basename -- "$f") == "$keep" ]] || printf '%s\n' "$f"
  done
}

handle_old() { # DIR GLOB KEEP
  local f
  while IFS= read -r f; do
    if (( DELETE_OLD )); then
      rm -f -- "$f" && info "Slettet ældre version: $(basename -- "$f")"
    else
      info "Ældre version kan slettes: $f"
    fi
  done < <(list_old "$@")
}

plan_or_continue() { # NAME URL SUBDIR GLOB METHOD
  (( RUN )) && return 0
  local name=$1 url=$2 sub=$3 glob=$4 method=$5 size f
  if ! size=$(remote_size "$url"); then
    err "Filen findes ikke på serveren: $url"
    return 1
  fi
  info "Plan: hent $name ($size)"
  info "      fra $url"
  info "      verifikation: $method"
  if (( NO_COPY )); then
    info "      kopieres ikke (--no-copy)"
  else
    info "      kopieres til $DEST/$sub/"
    [[ -f $DEST/$sub/$name ]] && info "      $name ligger allerede på nøglen (kontrolleres ved --run)"
    while IFS= read -r f; do
      if (( DELETE_OLD )); then info "      slettes bagefter: $(basename -- "$f")"
      else info "      ældre version: $(basename -- "$f")"; fi
    done < <(list_old "$DEST/$sub" "$glob" "$name")
  fi
  return "$RC_PLANNED"
}

deliver() { # SRC SHA256 SUBDIR GLOB
  local src=$1 sha=${2,,} sub=$3 glob=$4 name dir size avail tmp got
  name=$(basename -- "$src")
  if (( NO_COPY )); then
    ok "Verificeret i staging: $src (kopieres ikke)"
    return 0
  fi
  dir="$DEST/$sub"
  mkdir -p -- "$dir" || { err "Kan ikke oprette $dir"; return 1; }

  if [[ -f $dir/$name ]]; then
    info "$name ligger allerede på nøglen – læser den tilbage"
    if [[ $(readback_sha256 "$dir/$name") == "$sha" ]]; then
      ok "Allerede opdateret: $dir/$name"
      handle_old "$dir" "$glob" "$name"
      return 0
    fi
    warn "Kopien på nøglen afviger fra den verificerede fil – erstattes"
  fi

  size=$(stat -c %s -- "$src")
  avail=$(df -B1 --output=avail -- "$dir" | tail -n1 | tr -d ' ')
  if (( size + 268435456 > avail )); then
    err "Ikke plads: kræver $(numfmt --to=iec "$size")B, ledigt $(numfmt --to=iec "$avail")B på nøglen"
    return 1
  fi

  tmp="$dir/.${name}.part"
  info "Kopierer $name til nøglen"
  if ! cp -- "$src" "$tmp"; then
    rm -f -- "$tmp"; err "Kopiering fejlede"; return 1
  fi
  sync -- "$tmp" 2>/dev/null || sync
  mv -f -- "$tmp" "$dir/$name" || { err "Kunne ikke omdøbe $tmp"; return 1; }
  sync

  info "Læser kopien tilbage fra nøglen"
  got=$(readback_sha256 "$dir/$name")
  if [[ $got != "$sha" ]]; then
    err "Kopien på nøglen afviger fra den verificerede fil – kopien slettes"
    rm -f -- "$dir/$name"
    return 1
  fi
  ok "Kopieret og kontrolleret: $dir/$name"
  handle_old "$dir" "$glob" "$name"
  if (( CLEAN_STAGING )); then
    rm -f -- "$src" && info "Staging-kopi slettet"
  fi
}

# Fælles afslutning for ISO'er, der verificeres mod en kendt hash.
# finish_by_hash ALGO EXPECTED URL OUT GLOB METHOD
finish_by_hash() {
  local algo=$1 exp=$2 url=$3 out=$4 glob=$5 method=$6 rc sha
  plan_or_continue "$(basename -- "$out")" "$url" Linux "$glob" "$method" || { rc=$?; return "$rc"; }
  get_verified "$url" "$out" check_hash "$algo" "$out" "$exp" || return 1
  ok "${algo^^} OK"
  if [[ $algo == sha256 ]]; then sha=$exp; else sha=$(hash_of sha256 "$out"); fi
  deliver "$out" "$sha" Linux "$glob"
}

# Fælles afslutning for ISO'er med en løsrevet signatur direkte på filen.
# finish_by_sig HOMEDIR PIN URL OUT SIGFILE GLOB METHOD
finish_by_sig() {
  local h=$1 pin=$2 url=$3 out=$4 sig=$5 glob=$6 method=$7 rc sha
  plan_or_continue "$(basename -- "$out")" "$url" Linux "$glob" "$method" || { rc=$?; return "$rc"; }
  get_verified "$url" "$out" gpg_verify "$h" "$pin" "$sig" "$out" || return 1
  ok "Signatur OK ($pin)"
  sha=$(hash_of sha256 "$out")
  deliver "$out" "$sha" Linux "$glob"
}

unsigned_gate() { # NAVN
  ITEM_UNSIGNED=1
  if (( ! ALLOW_UNSIGNED )); then
    warn "$1 udgiver ingen signatur – springes over (brug --allow-unsigned for at tage den med)"
    return "$RC_SKIPPED"
  fi
  warn "$1 udgiver ingen signatur – verificeres kun mod en SHA-256 uden signatur"
}

# ---------------------------------------------------------------------------
# Signerede elementer
# ---------------------------------------------------------------------------
handle_debian() { # dvd | live-cinnamon
  local kind=$1 base re glob w h fpr name exp
  case $kind in
    dvd)           base="https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd"
                   re='^debian-[0-9.]+-amd64-DVD-1\.iso$'; glob='debian-*-amd64-DVD-1.iso' ;;
    live-cinnamon) base="https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid"
                   re='^debian-live-[0-9.]+-amd64-cinnamon\.iso$'; glob='debian-live-*-amd64-cinnamon.iso' ;;
    *) err "Ukendt Debian-variant: $kind"; return 1 ;;
  esac
  w=$(item_dir "debian-$kind") || return 1
  h=$(new_gnupghome) || return 1
  for fpr in "${FPR_DEBIAN[@]}"; do key_from_sources "$h" "$w" "$fpr" || return 1; done
  fetch_small "$base/SHA256SUMS" "$w/SHA256SUMS" || return 1
  fetch_small "$base/SHA256SUMS.sign" "$w/SHA256SUMS.sign" || return 1
  gpg_verify "$h" "${FPR_DEBIAN[*]}" "$w/SHA256SUMS.sign" "$w/SHA256SUMS" \
    || { err "SHA256SUMS er ikke signeret af Debians CD-nøgle"; return 1; }
  ok "SHA256SUMS signeret af Debian"
  name=$(sum_names "$w/SHA256SUMS" | grep -E "$re" | head -n1) || true
  [[ -n $name ]] || { err "Fandt ingen ISO, der passer til $re"; return 1; }
  exp=$(sum_from_sha256sums "$w/SHA256SUMS" "$name") || { err "Mangler hash for $name"; return 1; }
  finish_by_hash sha256 "$exp" "$base/$name" "$w/$name" "$glob" "SHA-256 fra signeret SHA256SUMS"
}

handle_fedora() { # Workstation | KDE | Server
  local variant=$1 v=$FEDORA_VER pin w h re list csum name exp dir dl glob
  pin=${FPR_FEDORA[$v]:-}
  [[ -n $pin ]] || { err "Ingen fastlåst Fedora-nøgle for version $v – tilføj den i FPR_FEDORA"; return 1; }
  case $variant in
    Workstation) re='^Fedora-Workstation-Live-.*\.iso$';  glob='Fedora-Workstation-Live-*.iso' ;;
    KDE)         re='^Fedora-KDE-Desktop-Live-.*\.iso$';  glob='Fedora-KDE-Desktop-Live-*.iso' ;;
    Server)      re='^Fedora-Server-dvd-x86_64-.*\.iso$'; glob='Fedora-Server-dvd-x86_64-*.iso' ;;
    *) err "Ukendt Fedora-variant: $variant"; return 1 ;;
  esac
  dir="https://dl.fedoraproject.org/pub/fedora/linux/releases/${v}/${variant}/x86_64/iso/"
  dl="https://download.fedoraproject.org/pub/fedora/linux/releases/${v}/${variant}/x86_64/iso/"
  w=$(item_dir "fedora-${variant,,}") || return 1
  h=$(new_gnupghome) || return 1

  if ! list=$(fetch_page "$dir" 2>/dev/null); then
    warn "Fedora $v $variant findes ikke på serveren endnu – springes over"
    return "$RC_SKIPPED"
  fi
  csum=$(grep -o 'href="[^"/]*-CHECKSUM"' <<<"$list" | head -n1 | sed 's/^href="//; s/"$//') || true
  [[ -n $csum ]] || { err "Fandt ingen CHECKSUM-fil i $dir"; return 1; }

  key_from_sources "$h" "$w" "$pin" "https://fedoraproject.org/fedora.gpg" || return 1
  fetch_small "${dir}${csum}" "$w/$csum" || return 1
  gpg_verify "$h" "$pin" "$w/$csum" "" "$w/CHECKSUM.verified" \
    || { err "$csum er ikke signeret af Fedora $v-nøglen"; return 1; }
  ok "$csum signeret af Fedora $v"

  name=$(fedora_names "$w/CHECKSUM.verified" | grep -E "$re" | head -n1) || true
  [[ -n $name ]] || { err "Ingen ISO for $variant i den signerede CHECKSUM"; return 1; }
  exp=$(fedora_sum "$w/CHECKSUM.verified" "$name") || { err "Mangler hash for $name"; return 1; }
  finish_by_hash sha256 "$exp" "${dl}${name}" "$w/$name" "$glob" "SHA-256 fra signeret $csum"
}

handle_manjaro_kde() {
  local w h url name page
  w=$(item_dir manjaro-kde) || return 1
  h=$(new_gnupghome) || return 1
  page=$(fetch_page "https://manjaro.org/products/download/x86" 2>/dev/null) || page=""
  url=$(grep -oE 'https://download\.manjaro\.org/kde/[^"'\''<> ]+\.iso' <<<"$page" \
          | grep -v minimal | head -n1) || true
  if [[ -z $url ]]; then
    warn "Kunne ikke finde nyeste Manjaro KDE på manjaro.org – bruger $MANJARO_KDE_FALLBACK"
    url=$MANJARO_KDE_FALLBACK
  fi
  name=$(basename -- "$url")
  key_from_sources "$h" "$w" "$FPR_MANJARO" || return 1
  fetch_small "${url}.sig" "$w/${name}.sig" || return 1
  finish_by_sig "$h" "$FPR_MANJARO" "$url" "$w/$name" "$w/${name}.sig" 'manjaro-kde-*.iso' \
    "OpenPGP-signatur, Manjaro Build Server $FPR_MANJARO"
}

handle_mint() {
  local v=$MINT_VER w h base name exp
  name="linuxmint-${v}-cinnamon-64bit.iso"
  base="https://mirrors.kernel.org/linuxmint/stable/${v}"
  w=$(item_dir mint-cinnamon) || return 1
  h=$(new_gnupghome) || return 1
  key_from_sources "$h" "$w" "$FPR_MINT" || return 1
  fetch_small "$base/sha256sum.txt" "$w/sha256sum.txt" || return 1
  fetch_small "$base/sha256sum.txt.gpg" "$w/sha256sum.txt.gpg" || return 1
  gpg_verify "$h" "$FPR_MINT" "$w/sha256sum.txt.gpg" "$w/sha256sum.txt" \
    || { err "sha256sum.txt er ikke signeret af Linux Mints nøgle"; return 1; }
  ok "sha256sum.txt signeret af Linux Mint"
  exp=$(sum_from_sha256sums "$w/sha256sum.txt" "$name") \
    || { err "$name står ikke i den signerede sha256sum.txt"; return 1; }
  finish_by_hash sha256 "$exp" "$base/$name" "$w/$name" 'linuxmint-*-cinnamon-64bit.iso' \
    "SHA-256 fra signeret sha256sum.txt"
}

handle_mx_xfce() {
  local v=$MX_VER w h name base
  name="MX-${v}_Xfce_x64.iso"
  base="https://sourceforge.net/projects/mx-linux/files/Final/Xfce"
  w=$(item_dir mx-xfce) || return 1
  h=$(new_gnupghome) || return 1
  key_from_sources "$h" "$w" "$FPR_MX_XFCE" || return 1
  fetch_small "$base/${name}.sig/download" "$w/${name}.sig" any || return 1
  finish_by_sig "$h" "$FPR_MX_XFCE" "$base/${name}/download" "$w/$name" "$w/${name}.sig" \
    'MX-*_Xfce_x64.iso' "OpenPGP-signatur, MX Xfce-nøgle $FPR_MX_XFCE"
}

handle_opensuse_tw_kde() {
  local w h base cur name exp
  base="https://download.opensuse.org/tumbleweed/iso"
  cur="openSUSE-Tumbleweed-KDE-Live-x86_64-Current.iso"
  w=$(item_dir opensuse-tw-kde) || return 1
  h=$(new_gnupghome) || return 1
  key_from_sources "$h" "$w" "$FPR_OPENSUSE" \
    "https://download.opensuse.org/tumbleweed/repo/oss/repodata/repomd.xml.key" || return 1
  fetch_small "$base/${cur}.sha256" "$w/${cur}.sha256" any || return 1
  if grep -q '^-----BEGIN PGP SIGNED MESSAGE-----' "$w/${cur}.sha256"; then
    gpg_verify "$h" "$FPR_OPENSUSE" "$w/${cur}.sha256" "" "$w/sha256.verified" \
      || { err "Checksumfilen er ikke signeret af openSUSE"; return 1; }
  else
    fetch_small "$base/${cur}.sha256.asc" "$w/${cur}.sha256.asc" any || return 1
    gpg_verify "$h" "$FPR_OPENSUSE" "$w/${cur}.sha256.asc" "$w/${cur}.sha256" \
      || { err "Checksumfilen er ikke signeret af openSUSE"; return 1; }
    cp -- "$w/${cur}.sha256" "$w/sha256.verified"
  fi
  ok "Checksumfil signeret af openSUSE"
  # Checksumfilen navngiver det konkrete snapshot – det er den fil, vi henter.
  name=$(sum_names "$w/sha256.verified" | grep -E '^openSUSE-Tumbleweed-KDE-Live-x86_64-.*\.iso$' | head -n1) || true
  [[ -n $name ]] || name=$cur
  exp=$(sum_from_sha256sums "$w/sha256.verified" "$name") \
    || exp=$(first_sha256 "$w/sha256.verified")
  [[ $exp =~ ^[0-9a-fA-F]{64}$ ]] || { err "Fandt ingen SHA-256 i checksumfilen"; return 1; }
  finish_by_hash sha256 "$exp" "$base/$name" "$w/$name" \
    'openSUSE-Tumbleweed-KDE-Live-x86_64-*.iso' "SHA-256 fra signeret checksumfil"
}

handle_parrot() { # home | security
  local ed=$1 v=$PARROT_VER w h name base algo exp
  name="Parrot-${ed}-${v}_amd64.iso"
  base="https://deb.parrot.sh/parrot/iso/${v}"
  w=$(item_dir "parrot-${ed}") || return 1
  h=$(new_gnupghome) || return 1
  key_from_sources "$h" "$w" "$FPR_PARROT" "https://deb.parrot.sh/parrot/misc/archive.gpg" || return 1
  fetch_small "$base/signed-hashes.txt" "$w/signed-hashes.txt" any || return 1
  if ! grep -q '^-----BEGIN PGP SIGNED MESSAGE-----' "$w/signed-hashes.txt"; then
    err "signed-hashes.txt for Parrot $v er IKKE signeret – afviser (kan ikke verificeres)"
    return 1
  fi
  gpg_verify "$h" "$FPR_PARROT" "$w/signed-hashes.txt" "" "$w/hashes.verified" \
    || { err "signed-hashes.txt er ikke signeret af Parrots nøgle"; return 1; }
  ok "signed-hashes.txt signeret af Parrot"
  exp=""
  for algo in sha512 sha256; do
    exp=$(parrot_sum "$w/hashes.verified" "$algo" "$name") && break
    exp=""
  done
  [[ -n $exp ]] || { err "Ingen SHA-256/512 for $name i den signerede fil (md5 accepteres ikke)"; return 1; }
  finish_by_hash "$algo" "$exp" "$base/$name" "$w/$name" "Parrot-${ed}-*_amd64.iso" \
    "${algo^^} fra signeret signed-hashes.txt"
}

qubes_iso_ok() { # HOMEDIR SIG DATA – signeret af en udgivelsesnøgle certificeret af QMSK
  local h=$1 signers s kid=${FPR_QUBES_MASTER: -16}
  signers=$(gpg_signers "$h" "$2" "$3") || return 1
  for s in $signers; do
    [[ $s == "$FPR_QUBES_MASTER" ]] && continue
    if gpg --batch --homedir "$h" --with-colons --check-signatures "$s" 2>/dev/null \
         | awk -F: -v k="$kid" '$1=="sig" && $2=="!" && $5==k {f=1} END {exit (f ? 0 : 1)}'; then
      QUBES_RSK=$s
      return 0
    fi
  done
  return 1
}

handle_qubes() {
  local v=$QUBES_VER mm=${QUBES_VER%.*} w h name url sha rc
  name="Qubes-R${v}-x86_64.iso"
  url="https://mirrors.edge.kernel.org/qubes/iso/${name}"
  w=$(item_dir qubes) || return 1
  h=$(new_gnupghome) || return 1
  key_from_sources "$h" "$w" "$FPR_QUBES_MASTER" "https://keys.qubes-os.org/keys/qubes-master-signing-key.asc" || return 1
  fetch_small "https://keys.qubes-os.org/keys/qubes-release-${mm}-signing-key.asc" "$w/rsk.asc" || return 1
  import_keys "$h" "$w/rsk.asc"
  assert_pinned_key "$h" "$FPR_QUBES_MASTER" \
    || { err "Udgivelsesnøglen indeholder en nøgle med samme ID som QMSK – afviser"; return 1; }
  fetch_small "${url}.asc" "$w/${name}.asc" || return 1

  plan_or_continue "$name" "$url" Linux 'Qubes-R*-x86_64.iso' \
    "OpenPGP-signatur, udgivelsesnøgle $mm certificeret af QMSK $FPR_QUBES_MASTER" || { rc=$?; return "$rc"; }

  QUBES_RSK=""
  get_verified "$url" "$w/$name" qubes_iso_ok "$h" "$w/${name}.asc" "$w/$name" || return 1
  ok "Signatur OK (Qubes-udgivelsesnøgle $QUBES_RSK, certificeret af QMSK)"
  sha=$(hash_of sha256 "$w/$name")
  deliver "$w/$name" "$sha" Linux 'Qubes-R*-x86_64.iso'
}

handle_solus_budgie() {
  local d=$SOLUS_DATE w h name base exp
  name="Solus-Budgie-Release-${d}.iso"
  base="https://downloads.getsol.us/isos/${d}"
  w=$(item_dir solus-budgie) || return 1
  h=$(new_gnupghome) || return 1
  key_from_sources "$h" "$w" "$FPR_SOLUS" "https://downloads.getsol.us/gpg/solus-releng-pub.gpg" || return 1
  fetch_small "$base/${name}.sha256sum" "$w/${name}.sha256sum" || return 1
  fetch_small "$base/${name}.sha256sum.sign" "$w/${name}.sha256sum.sign" || return 1
  gpg_verify "$h" "$FPR_SOLUS" "$w/${name}.sha256sum.sign" "$w/${name}.sha256sum" \
    || { err "Checksumfilen er ikke signeret af Solus"; return 1; }
  ok "Checksumfil signeret af Solus"
  exp=$(sum_from_sha256sums "$w/${name}.sha256sum" "$name") \
    || exp=$(first_sha256 "$w/${name}.sha256sum")
  [[ $exp =~ ^[0-9a-fA-F]{64}$ ]] || { err "Fandt ingen SHA-256 i checksumfilen"; return 1; }
  finish_by_hash sha256 "$exp" "$base/$name" "$w/$name" 'Solus-Budgie-Release-*.iso' \
    "SHA-256 fra signeret checksumfil"
}

handle_tails() {
  local v=$TAILS_VER w h name url
  name="tails-amd64-${v}.img"
  url="https://download.tails.net/tails/stable/tails-amd64-${v}/${name}"
  w=$(item_dir tails) || return 1
  h=$(new_gnupghome) || return 1
  key_from_sources "$h" "$w" "$FPR_TAILS" "https://tails.net/tails-signing.key" || return 1
  fetch_small "https://tails.net/torrents/files/${name}.sig" "$w/${name}.sig" || return 1
  finish_by_sig "$h" "$FPR_TAILS" "$url" "$w/$name" "$w/${name}.sig" 'tails-amd64-*.img' \
    "OpenPGP-signatur, Tails-nøgle $FPR_TAILS"
}

handle_ubuntu() { # desktop | live-server
  local kind=$1 w h name base exp
  name="ubuntu-${UBUNTU_VER}-${kind}-amd64.iso"
  base="https://releases.ubuntu.com/${UBUNTU_SERIES}"
  w=$(item_dir "ubuntu-${kind}") || return 1
  h=$(new_gnupghome) || return 1
  key_from_sources "$h" "$w" "$FPR_UBUNTU" || return 1
  fetch_small "$base/SHA256SUMS" "$w/SHA256SUMS" || return 1
  fetch_small "$base/SHA256SUMS.gpg" "$w/SHA256SUMS.gpg" || return 1
  gpg_verify "$h" "$FPR_UBUNTU" "$w/SHA256SUMS.gpg" "$w/SHA256SUMS" \
    || { err "SHA256SUMS er ikke signeret af Ubuntus nøgle"; return 1; }
  ok "SHA256SUMS signeret af Ubuntu"
  exp=$(sum_from_sha256sums "$w/SHA256SUMS" "$name") \
    || { err "$name står ikke i den signerede SHA256SUMS"; return 1; }
  finish_by_hash sha256 "$exp" "$base/$name" "$w/$name" "ubuntu-*-${kind}-amd64.iso" \
    "SHA-256 fra signeret SHA256SUMS"
}

# ---------------------------------------------------------------------------
# Usignerede elementer (kun med --allow-unsigned)
# ---------------------------------------------------------------------------
handle_deepin() {
  local rc v=$DEEPIN_VER w name base exp
  unsigned_gate "deepin" || { rc=$?; return "$rc"; }
  name="deepin-desktop-community-${v}-amd64.iso"
  base="https://cdimage.deepin.com/releases/${v}/amd64"
  w=$(item_dir deepin) || return 1
  fetch_small "$base/SHA256SUMS" "$w/SHA256SUMS" || return 1
  exp=$(sum_from_sha256sums "$w/SHA256SUMS" "$name") || { err "$name står ikke i SHA256SUMS"; return 1; }
  finish_by_hash sha256 "$exp" "$base/$name" "$w/$name" 'deepin-desktop-community-*-amd64.iso' \
    "SHA-256 fra SHA256SUMS hentet over HTTPS (ingen signatur)"
}

handle_elementary() {
  local rc w page url name=$ELEMENTARY_ISO
  unsigned_gate "elementary OS" || { rc=$?; return "$rc"; }
  w=$(item_dir elementary) || return 1
  page=$(fetch_page "https://elementary.io/" 2>/dev/null) || { err "Kunne ikke hente elementary.io"; return 1; }
  url=$(grep -oE "https://dl\.elementaryos\.org/[A-Za-z0-9=_-]+/${name//./\\.}" <<<"$page" | head -n1) || true
  [[ -n $url ]] || { err "Fandt ikke et downloadlink til $name på elementary.io (ny version? opdatér ELEMENTARY_ISO/SHA256)"; return 1; }
  finish_by_hash sha256 "$ELEMENTARY_SHA256" "$url" "$w/$name" 'elementaryos-*-stable-amd64.*.iso' \
    "fastlåst SHA-256 fra elementary.io/docs/installation (ingen signatur)"
}

handle_pop() {
  local rc w json url name exp
  unsigned_gate "Pop!_OS" || { rc=$?; return "$rc"; }
  w=$(item_dir pop) || return 1
  json=$(fetch_page "https://api.pop-os.org/builds/${POP_SERIES}/generic?arch=amd64" 2>/dev/null) \
    || { err "Kunne ikke hente build-info fra api.pop-os.org"; return 1; }
  url=$(sed -n 's/.*"url":"\([^"]*\)".*/\1/p' <<<"$json")
  exp=$(sed -n 's/.*"sha_sum":"\([0-9a-fA-F]\{64\}\)".*/\1/p' <<<"$json")
  [[ $url == https://iso.pop-os.org/*.iso && -n $exp ]] || { err "Uventet svar fra api.pop-os.org"; return 1; }
  name=$(basename -- "$url")
  finish_by_hash sha256 "$exp" "$url" "$w/$name" 'pop-os_*_amd64_*.iso' \
    "SHA-256 fra api.pop-os.org over HTTPS (ingen signatur)"
}

handle_zorin() {
  local rc w name url
  unsigned_gate "Zorin OS" || { rc=$?; return "$rc"; }
  name="Zorin-OS-${ZORIN_VER}-Core-64-bit.iso"
  url="https://mirrors.edge.kernel.org/zorinos-isos/${ZORIN_VER%%.*}/${name}"
  w=$(item_dir zorin) || return 1
  finish_by_hash sha256 "$ZORIN_SHA256" "$url" "$w/$name" 'Zorin-OS-*-Core-64-bit.iso' \
    "fastlåst SHA-256 fra help.zorin.com (ingen signatur)"
}

# ---------------------------------------------------------------------------
# Styring
# ---------------------------------------------------------------------------
run_item() {
  case $1 in
    debian-dvd)           handle_debian dvd ;;
    debian-live-cinnamon) handle_debian live-cinnamon ;;
    fedora-workstation)   handle_fedora Workstation ;;
    fedora-kde)           handle_fedora KDE ;;
    fedora-server)        handle_fedora Server ;;
    manjaro-kde)          handle_manjaro_kde ;;
    mint-cinnamon)        handle_mint ;;
    mx-xfce)              handle_mx_xfce ;;
    opensuse-tw-kde)      handle_opensuse_tw_kde ;;
    parrot-home)          handle_parrot home ;;
    parrot-security)      handle_parrot security ;;
    qubes)                handle_qubes ;;
    solus-budgie)         handle_solus_budgie ;;
    tails)                handle_tails ;;
    ubuntu-desktop)       handle_ubuntu desktop ;;
    ubuntu-server)        handle_ubuntu live-server ;;
    deepin)               handle_deepin ;;
    elementary)           handle_elementary ;;
    pop)                  handle_pop ;;
    zorin)                handle_zorin ;;
    *) err "Ukendt element: $1"; return 1 ;;
  esac
}

expand_selection() { # "a,b,gruppe" -> elementer, én pr. linje
  local tok it known
  local -a toks out=()
  IFS=',' read -r -a toks <<<"$1"
  for tok in "${toks[@]}"; do
    case $tok in
      '')       ;;
      all)      out+=("${ALL_ITEMS[@]}") ;;
      signed)   out+=("${SIGNED_ITEMS[@]}") ;;
      unsigned) out+=("${UNSIGNED_ITEMS[@]}") ;;
      debian)   out+=(debian-dvd debian-live-cinnamon) ;;
      fedora)   out+=(fedora-workstation fedora-kde fedora-server) ;;
      parrot)   out+=(parrot-home parrot-security) ;;
      ubuntu)   out+=(ubuntu-desktop ubuntu-server) ;;
      manjaro)  out+=(manjaro-kde) ;;
      mint)     out+=(mint-cinnamon) ;;
      mx)       out+=(mx-xfce) ;;
      opensuse) out+=(opensuse-tw-kde) ;;
      solus)    out+=(solus-budgie) ;;
      *)
        known=0
        for it in "${ALL_ITEMS[@]}"; do [[ $it == "$tok" ]] && known=1; done
        (( known )) || { printf 'Ukendt element: %s (se --list)\n' "$tok" >&2; return 2; }
        out+=("$tok") ;;
    esac
  done
  printf '%s\n' "${out[@]}" | awk '!seen[$0]++'
}

show_list() {
  cat <<EOF
Signerede (verificeres mod fastlåst nøgle):
  debian-dvd            nyeste i current/        (fra signeret SHA256SUMS)
  debian-live-cinnamon  nyeste i current-live/   (fra signeret SHA256SUMS)
  fedora-workstation    $FEDORA_VER
  fedora-kde            $FEDORA_VER
  fedora-server         $FEDORA_VER
  manjaro-kde           nyeste fra manjaro.org
  mint-cinnamon         $MINT_VER
  mx-xfce               $MX_VER
  opensuse-tw-kde       nyeste snapshot
  parrot-home           $PARROT_VER
  parrot-security       $PARROT_VER
  qubes                 $QUBES_VER
  solus-budgie          $SOLUS_DATE
  tails                 $TAILS_VER
  ubuntu-desktop        $UBUNTU_VER
  ubuntu-server         $UBUNTU_VER

Usignerede (kun med --allow-unsigned):
  deepin                $DEEPIN_VER        (SHA256SUMS over HTTPS)
  elementary            ${ELEMENTARY_ISO}  (fastlåst hash)
  pop                   $POP_SERIES nyeste build (hash fra API over HTTPS)
  zorin                 $ZORIN_VER         (fastlåst hash)

Grupper og korte navne: all, signed, unsigned, debian, fedora, parrot, ubuntu,
                        manjaro, mint, mx, opensuse, solus
EOF
}

cleanup() {
  local d
  if [[ -n $RUN_TMP && -d $RUN_TMP ]]; then
    for d in "$RUN_TMP"/gnupg.*; do
      [[ -d $d ]] && gpgconf --homedir "$d" --kill all >/dev/null 2>&1 || true
    done
    rm -rf -- "$RUN_TMP"
  fi
}

check_dest() {
  local src label
  if [[ ! -d $DEST ]]; then
    (( RUN )) && die "ISO-mappen findes ikke: $DEST (er Ventoy-nøglen monteret?)"
    warn "ISO-mappen findes ikke: $DEST (er Ventoy-nøglen monteret?)"
    return 0
  fi
  src=$(findmnt -n -o SOURCE --target "$DEST" 2>/dev/null || true)
  label=$(lsblk -n -o LABEL -- "$src" 2>/dev/null | head -n1 || true)
  if [[ $label != "Ventoy" ]]; then
    die "$DEST ligger ikke på en partition med label 'Ventoy' (fandt '${label:-?}' på ${src:-?})"
  fi
  [[ -w $DEST ]] || die "Ingen skriveadgang til $DEST"
  info "Ventoy-mappe: $DEST ($src)"
}

main() {
  while (($#)); do
    case $1 in
      --run)            RUN=1 ;;
      --no-copy)        NO_COPY=1 ;;
      --delete-old)     DELETE_OLD=1 ;;
      --clean-staging)  CLEAN_STAGING=1 ;;
      --allow-unsigned) ALLOW_UNSIGNED=1 ;;
      --only)           shift; [[ $# -gt 0 ]] || { echo "--only kræver en liste" >&2; exit 2; }
                        local sel
                        sel=$(expand_selection "$1") || exit 2
                        mapfile -t SELECTED <<<"$sel"
                        [[ -n ${SELECTED[0]:-} ]] || exit 2 ;;
      --dest)           shift; DEST=${1:?--dest kræver en mappe} ;;
      --staging)        shift; STAGING=${1:?--staging kræver en mappe} ;;
      --list)           show_list; exit 0 ;;
      -h|--help)        usage; exit 0 ;;
      *) echo "Ukendt argument: $1 (se --help)" >&2; exit 2 ;;
    esac
    shift
  done
  ((${#SELECTED[@]})) || SELECTED=("${ALL_ITEMS[@]}")

  local dep
  for dep in curl gpg gpgconf sha256sum sha512sum findmnt lsblk df stat dd numfmt flock awk sed grep; do
    command -v "$dep" >/dev/null 2>&1 || { echo "Mangler værktøj: $dep" >&2; exit 1; }
  done

  mkdir -p -- "$STAGING"
  exec 9>"$STAGING/.ventoy-iso-update.lock"
  flock -n 9 || { echo "Scriptet kører allerede (lås: $STAGING/.ventoy-iso-update.lock)" >&2; exit 1; }

  LOG="$STAGING/ventoy-iso-update-$(date +%Y%m%d-%H%M%S).log"
  exec 4>&2                              # fremdriftsbjælke direkte til terminalen
  exec > >(tee -a "$LOG") 2>&1

  RUN_TMP=$(mktemp -d)
  trap cleanup EXIT

  if (( RUN )); then info "Tilstand: KØRSEL"; else info "Tilstand: DRY-RUN (brug --run for at udføre)"; fi
  (( ALLOW_UNSIGNED )) && warn "Usignerede distroer er slået til (--allow-unsigned)"
  info "Staging: $STAGING"
  info "Log:     $LOG"
  (( NO_COPY )) || check_dest

  local it rc label
  local -a summary=()
  local failures=0
  for it in "${SELECTED[@]}"; do
    printf '\n=== %s ===\n' "$it"
    ITEM_UNSIGNED=0
    if run_item "$it"; then rc=0; else rc=$?; fi
    case $rc in
      0)             label=OK ;;
      "$RC_PLANNED") label='KLAR (dry-run)' ;;
      "$RC_SKIPPED") label='SPRUNGET OVER' ;;
      *)             label=FEJL; failures=$((failures + 1)) ;;
    esac
    if (( ITEM_UNSIGNED )) && [[ $rc != "$RC_SKIPPED" ]]; then
      label+=" – usigneret"
    fi
    summary+=("$(printf '%-22s %s' "$it" "$label")")
  done

  printf '\n=== Opsummering ===\n'
  printf '%s\n' "${summary[@]}"
  if (( RUN )) && (( ! NO_COPY )); then
    sync
    info "Husk at afmontere nøglen, før du trækker den ud: udisksctl unmount -b <enhed>"
  fi
  (( failures == 0 )) || exit 1
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
