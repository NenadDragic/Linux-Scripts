#!/usr/bin/env bash
#
# WD-Drive.sh — montér, vis status for og afmontér det krypterede WD Elements-drev.
#
#   sudo ./WD-Drive.sh mount            Lås op og montér på /mnt/backup
#        ./WD-Drive.sh status           Vis tilstand (mere detaljeret med sudo)
#   sudo ./WD-Drive.sh umount [--sluk]  Afmontér og lås — med --sluk også strøm af USB-drevet
#
# Exitkoder for status (brugbare i andre scripts):
#   0 = monteret   1 = tilsluttet, men ikke monteret   3 = ikke tilsluttet
#
# Dækker kun dette ene drev. Drevet findes via LUKS-UUID'et, så det er ligegyldigt
# om det hedder sdb eller sdc, og om skrivebordet eller scriptet har låst det op.
#
# Nenad Dragic — Debian-Laptop

set -uo pipefail

# ─── Drevet ──────────────────────────────────────────────────────────────────
LUKS_UUID="f77e78ad-3189-4e36-b912-82e42359049e"   # LUKS-partitionen
FS_UUID="8154462f-dffc-481a-b95f-37f048a3236a"     # filsystemet indeni
MAPNAME="wd-backup"                  # navn når scriptet selv låser op
KEYFILE="/root/wd-backup.key"        # bruges hvis den findes, ellers spørges om kode
MOUNTPOINT="/mnt/backup"
MOUNT_OPTS="noatime"

LUKS_DEV="/dev/disk/by-uuid/$LUKS_UUID"

RED=$'\033[0;31m'; GRN=$'\033[0;32m'; YEL=$'\033[0;33m'
BLU=$'\033[0;34m'; BLD=$'\033[1m'; NC=$'\033[0m'
[[ -t 1 ]] || { RED=""; GRN=""; YEL=""; BLU=""; BLD=""; NC=""; }

info() { printf '%s\n' "${BLU}==>${NC} $1"; }
ok()   { printf '%s\n' "${GRN}==>${NC} $1"; }
advar(){ printf '%s\n' "${YEL}==> ADVARSEL:${NC} $1"; }
fejl() { printf '%s\n' "${RED}==> FEJL:${NC} $1" >&2; }
doed() { fejl "$1"; exit 1; }
raekke() { printf '  %-14s %s\n' "$1" "$2"; }

hjaelp() {
  cat <<EOF
${BLD}WD-Drive.sh${NC} — det krypterede WD Elements-backupdrev

  sudo $0 mount            Lås op og montér på $MOUNTPOINT
       $0 status           Vis om drevet er tilsluttet, låst op og monteret
  sudo $0 umount [--sluk]  Afmontér og lås. --sluk slukker også USB-drevet,
                           så det kan tages ud med det samme.
EOF
}

kraev_root() { [[ $EUID -eq 0 ]] || doed "Kør med sudo: sudo $0 $KOMMANDO"; }

# ─── Opslag ──────────────────────────────────────────────────────────────────
er_tilsluttet() { [[ -b "$LUKS_DEV" ]]; }
luks_part()     { readlink -f "$LUKS_DEV"; }
disk_af()       { lsblk -no PKNAME "$(luks_part)" 2>/dev/null | head -n1; }

# Den åbne LUKS-mapping, uanset navn (luks-<uuid> fra skrivebordet, wd-backup herfra)
find_mapper() {
  local navn type
  while read -r navn type; do
    [[ $type == crypt ]] && { printf '/dev/mapper/%s\n' "$navn"; return; }
  done < <(lsblk -nr -o NAME,TYPE "$(luks_part)" 2>/dev/null)
}

# Alle steder filsystemet er monteret (også /media/... fra skrivebordet)
find_mounts() { findmnt -n -o TARGET --source "UUID=$FS_UUID" 2>/dev/null; }

