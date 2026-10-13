# CreatePDF Script

Converts a list of web pages into PDF files using `wkhtmltopdf`, naming each output file with today's date, and moves every successfully generated PDF into a `PDF/` subfolder.

---

## Usage

```console
chmod +x CreatePDF.sh
bash CreatePDF.sh
```

Run it from the folder that contains a `Lookup.txt` file listing one `<url> <filename>` pair per line (space-separated).

Prerequisites:

- `wkhtmltopdf` — checked at startup (see the dependency check below); the script does not install it
- A `Lookup.txt` file in the working directory with `url filename` pairs, one per line
- Dependency check: the script starts by sourcing the shared `lib/require_tools.sh` (found by walking up from the script's own folder) and stops with an `apt install` hint if any of these are missing: `wkhtmltopdf`

---

## What the Script Does

### Step 1 – Ensure wkhtmltopdf is installed

Sources the shared `lib/require_tools.sh` and runs `require_tools wkhtmltopdf`. If `wkhtmltopdf` is missing, it prints a `sudo apt install wkhtmltopdf` hint and exits; nothing is installed.

### Step 2 – Compute today's date

`date_today=$(date +%Y-%m-%d)` captures the current date in `YYYY-MM-DD` format, used later to build output filenames.

### Step 3 – Create the output folder

`mkdir -p PDF` ensures a `PDF/` subfolder exists in the current directory (no error if it's already there).

### Step 4 – Read URL/filename pairs and convert

The script reads `Lookup.txt` line by line with `while IFS=' ' read -r url filename`. For each line:

- Builds `output_file="${filename}_${date_today}.pdf"`
- Runs `wkhtmltopdf "$url" "$output_file"`
- If the command exits `0`, moves the new PDF into `PDF/` and prints a Danish success message
- If it fails, prints a Danish error message and continues to the next line

---

## Notes

- Script comments and echoed messages are in Danish (e.g. "er blevet oprettet og flyttet til PDF-mappen").
- The in-script comment above the read loop says `Læs fra "names.txt"`, but the loop actually reads `done < Lookup.txt` — the comment is stale; the real required input file is `Lookup.txt`.
- The install hint printed by the dependency check uses `apt`; on non-Debian/Ubuntu systems install `wkhtmltopdf` with the local package manager.
- `read -r url filename` splits on the first space only for `url`; anything after the first space on a line (including further spaces) is captured into `filename`, so filenames with spaces work but URLs with spaces would not.
- Not fully safe to blindly re-run for the same day: `output_file` is deterministic (`filename_date.pdf`), so a same-day re-run will regenerate and silently overwrite an existing file of the same name inside `PDF/` via `mv`.
- No check that `Lookup.txt` exists; if missing, the redirection fails and the loop simply does not execute (no explicit error message from the script itself).
