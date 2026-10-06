#!/usr/bin/env bash
# --- Dependency check (auto-inserted) ---
_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
while [ "$_d" != "/" ] && [ ! -f "$_d/lib/require_tools.sh" ]; do _d="$(dirname "$_d")"; done
if [ ! -f "$_d/lib/require_tools.sh" ]; then
    echo "FEJL: Kunne ikke finde lib/require_tools.sh (delt dependency-checker)." >&2
    exit 1
fi
# shellcheck source=/dev/null
source "$_d/lib/require_tools.sh"
unset _d
require_tools tmux
#
# tmux-rotate.sh – roterer en tmux-klient mellem udvalgte sessioner
#
# Interaktiv:     tmux-rotate.sh
# Ikke-interaktiv: tmux-rotate.sh -s prod,logs,monitor -i 15 [-c /dev/pts/3]
#
# Stop med Ctrl-C. Scriptet stopper også selv, hvis klienten detacher,
# eller hvis ingen af de valgte sessioner findes længere.

set -uo pipefail

PROG=$(basename "$0")

usage() {
    cat <<EOF
Brug: $PROG [-s sessioner] [-i sekunder] [-c klient] [-l] [-h]

  -s  Kommasepareret liste af sessionsnavne (springer menuen over)
  -i  Sekunder mellem skift (heltal >= 1)
  -c  tmux-klient der skal rotere (se: tmux list-clients)
  -l  Vis sessioner og klienter og afslut
  -h  Vis denne hjælp

Uden flag spørger scriptet interaktivt.
EOF
}

die() { echo "$PROG: $*" >&2; exit 1; }

# --- Forudsætninger ---------------------------------------------------------
command -v tmux >/dev/null 2>&1 || die "tmux er ikke installeret."
tmux list-sessions >/dev/null 2>&1 || die "Ingen tmux-server kører (ingen sessioner)."

# --- Flag -------------------------------------------------------------------
opt_sessions="" opt_interval="" opt_client="" opt_list=0
while getopts ":s:i:c:lh" opt; do
    case $opt in
        s) opt_sessions=$OPTARG ;;
        i) opt_interval=$OPTARG ;;
        c) opt_client=$OPTARG ;;
        l) opt_list=1 ;;
        h) usage; exit 0 ;;
        :) die "Flaget -$OPTARG kræver en værdi." ;;
        *) usage >&2; exit 1 ;;
    esac
done

mapfile -t all_sessions < <(tmux list-sessions -F '#{session_name}')
mapfile -t session_info < <(tmux list-sessions -F '#{session_windows} vinduer#{?session_attached,#, tilknyttet,}')
mapfile -t all_clients  < <(tmux list-clients  -F '#{client_name}')

