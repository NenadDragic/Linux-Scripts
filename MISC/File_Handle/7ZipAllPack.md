# 7Zip All Pack Script

Compresses every subfolder of the current directory into its own password-protected `.7z` archive, using the `7zz` CLI. Each archive is named after the subfolder it was created from and is written one level up (in the directory the script was run from).

---

## Usage

```console
chmod +x 7ZipAllPack.sh
bash 7ZipAllPack.sh
```

Run it from the parent directory that contains the subfolders you want to archive (each subfolder becomes one `.7z` file, placed next to the subfolders).

Prerequisites:

- `7zz` (the 7-Zip CLI binary) must be installed and on `PATH`.
- The password entered at the prompt must match a hardcoded MD5 hash baked into the script (`EXPECTED_MD5`); there is no way to set/change the accepted password without editing the script.
- Write access to the current directory (archives are written to `../$folder_name.7z` relative to each subfolder, i.e. into the current directory).

### Configuration (top of script)

| Variable | Default | Meaning |
|---|---|---|
| `EXPECTED_MD5` | `e0baa6edf1482789a19a5e1380bb4132` | MD5 hash the entered password must match before the script proceeds |

---

## What the Script Does

### Step 1 – Prompt for and validate the password
Reads a password silently (`read -s`), computes its MD5 with `md5sum`, and compares it to the hardcoded `EXPECTED_MD5`. If it doesn't match, prints "Forkert adgangskode." and exits with status 1.

### Step 2 – Loop over every subfolder
Iterates `for dir in */` over all subdirectories of the current directory.

### Step 3 – Compress each subfolder's contents
For each subfolder, strips the trailing slash to get `folder_name`, then runs, in a subshell:

```bash
(cd "$folder_name" && 7zz a -p"$password" -mhe -t7z "../$folder_name.7z" ./*)
```

This creates (or updates, if it already exists) a `.7z` archive named `$folder_name.7z` in the current directory, containing the subfolder's contents. `-mhe` encrypts the archive headers (filenames included) in addition to the file contents, and `-p"$password"` supplies the password non-interactively.

### Step 4 – Report success or failure per folder
Checks `$?` after the 7zz call and prints a per-folder success or "FEJL" (error) message, then continues to the next folder. A failure on one folder does not stop the loop.

---

## Notes

- Destructive/overwrite behavior: no source files are deleted or moved. However, if a `$folder_name.7z` archive already exists, `7zz a` adds/updates entries in it rather than starting fresh — re-running the script does not guarantee a clean rebuild of the archive.
- The accepted password is fixed via an MD5 hash in the script; changing the password requires editing `EXPECTED_MD5`.
- Output messages ("Indtast adgangskode", "Komprimerer...", "FEJL", etc.) are in Danish.
- Requires the `7zz` binary specifically (not `7z` or `p7zip`); if it isn't installed the script will fail on every folder.
- No dry-run/preview mode — running it immediately starts compressing every subfolder found.
