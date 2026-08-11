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
- The password entered at the prompt must match a hardcoded MD5 hash baked into the script (`EXPECTED_MD5`) — the same hash used in `7ZipAllPack.sh`.
- Write access to the current directory (extraction folders are created here).

### Configuration (top of script)

| Variable | Default | Meaning |
|---|---|---|
| `EXPECTED_MD5` | `e0baa6edf1482789a19a5e1380bb4132` | MD5 hash the entered password must match before the script proceeds |

---

## What the Script Does

### Step 1 – Prompt for and validate the password
Reads a password silently (`read -s`), computes its MD5 with `md5sum`, and compares it to `EXPECTED_MD5`. If it doesn't match, prints "Forkert adgangskode." and exits with status 1.

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
- The accepted password is fixed via an MD5 hash in the script; changing it requires editing `EXPECTED_MD5`.
- Output messages are in Danish.
- Requires the `7zz` binary specifically (not `7z` or `p7zip`).
