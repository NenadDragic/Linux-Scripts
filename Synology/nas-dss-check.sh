#!/bin/bash
# Version:      1.1
# Date:         2026-10-09
# Test Run:
# Developper:   Nenad(a)dragic(.)com
#
# Kontrollerer det nyeste DSM-udtræk (.dss) i ~/Downloads mod git med nas-dss-check.py.
# Kald:  ./nas-dss-check.sh                  (nyeste .dss i ~/Downloads)
#        ./nas-dss-check.sh fil.dss          (en bestemt fil)
#        ./nas-dss-check.sh --export /tmp/x  (ekstra valg sendes videre til nas-dss-check.py)
#        ./nas-dss-check.sh --no-diff        (uden forskellene)
#        ./nas-dss-check.sh --context 3      (3 uændrede linjer omkring hver forskel)
# v1.1 (2026-10-09): Forskellene vises som standard (nas-dss-check.py 1.1).
# Exit 0: alt er i sync og ingen hemmeligheder er fundet. Exit 1: noget skal ses på. Exit 2: fejl i opsætningen.

DOWNLOADS="$HOME/Downloads"
GITDIR="$HOME/git/Devices/NAS/Synology"   # NAS-scriptene i git
SCANDIR="$HOME/git/Devices"               # hele repoet søges igennem for hemmeligheder

HERE="$(dirname "$(readlink -f "$0")")"
CHECK="$HERE/nas-dss-check.py"

fejl() { echo "FEJL: $*" >&2; exit 2; }

command -v python3 >/dev/null || fejl "python3 findes ikke"
[[ -f $CHECK ]]  || fejl "$CHECK findes ikke (skal ligge ved siden af dette script)"
[[ -d $GITDIR ]] || fejl "$GITDIR findes ikke"

# Første argument kan være en .dss-fil. Ellers bruges den nyeste i ~/Downloads.
if [[ ${1:-} == *.dss ]]; then
    DSS=$1; shift
    [[ -f $DSS ]] || fejl "$DSS findes ikke"
else
    shopt -s nullglob
    filer=("$DOWNLOADS"/*.dss)
    (( ${#filer[@]} )) || fejl "ingen .dss-fil i $DOWNLOADS. Hent først et nyt udtræk fra DSM."
    DSS=${filer[0]}
    for f in "${filer[@]}"; do [[ $f -nt $DSS ]] && DSS=$f; done
    (( ${#filer[@]} > 1 )) && echo "Bemærk: ${#filer[@]} .dss-filer i $DOWNLOADS. Bruger den nyeste."
fi

alder=$(( ( $(date +%s) - $(stat -c %Y "$DSS") ) / 86400 ))
echo "Udtræk: $DSS ($(date -r "$DSS" '+%F %H:%M'), $alder dag(e) gammelt)"
(( alder > 7 )) && echo "Bemærk: Udtrækket er over en uge gammelt. Hent et nyt, hvis du har ændret noget i DSM."
command -v shellcheck >/dev/null || echo "Bemærk: shellcheck mangler, så trin 3 springes over (sudo apt install shellcheck)."
echo

python3 "$CHECK" "$DSS" "$GITDIR" --scan "$SCANDIR" "$@"
rc=$?

echo
case $rc in
    0) echo "OK: NAS og git er i sync, og der er ingen hemmeligheder." ;;
    1) echo "Se punkterne ovenfor." ;;
    *) echo "nas-dss-check.py stoppede med fejl ($rc)." ;;
esac
exit $rc