if (( opt_list )); then
    echo "Sessioner:"
    tmux list-sessions -F '  #{session_name}  (#{session_windows} vinduer, #{?session_attached,tilknyttet,ikke tilknyttet})'
    echo "Klienter:"
    if (( ${#all_clients[@]} )); then
        tmux list-clients -F '  #{client_name}  -> #{session_name}  (#{client_width}x#{client_height})'
    else
        echo "  (ingen)"
    fi
    exit 0
fi

(( ${#all_clients[@]} )) || die "Ingen klienter er tilknyttet tmux. Start 'tmux attach' på den skærm, der skal rotere."

session_exists() { tmux has-session -t "=$1" 2>/dev/null; }

# --- Vælg sessioner ---------------------------------------------------------
selected=()
if [[ -n $opt_sessions ]]; then
    IFS=',' read -ra wanted <<< "$opt_sessions"
    for s in "${wanted[@]}"; do
        s=${s// /}
        [[ -z $s ]] && continue
        session_exists "$s" || die "Sessionen '$s' findes ikke."
        selected+=("$s")
    done
else
    echo "Aktive tmux-sessioner:"
    for i in "${!all_sessions[@]}"; do
        printf '  %2d) %s  (%s)\n' $((i + 1)) "${all_sessions[$i]}" "${session_info[$i]}"
    done
    echo
    while :; do
        read -rp "Vælg sessioner (fx '1 3 4', '1-3' eller 'a' for alle): " answer
        selected=()
        valid=1
        if [[ $answer =~ ^[aA](lle)?$ ]]; then
            selected=("${all_sessions[@]}")
        else
            for tok in ${answer//,/ }; do
                if [[ $tok =~ ^([0-9]+)-([0-9]+)$ ]]; then
                    from=${BASH_REMATCH[1]} to=${BASH_REMATCH[2]}
                elif [[ $tok =~ ^[0-9]+$ ]]; then
                    from=$tok to=$tok
                else
                    valid=0; break
                fi
                for (( n = from; n <= to; n++ )); do
                    if (( n < 1 || n > ${#all_sessions[@]} )); then valid=0; break 2; fi
                    s=${all_sessions[$((n - 1))]}
                    # undgå dubletter
                    [[ " ${selected[*]} " == *" $s "* ]] || selected+=("$s")
                done
            done
        fi
        if (( valid && ${#selected[@]} >= 1 )); then break; fi
        echo "Ugyldigt valg – prøv igen."
    done
fi

# --- Interval ---------------------------------------------------------------
interval=$opt_interval
until [[ $interval =~ ^[0-9]+$ ]] && (( interval >= 1 )); do
    [[ -n $interval ]] && echo "Intervallet skal være et heltal >= 1."
    read -rp "Sekunder mellem skift [10]: " interval
    interval=${interval:-10}
done

# --- Klient -----------------------------------------------------------------
client=$opt_client
if [[ -n $client ]]; then
    printf '%s\n' "${all_clients[@]}" | grep -qxF "$client" || die "Klienten '$client' findes ikke (se: $PROG -l)."
elif (( ${#all_clients[@]} == 1 )); then
    client=${all_clients[0]}
else
    echo
    echo "Flere klienter er tilknyttet. Hvilken skærm skal rotere?"
    for i in "${!all_clients[@]}"; do
        c=${all_clients[$i]}
        info=$(tmux list-clients -F '#{client_name}|#{session_name}|#{client_width}x#{client_height}' \
               | awk -F'|' -v c="$c" '$1 == c { print "viser " $2 ", " $3 }')
        printf '  %2d) %s  (%s)\n' $((i + 1)) "$c" "$info"
    done
    while :; do
        read -rp "Vælg klient [1]: " n
        n=${n:-1}
        if [[ $n =~ ^[0-9]+$ ]] && (( n >= 1 && n <= ${#all_clients[@]} )); then
            client=${all_clients[$((n - 1))]}
            break
        fi
        echo "Ugyldigt valg."
    done
fi

(( ${#selected[@]} >= 2 )) || echo "Bemærk: kun én session valgt – der er ikke noget at rotere imellem, men scriptet holder klienten på den." >&2

# Lukkes den session, klienten viser, detacher tmux som standard klienten
if [[ $(tmux show-options -gv detach-on-destroy 2>/dev/null) == on ]]; then
    echo "Tip: 'tmux set -g detach-on-destroy off' får klienten til at blive hængende," >&2
    echo "     hvis en valgt session lukkes, mens den vises." >&2
fi

# Advarsel hvis scriptet kører inde i den klient, det selv roterer
if [[ -n ${TMUX:-} ]]; then
    own_client=$(tmux display-message -p '#{client_name}' 2>/dev/null || true)
    if [[ $own_client == "$client" ]]; then
        echo "Advarsel: scriptet kører i den klient, det roterer. Når der skiftes væk," >&2
        echo "kan du ikke trykke Ctrl-C her. Stop det med: pkill -f $PROG" >&2
    fi
fi

# --- Rotation ---------------------------------------------------------------
trap 'echo; echo "Stoppet."; exit 0' INT TERM

echo
echo "Roterer klient $client mellem: ${selected[*]}"
echo "Interval: ${interval}s. Stop med Ctrl-C."

while :; do
    active=0
    for s in "${selected[@]}"; do
        if ! session_exists "$s"; then
            continue        # sessionen er lukket – spring over
        fi
        active=1
        if ! tmux switch-client -c "$client" -t "=$s" 2>/dev/null; then
            echo "Klienten $client er ikke længere tilknyttet (detached, eller den viste session blev lukket). Afslutter."
            exit 0
        fi
        sleep "$interval"
    done
    (( active )) || { echo "Ingen af de valgte sessioner findes længere. Afslutter."; exit 0; }
done
