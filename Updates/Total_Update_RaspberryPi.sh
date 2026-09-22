#!/usr/bin/env bash
# =============================================================================
# Total_Update_RaspberryPi.sh
# Total system opdatering af Raspberry Pi (Raspberry Pi OS / Debian-baseret)
# Opdaterer: APT pakker, EEPROM/bootloader-firmware, Snap, Python pip,
#            npm (global), rydder op efter sig selv og genstarter om nødvendigt.
# Kræver: sudo-adgang
# =============================================================================

set -euo pipefail

# ---------- farver & formatering ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ---------- hjælpefunktioner ----------
section() { echo -e "\n${CYAN}${BOLD}══════════════════════════════════════════${RESET}"; \
            echo -e "${CYAN}${BOLD}  $1${RESET}"; \
            echo -e "${CYAN}${BOLD}══════════════════════════════════════════${RESET}"; }
ok()      { echo -e "  ${GREEN}✔${RESET}  $1"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET}  $1"; }
info()    { echo -e "  ${CYAN}→${RESET}  $1"; }
err()     { echo -e "  ${RED}✘${RESET}  $1"; }

# ---------- rod-check ----------
if [[ $EUID -ne 0 ]]; then
  err "Scriptet skal køres med sudo: sudo bash $0"
  exit 1
fi

REBOOT_NEEDED=false
START_TIME=$(date +%s)

# ---------- OS/hardware-detektion ----------
OS_NAME="Linux"
OS_VERSION=""
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  OS_NAME="${NAME:-Linux}"
  OS_VERSION="${VERSION_ID:-}"
fi

PI_MODEL=""
if [[ -f /proc/device-tree/model ]]; then
  PI_MODEL=$(tr -d '\0' < /proc/device-tree/model)
fi

echo -e "\n${BOLD}Total Update Script — Raspberry Pi${RESET}"
echo    "System:  ${OS_NAME} ${OS_VERSION}"
[[ -n "$PI_MODEL" ]] && echo "Model:   ${PI_MODEL}"
echo    "Startet: $(date '+%d-%m-%Y %H:%M:%S')"
echo    "Kørende som: $(logname 2>/dev/null || echo 'root')"

if [[ -z "$PI_MODEL" ]]; then
  warn "Kunne ikke bekræfte at dette er en Raspberry Pi (mangler /proc/device-tree/model). Fortsætter alligevel."
fi

# ─────────────────────────────────────────
#  1. APT – pakker fra repositorier
# ─────────────────────────────────────────
section "1/7 · APT — pakke-opdatering"

info "Opdaterer pakkeliste..."
apt-get update -qq
ok "Pakkeliste opdateret"

info "Opgraderer installerede pakker (full-upgrade)..."
DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold"
ok "APT full-upgrade gennemført"

info "Installerer evt. manglende afhængigheder..."
apt-get install -f -y -qq
ok "Afhængigheder løst"

# ─────────────────────────────────────────
#  2. APT – oprydning
# ─────────────────────────────────────────
section "2/7 · APT — oprydning"

info "Fjerner forældede pakker (autoremove)..."
apt-get autoremove -y -qq
ok "Autoremove færdig"

info "Renser pakke-cache..."
apt-get autoclean -qq
ok "Cache renset"

# ─────────────────────────────────────────
#  3. EEPROM / bootloader-firmware
# ─────────────────────────────────────────
section "3/7 · Firmware — rpi-eeprom-update"

if command -v rpi-eeprom-update &>/dev/null; then
  info "Tjekker for EEPROM/bootloader-opdateringer..."
  if rpi-eeprom-update 2>/dev/null | grep -q "UPDATE AVAILABLE"; then
    info "Installerer EEPROM-opdatering..."
    rpi-eeprom-update -a 2>/dev/null || warn "EEPROM-opdatering kunne ikke installeres"
    ok "EEPROM/bootloader opdateret"
    REBOOT_NEEDED=true
  else
    ok "Ingen EEPROM-opdateringer tilgængelige"
  fi
