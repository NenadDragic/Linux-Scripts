# Convert Script

Renames every file (and directory) in the current folder to uppercase, converts any resulting `.HEIC` files to quality-100 JPEGs with `heif-convert`, then runs a second uppercase-rename pass with the `rename` utility. It is a general "normalize this folder and convert HEIC" utility, not restricted to photo files for the rename steps.

---

## Usage

```console
chmod +x Convert.sh
bash Convert.sh
```

Run it from inside the folder you want to convert. The script takes no arguments — it always operates on every entry of the current working directory.

Prerequisites:

- `heif-convert` (from a libheif tools/examples package) must be installed.
- The `rename` utility (Perl-style `rename 'y/a-z/A-Z/' *`) must be installed.
- Standard `tr`/`mv` (present on any Linux system).

---

## What the Script Does

### Step 1 – Uppercase every entry in the folder
`for f in *; do mv "$f" "$(echo "$f" | tr 'a-z' 'A-Z')"; done` renames **every** file and directory in the current working directory to its uppercase form — not limited to images.

### Step 2 – Convert HEIC to JPEG
`for f in *.HEIC` now matches because Step 1 already uppercased extensions. Each matched file is converted with `heif-convert -q 100 "$f" "${f%.HEIC}.JPG"`, producing a quality-100 JPEG with the same base name. The original `.HEIC` file is **not** deleted.

### Step 3 – Uppercase pass again
`rename 'y/a-z/A-Z/' *` re-applies an uppercase transliteration to everything in the folder. Since names are already uppercase after Step 1, this is functionally redundant as written, but it is present in the script.

---

## Notes

- **Destructive and unfiltered:** Steps 1 and 3 rename every file and subdirectory in the working directory to uppercase, unconditionally — there is no filter for image files, no dry run, and no collision handling. If uppercasing two differently-cased names would collide (e.g. `img1.jpg` and `IMG1.jpg`), the second `mv` can silently overwrite the first.
- Running this in a directory that also contains unrelated files or subfolders will rename those too.
- The source `.HEIC` is kept after conversion (unlike `Sort_Total.sh`'s optional DNG deletion), so both the `.HEIC` and the new `.JPG` remain afterward.
- **The script ignores any argument passed to it.** `Update_PVT_Folders.sh` calls it as `"$CONVERT_SCRIPT" "$file"`, but `Convert.sh` never references `$1`/`$@` — it always processes every entry of whatever directory is current when it runs, regardless of what filename was passed in.
- Re-running is mostly idempotent for the uppercase renames (already-uppercase names are unaffected), but the HEIC→JPEG conversion has no existence check, so it will re-convert and overwrite the `.JPG` every time it runs while the `.HEIC` is still present.
- No error handling for missing tools: if `heif-convert` or `rename` are not installed, the script fails with a plain "command not found" partway through.
- Comments are in English.
