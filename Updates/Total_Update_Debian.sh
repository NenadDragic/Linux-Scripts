#!/usr/bin/env bash
# =============================================================================
# ubuntu-total-update.sh
# Total system opdatering af Ubuntu Desktop
# Opdaterer: APT pakker, Snap, Flatpak, firmware, Python pip, npm (global),
#            rydder op efter sig selv og genstarter om nødvendigt.
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

# ---------- OS-detektion ----------
OS_NAME="Linux"
OS_VERSION=""
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  OS_NAME="${NAME:-Linux}"
  OS_VERSION="${VERSION_ID:-}"
fi

echo -e "\n${BOLD}Total Update Script${RESET}"
echo    "System:  ${OS_NAME} ${OS_VERSION}"
echo    "Startet: $(date '+%d-%m-%Y %H:%M:%S')"
echo    "Kørende som: $(logname 2>/dev/null || echo 'root')"

# Info om hvad der er relevant for det detekterede OS
if echo "$OS_NAME" | grep -qi "ubuntu"; then
  info "Ubuntu detekteret — alle trin aktive inkl. Snap"
elif echo "$OS_NAME" | grep -qi "debian"; then
  warn "Debian detekteret — Snap og fwupd er ikke standard, springer over hvis ikke installeret"
fi

# ─────────────────────────────────────────
#  1. APT – pakker fra repositorier
# ─────────────────────────────────────────
section "1/8 · APT — pakke-opdatering"

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
section "2/8 · APT — oprydning"

info "Fjerner forældede pakker (autoremove)..."
apt-get autoremove -y -qq
ok "Autoremove færdig"

info "Renser pakke-cache..."
apt-get autoclean -qq
ok "Cache renset"

# ─────────────────────────────────────────
#  3. Snap
# ─────────────────────────────────────────
section "3/8 · Snap — opdatering"

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
  warn "Snap ikke fundet – springer over"
fi

# ─────────────────────────────────────────
#  4. Flatpak
# ─────────────────────────────────────────
section "4/8 · Flatpak — opdatering"

if command -v flatpak &>/dev/null; then
  info "Opdaterer alle Flatpak-applikationer..."
  flatpak update -y
  info "Fjerner ubrugte Flatpak-runtime-pakker..."
  flatpak uninstall --unused -y
  ok "Flatpak opdateret og ryddet"
else
  warn "Flatpak ikke installeret – springer over"
fi

# ─────────────────────────────────────────
#  5. Firmware (fwupd)
# ─────────────────────────────────────────
section "5/8 · Firmware — fwupd"

if command -v fwupdmgr &>/dev/null; then
  info "Henter firmware-metadata..."
  fwupdmgr refresh --force 2>/dev/null || warn "Metadata-opdatering fejlede (ikke kritisk)"

  info "Tjekker for firmware-opdateringer..."
  if fwupdmgr get-updates 2>/dev/null | grep -q "Upgrade"; then
    info "Installerer firmware-opdateringer..."
    fwupdmgr update -y 2>/dev/null || warn "Nogle firmware-opdateringer kunne ikke installeres"
    ok "Firmware opdateret"
    REBOOT_NEEDED=true
  else
    ok "Ingen firmware-opdateringer tilgængelige"
  fi
else
  warn "fwupd ikke installeret – springer over"
fi

# ─────────────────────────────────────────
#  6. Python pip (bruger-niveau)
# ─────────────────────────────────────────
section "6/8 · Python pip — bruger-pakker"

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
#  7. npm globale pakker
# ─────────────────────────────────────────
section "7/8 · npm — globale pakker"

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
#  8. updatedb (locate-database)
# ─────────────────────────────────────────
section "8/8 · updatedb — fil-lokations-database"

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

# Tjek om en genstart er nødvendig
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