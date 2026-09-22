#!/usr/bin/env bash
# SpaceUsageRealTime.sh — vis alle drev, vælg ét, og log dets forbrug i realtid.
#
# Viser først en nummereret liste over alle monterede drev/shares (df -h,
# uden pseudo-filsystemer som tmpfs). Du vælger ét, og scriptet skriver
# herefter tidsstemplet forbrug/ledigt/procent for det valgte drev hvert
# INTERVAL sekund, til skærmen og til en logfil i din hjemmemappe
# (~/<drevnavn>-usage.log).
#
# Brug:   ./SpaceUsageRealTime.sh [tilvalg]
# Hjælp:  ./SpaceUsageRealTime.sh --hjaelp
#
# Nenad Dragic

set -uo pipefail

INTERVAL=60
EXCLUDE_FS=(tmpfs devtmpfs squashfs overlay efivarfs)

hjaelp() {
  cat <<EOF
SpaceUsageRealTime.sh — vis alle drev, vælg ét, og log dets forbrug i realtid

  ./SpaceUsageRealTime.sh [tilvalg]

Tilvalg:
  --interval N, -i N   Sekunder mellem hver måling (standard: 60).
  --hjaelp, -h          Denne hjælp.

Scriptet spørger interaktivt hvilket drev der skal overvåges. Stop
overvågningen med Ctrl+C — logfilen bevares, og der tilføjes til den
ved næste kørsel.

Log skrives til: ~/<drevnavn>-usage.log
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --interval|-i)
      INTERVAL="${2:-}"
      [[ "$INTERVAL" =~ ^[0-9]+$ && "$INTERVAL" -gt 0 ]] || { echo "Ugyldigt interval: ${2:-}" >&2; exit 2; }
      shift 2 ;;
    --hjaelp|--hjælp|-h) hjaelp; exit 0 ;;
    *) echo "Ukendt tilvalg: $1" >&2; hjaelp; exit 2 ;;
  esac
done

command -v df >/dev/null || { echo "FEJL: 'df' blev ikke fundet." >&2; exit 1; }

# --- Byg df-udelukkelserne ---------------------------------------------
declare -a DF_EXCLUDES=()
for fs in "${EXCLUDE_FS[@]}"; do DF_EXCLUDES+=(-x "$fs"); done

# --- Vis alle drev -------------------------------------------------------
mapfile -t ROWS < <(df -h "${DF_EXCLUDES[@]}" --output=source,fstype,size,used,avail,pcent,target 2>/dev/null | tail -n +2)

[[ ${#ROWS[@]} -gt 0 ]] || { echo "FEJL: Ingen drev fundet med df." >&2; exit 1; }

echo "Tilgængelige drev:"
printf '%3s  %-24s %-8s %6s %6s %6s %5s  %s\n' "#" "KILDE" "TYPE" "STR" "BRUGT" "LEDIGT" "BRUGT%" "MONTERET"
for i in "${!ROWS[@]}"; do
  # shellcheck disable=SC2086 # kolonner adskilt af enkelt mellemrum fra df, ønsket ord-splitting
  read -r src fstype size used avail pcent target <<<"${ROWS[$i]}"
  printf '%3d  %-24s %-8s %6s %6s %6s %6s  %s\n' "$((i + 1))" "$src" "$fstype" "$size" "$used" "$avail" "$pcent" "$target"
done
echo

# --- Vælg drev -------------------------------------------------------------
valg=""
while :; do
  read -rp "Vælg drev at overvåge [1-${#ROWS[@]}]: " valg
  [[ "$valg" =~ ^[0-9]+$ ]] && (( valg >= 1 && valg <= ${#ROWS[@]} )) && break
  echo "Ugyldigt valg. Prøv igen."
done

read -r SRC FSTYPE SIZE USED AVAIL PCENT TARGET <<<"${ROWS[$((valg - 1))]}"

# --- Log-navn: udled et filnavn-sikkert navn fra monteringspunktet ---------
if [[ "$TARGET" == "/" ]]; then
  NAVN="root"
else
  NAVN="$(basename -- "$TARGET")"
fi
NAVN="${NAVN//[^A-Za-z0-9._-]/_}"
[[ -n "$NAVN" ]] && [[ "$NAVN" != "_" ]] || NAVN="$(basename -- "$SRC")"
LOG="$HOME/${NAVN}-usage.log"

echo "Overvåger:  $SRC  ($TARGET)"
echo "Interval:   ${INTERVAL}s"
echo "Log:        $LOG"
echo "Stop med Ctrl+C."
echo

trap 'printf "\n%s  Overvågning stoppet.\n" "$(date "+%F %T")"; exit 0' INT TERM

ROW_FMT='%-19s %6s %6s %6s\n'
{
  # shellcheck disable=SC2059 # ROW_FMT er et fast, internt format uden brugerinput
  printf "$ROW_FMT" "TIDSPUNKT" "BRUGT" "LEDIGT" "BRUGT%"
  while :; do
    # shellcheck disable=SC2086 # kolonner adskilt af enkelt mellemrum fra df, ønsket ord-splitting
    read -r used avail pcent <<<"$(df -h --output=used,avail,pcent "$TARGET" | tail -1)"
    # shellcheck disable=SC2059
    printf "$ROW_FMT" "$(date '+%F %T')" "$used" "$avail" "$pcent"
    sleep "$INTERVAL"
  done
} | tee -a "$LOG"
