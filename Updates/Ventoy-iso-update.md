# Ventoy ISO Update

Downloads new releases of a fixed list of Linux ISOs, verifies each one cryptographically against the publisher's **pinned** OpenPGP key fingerprint, and copies it to a Ventoy USB stick. Nothing is put on the stick before verification has passed, and the copy on the stick is read back and compared with the verified file.

Without `--run` it is a dry run: only small files (keys, signatures, checksum files) are downloaded and verified, and the script shows what it would download and copy.

---

## Usage

```console
./Ventoy-iso-update.sh                         # dry run, all signed ISOs
./Ventoy-iso-update.sh --run                   # download, verify and copy
./Ventoy-iso-update.sh --run --only tails,qubes
./Ventoy-iso-update.sh --run --only fedora --delete-old --clean-staging
./Ventoy-iso-update.sh --list                  # items, groups and versions
```

| Option | Meaning |
| --- | --- |
| *(none)* | Dry run. Downloads and verifies keys, signatures and checksums only. No ISO is downloaded, nothing is copied. |
| `--run` | Download, verify and copy. |
| `--only LIST` | Comma-separated items or groups (see `--list`), for example `tails,qubes` or `fedora`. Default: all signed items. |
| `--allow-unsigned` | Also include distros that publish no signature (deepin, elementary, pop, zorin). They are only checked against a SHA-256 fetched over HTTPS or pinned in the script. |
| `--no-copy` | Download and verify in staging, but do not copy to the stick. |
| `--delete-old` | Delete older versions on the stick after a successful copy. Without it, they are only listed. |
| `--clean-staging` | Delete the downloaded ISO in staging after a successful copy. |
| `--dest DIR` | ISO folder on the Ventoy stick (default `/media/$USER/Ventoy/ISOs`). |
| `--staging DIR` | Work folder (default `~/Downloads/iso-staging`). |
| `--list` | Show items, groups and versions, then exit. |
| `-h`, `--help` | Show the header comment. |

Prerequisites:

- **Run as your normal user, not with `sudo`.** The default `--dest` uses `$USER` and the staging folder uses `$HOME`, and the stick is normally mounted for your user under `/media/$USER/Ventoy`. With `sudo` they point to `root`'s paths. The script does not check this.
- **Packages:** `curl` and `gnupg` (`gpg`, `gpgconf`). The rest (`flock`, `findmnt`, `lsblk`, `sha256sum`, `sha512sum`, `dd`, `numfmt`, `awk`, `sed`) is in a normal Debian/Ubuntu install. The script checks all of them at startup and stops with `Mangler værktøj: …` if one is missing. It does not use the shared `lib/require_tools.sh`.
- The Ventoy stick must be mounted and the target folder must be on a partition with the label `Ventoy`, and be writable.

### Configuration (top of script)

| Variable(s) | Description |
| --- | --- |
| `FEDORA_VER`, `MINT_VER`, `MX_VER`, `PARROT_VER`, `QUBES_VER`, `SOLUS_DATE`, `TAILS_VER`, `UBUNTU_SERIES`/`UBUNTU_VER`, `POP_SERIES`, `DEEPIN_VER` | Versions to fetch. **Must be updated by hand** for new releases. Debian, Fedora's file names, Manjaro, openSUSE and Pop!_OS find the newest file themselves. |
| `MANJARO_KDE_FALLBACK` | Used only if the newest Manjaro KDE ISO cannot be found on manjaro.org. |
| `ELEMENTARY_ISO`/`ELEMENTARY_SHA256`, `ZORIN_VER`/`ZORIN_SHA256` | Pinned file name and hash for the unsigned distros. Update both from the official page. |
| `FPR_*` | Pinned primary key fingerprints per publisher, with sources in the comments. Fedora has one key per version in `FPR_FEDORA`. |

---

## What the Script Does

### Step 1 – Setup

Parses the options, checks the tools, takes a lock (`$STAGING/.ventoy-iso-update.lock`) so only one run happens at a time, and logs everything to `$STAGING/ventoy-iso-update-<time>.log`. Unless `--no-copy` is given, it checks that `DEST` is on a partition labelled `Ventoy` and is writable (with `--run` a missing `DEST` is fatal; in a dry run it is a warning).

### Step 2 – Get the publisher's key

Each item gets its own temporary GnuPG home. The key is fetched from the publisher's own URL (when one is known) and then from three keyservers. A key is accepted **only** if its fingerprint matches the pinned one and no other key in the keyring has the same key ID, so the source and transport do not matter.

### Step 3 – Verify

Depending on what the publisher offers:

| Method | Items |
| --- | --- |
| Signed checksum file → SHA-256 of the ISO | Debian, Fedora, Mint, openSUSE, Parrot (SHA-512 or SHA-256, never MD5), Solus, Ubuntu |
| Detached signature on the ISO itself | Manjaro, MX, Tails |
| Signature by a release key certified by the Qubes Master Signing Key | Qubes |
| SHA-256 over HTTPS or pinned in the script (no signature) | deepin, elementary, Pop!_OS, Zorin – only with `--allow-unsigned` |

A signature only counts if `gpg` reports `VALIDSIG` from a pinned key; `BADSIG` or a revoked key always fails.

### Step 4 – Download

ISOs are downloaded to `$STAGING/<item>/` as `.part` files and renamed when complete, so an interrupted download resumes on the next run. A file left from an earlier run is verified again and reused if it passes. A file that fails verification is deleted. In a dry run, only the size of the remote file is checked.

### Step 5 – Copy and read back

Skips the copy if the stick already has an identical file (read back and compared). Otherwise it checks for free space (file size + 256 MiB), copies to a hidden `.part` file on the stick, syncs, renames, and reads the copy back with `O_DIRECT` (bypassing the page cache) to compare its SHA-256 with the verified file. A mismatch deletes the copy. Older versions matching the item's name pattern are then listed or, with `--delete-old`, deleted.

### Step 6 – Summary

Prints one line per item: `OK`, `KLAR (dry-run)`, `SPRUNGET OVER` or `FEJL`, marked `– usigneret` for unsigned items. After a `--run` it reminds you to unmount the stick (`udisksctl unmount -b <device>`).

### Exit codes

| Code | Meaning |
| --- | --- |
| `0` | All items OK, ready (dry run) or skipped |
| `1` | At least one item failed, a tool is missing, `DEST` is not a Ventoy partition, or another run holds the lock |
| `2` | Usage error (unknown option or item) |

---

## Notes

- **Versions need upkeep.** Most items use the version variables at the top. When a new release comes out, update the variable; for Fedora, also add the new version's key to `FPR_FEDORA` (the script refuses a Fedora version without a pinned key).
- **Fedora is skipped, not failed,** when the version folder does not exist on the server yet.
- **A wrong fingerprint is a hard stop.** If a publisher rotates its key, the item fails until the new fingerprint is checked against the publisher's page and added to the script.
- Not included on purpose: Windows (only time-limited download links), KDE neon (no Desktop User Edition at the moment), FreeBSD, Kali and Kodachi (can be added the same way).
- The header comment and output are in Danish. The header has its own version line (`1.3`, 2026-10-16) instead of the repository's standard header block, because `--help` prints the whole header.
