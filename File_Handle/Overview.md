# File_Handle Scripts Overview

An index of the scripts in this folder and their documentation. Each script has a matching `.md` file (same base name) describing usage, configuration, step-by-step behavior, and notable gotchas.

---

## Archiving

| Script | Doc | Summary |
|---|---|---|
| `7ZipAllPack.sh` | [7ZipAllPack.md](7ZipAllPack.md) | Compresses every subfolder of the current directory into its own password-protected `.7z` archive using the `7zz` CLI, named after the subfolder and written one level up. |
| `7ZipUnPackAll.sh` | [7ZipUnPackAll.md](7ZipUnPackAll.md) | Extracts every password-protected `.7z` archive found in the current directory using the `7zz` CLI, placing each archive's contents into a new folder named after the archive. |
| `MoveDocToArchive.sh` | [MoveDocToArchive.md](MoveDocToArchive.md) | Finds, previews (`find`/`dryrun`), or moves (`run`) files matching a date pattern from a source folder to an archive folder, automatically enabling checksum verification when source and destination are on different filesystems. |

## File Discovery/Search

| Script | Doc | Summary |
|---|---|---|
| `File_Count.sh` | [File_Count.md](File_Count.md) | Counts how many files of each extension exist in the current directory tree and prints a sorted tally, from least to most common. |
| `Find_Empty_Files.sh` | [Find_Empty_Files.md](Find_Empty_Files.md) | Finds and prints the paths of all empty files in the current directory and its subdirectories (`find . -type f -empty`). |
| `Find_Files_With_Big_Letters_In_FileName_Begginig.sh` | [Find_Files_With_Big_Letters_In_FileName_Begginig.md](Find_Files_With_Big_Letters_In_FileName_Begginig.md) | Finds all files whose filenames begin with a capital letter (`find . -type f -regex './[A-Z]*'`). |
| `Find_Files_With_No_Extension.sh` | [Find_Files_With_No_Extension.md](Find_Files_With_No_Extension.md) | Finds all files that do not have a file extension (`find . -type f ! -name '*.*'`). |
| `Find_Unique_File_Extensions.sh` | [Find_Unique_File_Extensions.md](Find_Unique_File_Extensions.md) | Finds all unique file extensions present in the current directory and its subdirectories. |
| `Search_Low_Extension.sh` | [Search_Low_Extension.md](Search_Low_Extension.md) | Searches for files whose extension consists of at least one lowercase letter, printing results between a banner and a completion footer. |

## Renaming

| Script | Doc | Summary |
|---|---|---|
| `Rename_Extensions_To_Big_Letter.sh` | [Rename_Extensions_To_Big_Letter.md](Rename_Extensions_To_Big_Letter.md) | Renames every file in the current directory by transliterating all lowercase letters in the filename to uppercase (whole filename, not just the extension; no recursion despite what the script's intro comment says). |

## Network Shares

| Script | Doc | Summary |
|---|---|---|
| `SMB.sh` | [SMB.md](SMB.md) | Mounts or unmounts one of three predefined CIFS/SMB network shares (`DashCam`, `Dragic`, `NetBackup`) from a fixed remote server to a fixed local mount point under `/mnt`. |

## Test Data

| Script | Doc | Summary |
|---|---|---|
| `CreateTxTFiles.sh` | [CreateTxTFiles.md](CreateTxTFiles.md) | Generates one or more large files filled with random binary data (via `/dev/urandom`) for test/dummy data of a known size — despite its filename, it creates `file_NNNN.bin` files, not `.txt` files. |

---

## Notes

- Danish console output: `7ZipAllPack.sh`, `7ZipUnPackAll.sh`, `CreateTxTFiles.sh`, and `SMB.sh` all print their status/error messages in Danish (e.g. "Forkert adgangskode.", "FEJL", "Opretter...", "Ugyldigt share-navn"); `MoveDocToArchive.sh`'s documented example output is also entirely in Danish. The remaining File Discovery/Search scripts and `Rename_Extensions_To_Big_Letter.sh` produce English (or no) output.
- Filename-vs-behavior mismatches to watch for: `CreateTxTFiles.sh` produces random-binary `.bin` files, not text files; `Rename_Extensions_To_Big_Letter.sh` uppercases the *entire* filename (not just the extension, despite "Extensions" in its name) and does **not** recurse into subdirectories even though a comment in the script claims it does.
- Destructive / no-dry-run scripts: `Rename_Extensions_To_Big_Letter.sh` renames every file in the current directory immediately with no confirmation or preview. `7ZipAllPack.sh`/`7ZipUnPackAll.sh` require a password matching a hardcoded MD5 hash and have no dry-run mode, though `7ZipUnPackAll.sh` may hit an interactive overwrite prompt if the destination already has files. `MoveDocToArchive.sh` is the one script here with explicit `find`/`dryrun`/`run` stages to preview before moving anything.
- Hardcoded, machine-specific values are common: the 7Zip scripts embed a fixed password MD5, `SMB.sh` embeds a remote IP (`192.168.1.50`) and credential paths under `/home/nenad/`, and `MoveDocToArchive.sh`'s documented examples use paths like `/home/nenad/Billeder` — these are specific to the original author's machine and need editing before reuse elsewhere.
