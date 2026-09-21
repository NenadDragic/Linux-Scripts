#!/usr/bin/env bash
# install-tools.sh – vælg hvilke værktøjer der skal installeres via apt
set -euo pipefail

# Navn|Beskrivelse  (rediger frit her)
TOOLS=(
  "mtr|Kombineret ping/traceroute til netværksfejlfinding"
  "bat|cat med syntax highlighting (binær hedder 'batcat' på Debian/Ubuntu)"
  "glances|Systemovervågning i terminalen (htop på steroider)"
)

# --- Rettigheds-validering -------------------------------------------------
if [[ $EUID -eq 0 ]]; then
  SUDO=""
  if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    # Kørt via 'sudo ./script' – husk den rigtige bruger til symlink m.m.
    REAL_USER="$SUDO_USER"
    REAL_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
    echo "ℹ Kører som root via sudo (rigtig bruger: $REAL_USER)"
  else
    REAL_USER="root"; REAL_HOME="/root"
    echo "ℹ Kører direkte som root"
  fi
else
  REAL_USER="$USER"; REAL_HOME="$HOME"
  if ! command -v sudo &>/dev/null; then
    echo "✘ Du er ikke root, og 'sudo' er ikke installeret. Kør scriptet som root." >&2
    exit 1
  fi
  echo "ℹ Kører som $REAL_USER – beder om sudo-rettigheder..."
  if ! sudo -v; then
    echo "✘ Kunne ikke få sudo-rettigheder (forkert kodeord eller ikke i sudoers)." >&2
    exit 1
  fi
  SUDO="sudo"
fi
# ---------------------------------------------------------------------------

# Filtrer allerede installerede pakker ud
declare -a AVAILABLE=()
for entry in "${TOOLS[@]}"; do
  pkg="${entry%%|*}"
  if dpkg -s "$pkg" &>/dev/null; then
    echo "✔ $pkg er allerede installeret – springes over"
  else
    AVAILABLE+=("$entry")
  fi
done
[[ ${#AVAILABLE[@]} -eq 0 ]] && { echo "Intet at installere."; exit 0; }

declare -a SELECTED=()

if command -v whiptail &>/dev/null; then
  # Grafisk checkliste
  args=()
  for entry in "${AVAILABLE[@]}"; do
    args+=("${entry%%|*}" "${entry#*|}" OFF)
  done
  choices=$(whiptail --title "Installér værktøjer" --checklist \
    "Vælg med [mellemrum], bekræft med [Enter]:" 20 78 ${#AVAILABLE[@]} \
    "${args[@]}" 3>&1 1>&2 2>&3) || { echo "Afbrudt."; exit 0; }
  for c in $choices; do SELECTED+=("${c//\"/}"); done
else
  # Tekstbaseret fallback – spørg pr. pakke
  for entry in "${AVAILABLE[@]}"; do
    pkg="${entry%%|*}"; desc="${entry#*|}"
    read -rp "Installér $pkg ($desc)? [j/N] " ans
    [[ "$ans" =~ ^[jJyY]$ ]] && SELECTED+=("$pkg")
  done
fi

[[ ${#SELECTED[@]} -eq 0 ]] && { echo "Intet valgt."; exit 0; }

echo
echo "Installerer: ${SELECTED[*]}"
$SUDO apt update
$SUDO apt install -y "${SELECTED[@]}"

# bat: tilbyd et 'bat'-alias, da binæren hedder batcat
if [[ " ${SELECTED[*]} " == *" bat "* ]] && command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
  read -rp "Opret symlink så 'bat' virker ($REAL_HOME/.local/bin/bat -> batcat)? [j/N] " ans
  if [[ "$ans" =~ ^[jJyY]$ ]]; then
    mkdir -p "$REAL_HOME/.local/bin"
    ln -sf "$(command -v batcat)" "$REAL_HOME/.local/bin/bat"
    # Hvis vi kører som root via sudo, skal filerne ejes af den rigtige bruger
    [[ $EUID -eq 0 && "$REAL_USER" != "root" ]] && chown -R "$REAL_USER" "$REAL_HOME/.local"
    echo "Symlink oprettet. Sørg for at $REAL_HOME/.local/bin er i din PATH."
  fi
fi

echo "Færdig."
