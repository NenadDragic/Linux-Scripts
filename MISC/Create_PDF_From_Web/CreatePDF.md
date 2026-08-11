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

- `wkhtmltopdf` — the script checks for it with `command -v wkhtmltopdf` and, if missing, attempts to auto-install it via `sudo apt install wkhtmltopdf -y` (Debian/Ubuntu only; the commented-out `yum` line for Fedora/CentOS is not actually executed)
- `sudo` access, since the auto-install step uses `sudo apt`
- A `Lookup.txt` file in the working directory with `url filename` pairs, one per line

---

## What the Script Does

### Step 1 – Ensure wkhtmltopdf is installed
The `install_wkhtmltopdf()` function checks with `command -v wkhtmltopdf`; if it isn't found, it prints a message and runs `sudo apt install wkhtmltopdf -y`. This function is called unconditionally at the top of the script, every run.

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

- Script comments and echoed messages are in Danish (e.g. "er ikke installeret", "er blevet oprettet og flyttet til PDF-mappen").
- The in-script comment above the read loop says `Læs fra "names.txt"`, but the loop actually reads `done < Lookup.txt` — the comment is stale; the real required input file is `Lookup.txt`.
- Auto-install only covers `apt`; on non-Debian/Ubuntu systems without `wkhtmltopdf` already installed, the script will fail when it tries to run `wkhtmltopdf`.
- `read -r url filename` splits on the first space only for `url`; anything after the first space on a line (including further spaces) is captured into `filename`, so filenames with spaces work but URLs with spaces would not.
- Not fully safe to blindly re-run for the same day: `output_file` is deterministic (`filename_date.pdf`), so a same-day re-run will regenerate and silently overwrite an existing file of the same name inside `PDF/` via `mv`.
- No check that `Lookup.txt` exists; if missing, the redirection fails and the loop simply does not execute (no explicit error message from the script itself).
