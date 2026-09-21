#!/usr/bin/env bash
# Henter nye commits ned fra GitHub for hvert git-repo under en base-mappe,
# uden at overskrive lokale ændringer.
#
# Base-mappe (kan overstyres med et argument: ./sync-from-github.sh /anden/sti):
#   Windows (Git Bash): H:\git  (/h/git)
#   Linux:               ~/Git

set -uo pipefail

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
        default_base="/h/git"
        ;;
    *)
        default_base="$HOME/Git"
        ;;
esac

base_dir="${1:-$default_base}"

if [ ! -d "$base_dir" ]; then
    echo "Base-mappen findes ikke: $base_dir"
    exit 1
fi

echo "Leder efter git-repos under: $base_dir"
echo

found_any=0

for dir in "$base_dir"/*/; do
    [ -d "${dir}.git" ] || continue
    found_any=1
    repo_name="$(basename "$dir")"
    echo "== $repo_name =="

    (
        cd "$dir" || exit 1

        git fetch origin --quiet

        local_rev="$(git rev-parse '@' 2>/dev/null)"
        remote_rev="$(git rev-parse '@{u}' 2>/dev/null)"
        if [ -z "$remote_rev" ]; then
            echo "  Ingen remote-tracking branch - springer over."
            exit 0
        fi
        base_rev="$(git merge-base '@' '@{u}')"

        if [ "$local_rev" = "$remote_rev" ]; then
            echo "  Allerede opdateret."
        elif [ "$local_rev" = "$base_rev" ]; then
            if [ -n "$(git status --porcelain)" ]; then
                echo "  Nyt fundet, men der er lokale, ikke-committede ændringer - springer over."
            else
                echo "  Nyt fundet - henter ned (fast-forward)..."
                branch="$(git rev-parse --abbrev-ref HEAD)"
                git pull --ff-only origin "$branch"
                git log --oneline "$local_rev..HEAD"
                echo "  Opdateret."
            fi
        elif [ "$remote_rev" = "$base_rev" ]; then
            echo "  Lokale commits der ikke er pushet endnu - intet at hente."
        else
            echo "  Lokal og remote er divergeret - kræver manuel håndtering."
        fi
    )
    echo
done

if [ "$found_any" -eq 0 ]; then
    echo "Ingen git-repos fundet under $base_dir."
fi
