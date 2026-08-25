#!/bin/bash

# Funktion til at tjekke og installere wkhtmltopdf
install_wkhtmltopdf() {
  command -v wkhtmltopdf >/dev/null 2>&1 || {
    echo >&2 "wkhtmltopdf er ikke installeret. Forsøger at installere..."
    # Tilpas installationskommandoen til dit system
    # For eksempel:
    #   sudo apt install wkhtmltopdf -y  # For Debian/Ubuntu
    #   sudo yum install wkhtmltopdf -y  # For Fedora/CentOS
    sudo apt install wkhtmltopdf -y
    echo
  }
}

# Kald funktionen for at tjekke og installere
install_wkhtmltopdf

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
