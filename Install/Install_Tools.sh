#!/usr/bin/env bash
# Install_Tools.sh – vælg hvilke værktøjer der skal installeres via apt
set -euo pipefail

# Navn|Beskrivelse  (rediger frit her)
TOOLS=(
  "mtr|Kombineret ping/traceroute til netværksfejlfinding"
  "bat|cat med syntax highlighting (binær hedder 'batcat' på Debian/Ubuntu)"
  "glances|Systemovervågning i terminalen (htop på steroider)"
  "tmux|Terminal-multiplexer – flere vinduer/paneler og sessioner der overlever afbrudt SSH"
  "doublecmd-qt|Double Commander – tovindues filhåndtering (Qt-udgave, GUI)"
  "doublecmd-plugins|Plugins til Double Commander (trækkes automatisk med doublecmd-qt)"
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

# Kun "install ok installed" tæller – 'dpkg -s' giver også exit 0 for
# pakker der er fjernet men ikke purged (status "config-files").
is_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

# Findes pakken i de aktiverede repos?
is_available() {
  local cand
  cand=$(apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/ {print $2}')
  [[ -n "$cand" && "$cand" != "(none)" ]]
}

# Opdater pakkelister først, så tilgængeligheds-tjekket er retvisende
echo "ℹ Opdaterer pakkelister..."
$SUDO apt-get update -qq

# Filtrer installerede og utilgængelige pakker ud
declare -a AVAILABLE=()
for entry in "${TOOLS[@]}"; do
  pkg="${entry%%|*}"
  if is_installed "$pkg"; then
    echo "✔ $pkg er allerede installeret – springes over"
  elif ! is_available "$pkg"; then
    echo "⚠ $pkg findes ikke i de aktiverede repos (Ubuntu: kræver evt. 'universe') – springes over"
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

# --- Double Commander-specifikke tjek --------------------------------------
# doublecmd-qt "Depends: doublecmd-common, doublecmd-plugins", så plugins
# kommer automatisk med. Vælges plugins ALENE, får man biblioteksfilerne
# uden nogen GUI at bruge dem i.
if [[ " ${SELECTED[*]} " == *" doublecmd-plugins "* \
      && " ${SELECTED[*]} " != *" doublecmd-qt "* ]] \
   && ! is_installed doublecmd-qt && ! is_installed doublecmd-gtk; then
  echo "⚠ doublecmd-plugins alene installerer ingen GUI (Double Commander mangler)."
  read -rp "Tilføj doublecmd-qt? [J/n] " ans
  [[ "$ans" =~ ^[nN]$ ]] || SELECTED+=("doublecmd-qt")
fi

# doublecmd-qt og doublecmd-gtk Provides/Conflicts/Replaces den virtuelle
# pakke "doublecmd" – de kan ikke være installeret samtidig.
if [[ " ${SELECTED[*]} " == *" doublecmd-qt "* ]] && is_installed doublecmd-gtk; then
  echo "⚠ doublecmd-gtk er installeret. Qt- og GTK-udgaven kan ikke sameksistere,"
  echo "  så apt vil FJERNE doublecmd-gtk. Indstillinger i ~/.config/doublecmd bevares."
  read -rp "Fortsæt? [j/N] " ans
  [[ "$ans" =~ ^[jJyY]$ ]] || { echo "Afbrudt."; exit 0; }
fi
# ---------------------------------------------------------------------------

echo
echo "Installerer: ${SELECTED[*]}"
# apt-get frem for apt i scripts – stabilt CLI og ingen "unstable CLI"-advarsel
$SUDO apt-get install -y "${SELECTED[@]}"

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