vis_brugere() {
  local mnt="$1" pids
  if command -v fuser >/dev/null; then
    pids=$(fuser -m "$mnt" 2>/dev/null | tr -s ' ')
    if [[ -n ${pids// /} ]]; then
      ps -o pid=,user=,comm=,args= -p ${pids// /,} 2>/dev/null | sed 's/^/      /' | cut -c1-110
      return 0
    fi
    return 1
  fi
  return 2
}

# ─── mount ───────────────────────────────────────────────────────────────────
cmd_mount() {
  kraev_root
  er_tilsluttet || doed "WD-drevet er ikke tilsluttet ($LUKS_DEV findes ikke)."

  local mnt
  mnt=$(find_mounts | head -n1)
  if [[ -n $mnt ]]; then
    ok "Drevet er allerede monteret på $mnt"
    return 0
  fi

  local mapper opened=0
  mapper=$(find_mapper)
  if [[ -n $mapper ]]; then
    info "Drevet er allerede låst op som $mapper"
  else
    info "Låser drevet op ..."
    if [[ -r $KEYFILE ]]; then
      cryptsetup open --key-file "$KEYFILE" "$LUKS_DEV" "$MAPNAME" \
        || doed "Kunne ikke låse op med nøglefilen $KEYFILE"
    else
      cryptsetup open "$LUKS_DEV" "$MAPNAME" || doed "Kunne ikke låse drevet op."
    fi
    opened=1
    mapper="/dev/mapper/$MAPNAME"
  fi

  mkdir -p "$MOUNTPOINT"
  if mountpoint -q "$MOUNTPOINT"; then
    [[ $opened -eq 1 ]] && cryptsetup close "$MAPNAME"
    doed "$MOUNTPOINT er allerede optaget af et andet filsystem."
  fi

  if ! mount -o "$MOUNT_OPTS" "$mapper" "$MOUNTPOINT"; then
    # Efterlad ikke drevet halvt åbent
    [[ $opened -eq 1 ]] && cryptsetup close "$MAPNAME"
    doed "Kunne ikke montere $mapper på $MOUNTPOINT"
  fi

  ok "Drevet er monteret på $MOUNTPOINT"
  df -h --output=size,used,avail,pcent "$MOUNTPOINT" | sed 's/^/    /'
}

# ─── status ──────────────────────────────────────────────────────────────────
cmd_status() {
  printf '%s\n' "${BLD}WD Elements-backupdrev${NC}"

  if ! er_tilsluttet; then
    raekke "Tilsluttet" "${YEL}nej${NC}"
    return 3
  fi

  local disk
  disk=$(disk_af)
  raekke "Tilsluttet" "${GRN}ja${NC}  (/dev/$disk, $(lsblk -dno SIZE "/dev/$disk" | tr -d ' '))"

  local mapper
  mapper=$(find_mapper)
  if [[ -z $mapper ]]; then
    raekke "Låst op" "nej — drevet er låst"
    raekke "Monteret" "nej"
    return 1
  fi
  raekke "Låst op" "${GRN}ja${NC}  ($mapper)"

  local mounts
  mapfile -t mounts < <(find_mounts)
  if (( ${#mounts[@]} == 0 )); then
    raekke "Monteret" "${YEL}nej${NC} — låst op, men ikke monteret"
    return 1
  fi

  local m
  for m in "${mounts[@]}"; do
    raekke "Monteret" "${GRN}$m${NC}  ($(findmnt -n -o FSTYPE,OPTIONS --target "$m" | awk '{print $1", "substr($2,1,2)}'))"
  done

  m="${mounts[0]}"
  raekke "Plads" "$(df -h --output=used,size,avail,pcent "$m" | tail -n1 \
    | awk '{printf "%s brugt af %s — %s fri (%s fyldt)", $1, $2, $3, $4}')"

  if [[ $EUID -eq 0 ]]; then
    local brugere
    if brugere=$(vis_brugere "$m"); then
      raekke "I brug af" ""
      printf '%s\n' "$brugere"
    else
      raekke "I brug af" "ingen processer"
    fi

    if command -v smartctl >/dev/null; then
      local sundhed
      sundhed=$(smartctl -H -d sat "/dev/$disk" 2>/dev/null \
        | awk -F: '/overall-health|SMART Health Status/ {gsub(/^ +/,"",$2); print $2}')
      raekke "SMART" "${sundhed:-kunne ikke læses via USB-broen}"
    fi
  else
    raekke "Mere" "kør med sudo for processer og SMART-status"
  fi
  return 0
}

# ─── umount ──────────────────────────────────────────────────────────────────
cmd_umount() {
  kraev_root
  if ! er_tilsluttet; then
    ok "Drevet er ikke tilsluttet — intet at gøre."
    return 0
  fi

  local disk
  disk=$(disk_af)

  local mounts i
  mapfile -t mounts < <(find_mounts)
  if (( ${#mounts[@]} )); then
    info "Skriver buffere til drevet ..."
    sync
    # Baglæns, så evt. indlejrede monteringer tages først
    for (( i=${#mounts[@]}-1; i>=0; i-- )); do
      if ! umount "${mounts[i]}"; then
        fejl "Kunne ikke afmontere ${mounts[i]} — noget bruger drevet:"
        vis_brugere "${mounts[i]}" || printf '      (installér psmisc for at se hvilke processer)\n'
        exit 1
      fi
      ok "Afmonteret ${mounts[i]}"
    done
  else
    info "Drevet var ikke monteret."
  fi

  local mapper
  mapper=$(find_mapper)
  if [[ -n $mapper ]]; then
    cryptsetup close "${mapper##*/}" || doed "Kunne ikke låse $mapper"
    ok "Drevet er låst"
  else
    info "Drevet var allerede låst."
  fi

  if [[ $SLUK -eq 1 ]]; then
    if command -v udisksctl >/dev/null; then
      udisksctl power-off -b "/dev/$disk" >/dev/null \
        && ok "Drevet er slukket — det kan tages ud nu." \
        || advar "Kunne ikke slukke /dev/$disk. Drevet er låst, så det er sikkert at tage ud."
    else
      advar "udisksctl mangler (sudo apt install udisks2). Drevet er låst og sikkert at tage ud."
    fi
  fi
}

# ─── Kommandolinje ───────────────────────────────────────────────────────────
KOMMANDO="${1:-}"; [[ $# -gt 0 ]] && shift
SLUK=0
for a in "$@"; do
  case "$a" in
    --sluk|--power-off) SLUK=1 ;;
    *) fejl "Ukendt tilvalg: $a"; hjaelp; exit 2 ;;
  esac
done

case "${KOMMANDO,,}" in
  mount|monter|montér)            cmd_mount ;;
  status)                         cmd_status; exit $? ;;
  umount|unmount|afmonter|afmontér) cmd_umount ;;
  -h|--hjaelp|--hjælp|help|"")    hjaelp; [[ -n $KOMMANDO ]]; exit $? ;;
  *) fejl "Ukendt kommando: $KOMMANDO"; hjaelp; exit 2 ;;
esac
