# Create PDF From Web Scripts Overview

An index of the scripts in this folder and their documentation. Each script has a matching `.md` file (same base name) describing usage, configuration, step-by-step behavior, and notable gotchas.

---

## Web-to-PDF Conversion

| Script | Doc | Summary |
|---|---|---|
| `CreatePDF.sh` | [CreatePDF.md](CreatePDF.md) | Converts a list of web pages into PDF files using `wkhtmltopdf`, naming each output file with today's date, and moves every successfully generated PDF into a `PDF/` subfolder. |

---

## Notes

- Success/error messages printed for each conversion are in Danish, while the surrounding documentation is in English.
- Not safe to blindly re-run on the same day: output filenames are deterministic (`filename_date.pdf`), so a same-day re-run silently overwrites an existing file of the same name in `PDF/`.
- Auto-installs `wkhtmltopdf` via `sudo apt install` if missing, but only supports Debian/Ubuntu (`apt`) — it does nothing on other distros beyond a commented-out, unused `yum` line.
