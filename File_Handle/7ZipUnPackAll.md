# 7Zip UnPack All Script

Extracts every password-protected `.7z` archive found in the current directory using the `7zz` CLI, placing each archive's contents into a new folder named after the archive.

---

## Usage

```console
chmod +x 7ZipUnPackAll.sh
bash 7ZipUnPackAll.sh
```

Run it from the directory containing the `.7z` files you want to extract.

Prerequisites:

- `7zz` (the 7-Zip CLI binary) must be installed and on `PATH`.
- The password used when the archives were created (see `7ZipAllPack.sh`).
- Write access to the current directory (extraction folders are created here).
- Dependency check: the script starts by sourcing the shared `lib/require_tools.sh` (found by walking up from the script's own folder) and stops with an `apt install` hint if any of these are missing: `7zz`

### Configuration (top of script)

None — the script has no hardcoded variables. (Up to v1.0 it embedded an MD5 hash of the accepted password; that was removed in v1.1 because an unsalted MD5 in a git repo can be brute-forced offline.)

---

## What the Script Does

### Step 1 – Prompt for the password

Reads the password silently (`read -r -s`) and exits with status 1 if it is empty ("Tom adgangskode."). The password is not validated up front — `7zz` itself rejects a wrong password for each archive (Step 5 then prints "FEJL").

### Step 2 – Loop over every `.7z` file

Iterates `for file in *.7z`. Inside the loop it checks whether the glob actually matched a real file (`[ ! -f "$file" ]`); if no `.7z` files are present, it prints "Ingen .7z-filer fundet..." and exits with status 1 on the first iteration.

### Step 3 – Create a destination folder

For each archive, derives `filename` by stripping the `.7z` suffix (`${file%.7z}`) and runs `mkdir -p "$filename"` to (re)create the destination folder.

### Step 4 – Extract the archive

Runs `7zz x -p"$password" "$file" -o"$filename"` to extract the archive's contents into that folder using the supplied password.

### Step 5 – Report success or failure per file

Checks `$?` after the extraction and prints a per-file success message or a "FEJL" message suggesting the password may be wrong, then continues to the next archive.

---

## Notes

- Destructive/overwrite behavior: no `-y`/`-aoa` overwrite flag is passed to `7zz x`, so if the destination folder already contains files with the same names, `7zz` may prompt interactively for overwrite confirmation — in a non-interactive run this could stall or fail rather than silently overwrite.
- Idempotency: re-running is not fully safe — `mkdir -p` won't fail if the folder exists, but extracting into a folder that already has partial/previous contents can trigger the overwrite prompt described above.
- No source `.7z` files are deleted after extraction.
- A wrong password is only detected per archive by `7zz`; each failed archive leaves an (empty or partial) folder behind.
- The password is passed to `7zz` as `-p<password>` and is therefore visible in the process list (`ps`) while an archive is being extracted.
- The old MD5 hash is still in the git history; treat the password it belonged to as exposed.
- Output messages are in Danish.
- Requires the `7zz` binary specifically (not `7z` or `p7zip`).
