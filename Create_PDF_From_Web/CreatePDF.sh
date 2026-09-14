#!/bin/bash
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
require_tools wkhtmltopdf

# Få dagens dato i ønsket format
date_today=$(date +%Y-%m-%d)

# Opret PDF-mappen, hvis den ikke eksisterer
mkdir -p  PDF

# Læs fra "names.txt"
while IFS=' ' read -r url filename
do
  # Konstruer output filnavn med dato
  output_file="${filename}_${date_today}.pdf"

  # Kør wkhtmltopdf kommandoen
  wkhtmltopdf "$url" "$output_file"

  # Tjek resultat og flyt fil
  if [ $? -eq 0 ]; then
    mv "$output_file" PDF/
    echo "PDF filen '$output_file' er blevet oprettet og flyttet til PDF-mappen."
  else
    echo "Der opstod en fejl ved oprettelse af '$output_file' fra '$url'."
  fi
done < Lookup.txt
