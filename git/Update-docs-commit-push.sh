#!/usr/bin/env bash
# Kalder Claude Code til at dokumentere nye/manglende script-filer (alle sprog, alle mapper),
# opdatere Overview.md/Tools/README.md, og committe + pushe resultatet til GitHub.
#
# Kræver at "claude" (Claude Code CLI) er installeret og logget ind på denne maskine.
# Kører uden at spørge undervejs - den committer og pusher automatisk, hvis der er noget at gøre.

set -uo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$repo_root" ]; then
    echo "Kunne ikke finde et git-repo herfra."
    exit 1
fi
cd "$repo_root" || exit 1

if ! command -v claude >/dev/null 2>&1; then
    echo "Kunne ikke finde 'claude' (Claude Code CLI) i PATH. Er den installeret?"
    exit 1
fi

prompt="$(cat <<'EOF'
Der kan være nye eller ændrede script-filer hvor som helst i dette repo (alle mapper og undermapper) - .ps1, .sh, .py eller andre scriptsprog - som mangler en tilhørende .md-dokumentationsfil (samme filnavn, .md i stedet for den oprindelige extension).

Gør følgende:
1. Find alle script-filer i hele repoet (alle mapper/undermapper, undtagen .git) der mangler en matchende .md-fil.
2. Læs 2-3 eksisterende .md-filer (fx i PowerShell/) for at følge den nøjagtige struktur og stil (titel + kort resumé, "Usage"-sektion med kodeblok og forudsætninger, en "Configuration"-tabel for hardcodede variabler, "What the Script Does" med nummererede trin, og en "Notes"-sektion med gotchas/begrænsninger).
3. Læs hvert manglende script grundigt og skriv en ny .md-fil for det, der beskriver hvad scriptet faktisk gør - gæt ikke på funktionalitet der ikke er i koden.
4. Hvis et script er tomt, hvis indholdet tydeligt ikke stemmer overens med filnavnet (fx en oplagt kopiér-fejl), eller hvis filens extension ikke matcher det sprog koden faktisk er skrevet i (fx en .py-fil med PowerShell-kode), så spring dokumentationen af den fil over, omdøb/flyt IKKE filen selv, og forklar situationen i den afsluttende opsummering i stedet for at gætte eller opdigte funktionalitet.
5. Opdater den relevante oversigtsfil, så hvert nyt/rettet script er listet med korrekt link og en kort engelsk beskrivelse i den mest passende sektion (opret en ny sektion, hvis det ikke passer ind i de eksisterende):
   - Scripts under Tools/ listes i Tools/README.md.
   - Alle andre scripts (uanset mappe/sprog) listes i den samlede Overview.md i repo-roden, under den relevante sprog-overskrift (## PowerShell, ## Python, ## Bash, osv.) og kategori.
6. Stage kun de relevante filer (brug ikke `git add -A`/`git add .`), lav én commit med en kort, beskrivende besked, og push til origin.
7. Afslut med en kort opsummering: hvad blev committet og pushet, og hvilke filer (hvis nogen) blev sprunget over og hvorfor.

Hvis der slet ingen nye/udokumenterede script-filer findes, så sig det bare og lav ingen commit.
EOF
)"

echo "Starter Claude Code for at opdatere dokumentation, committe og pushe..."
echo

claude -p "$prompt" \
    --permission-mode acceptEdits \
    --allowedTools "Read Write Edit Glob Grep Bash(git *)"