else
  warn "rpi-eeprom-update ikke installeret – springer over"
fi

# ─────────────────────────────────────────
#  4. Snap
# ─────────────────────────────────────────
section "4/7 · Snap — opdatering"

if command -v snap &>/dev/null; then
  info "Opdaterer alle Snap-pakker..."
  snap refresh
  ok "Snap opdateret"

  # Fjern gamle snap-revisioner (holder kun seneste 2)
  info "Fjerner gamle Snap-revisioner..."
  LANG=C snap list --all | awk '/disabled/{print $1, $3}' | \
    while read -r snapname revision; do
      snap remove "$snapname" --revision="$revision" 2>/dev/null && \
        info "  Fjernet: $snapname rev.$revision" || true
    done
  ok "Gamle revisioner ryddet"
else
  warn "Snap ikke fundet – springer over (ikke standard på Raspberry Pi OS)"
fi

# ─────────────────────────────────────────
#  5. Python pip (bruger-niveau)
# ─────────────────────────────────────────
section "5/7 · Python pip — bruger-pakker"

REAL_USER=$(logname 2>/dev/null || echo "")
if [[ -n "$REAL_USER" ]] && command -v pip3 &>/dev/null; then
  info "Opgraderer pip3 for bruger: $REAL_USER..."
  sudo -u "$REAL_USER" pip3 install --upgrade pip --quiet 2>/dev/null || true

  info "Opgraderer forældede pip3-pakker..."
  OUTDATED=$(sudo -u "$REAL_USER" pip3 list --outdated --format=freeze 2>/dev/null \
             | grep -v '^\-e' | cut -d= -f1 || true)
  if [[ -n "$OUTDATED" ]]; then
    echo "$OUTDATED" | xargs -r sudo -u "$REAL_USER" pip3 install --upgrade --quiet
    ok "pip3-pakker opgraderet"
  else
    ok "Ingen forældede pip3-pakker"
  fi
else
  warn "pip3 ikke fundet eller ingen bruger – springer over"
fi

# ─────────────────────────────────────────
#  6. npm globale pakker
# ─────────────────────────────────────────
section "6/7 · npm — globale pakker"

if command -v npm &>/dev/null; then
  info "Opdaterer npm selv..."
  npm install -g npm --silent 2>/dev/null || true
  info "Opdaterer globale npm-pakker..."
  npm update -g --silent 2>/dev/null || true
  ok "npm globale pakker opdateret"
else
  warn "npm ikke installeret – springer over"
fi

# ─────────────────────────────────────────
#  7. updatedb (locate-database)
# ─────────────────────────────────────────
section "7/7 · updatedb — fil-lokations-database"

if command -v updatedb &>/dev/null; then
  info "Opdaterer locate-database..."
  updatedb
  ok "locate-database opdateret"
else
  warn "updatedb ikke fundet – installer mlocate eller plocate"
fi

# ─────────────────────────────────────────
#  Genstart-check
# ─────────────────────────────────────────
section "Afslutning"

if [[ -f /var/run/reboot-required ]]; then
  REBOOT_NEEDED=true
fi

END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))
MINUTES=$(( ELAPSED / 60 ))
SECONDS=$(( ELAPSED % 60 ))

echo ""
ok "Alle opdateringstrin gennemført"
echo -e "  ${BOLD}Varighed:${RESET} ${MINUTES}m ${SECONDS}s"
echo -e "  ${BOLD}Tidspunkt:${RESET} $(date '+%d-%m-%Y %H:%M:%S')"

if $REBOOT_NEEDED; then
  echo ""
  echo -e "  ${YELLOW}${BOLD}⚠  En genstart er anbefalet.${RESET}"
  echo -e "  ${YELLOW}Kør: sudo reboot${RESET}"
fi

echo ""
