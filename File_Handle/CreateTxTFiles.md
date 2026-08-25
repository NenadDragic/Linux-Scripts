# Create Test Files Script

Generates one or more large files filled with random binary data (via `/dev/urandom`), useful for creating test/dummy data of a known size — despite its filename, it does **not** create `.txt` files; the output files are named `file_NNNN.bin` and contain random bytes, not text.

---

## Usage

```console
chmod +x CreateTxTFiles.sh
bash CreateTxTFiles.sh [output_dir]
```

`output_dir` is optional; if omitted it defaults to `$HOME/testfiles`.

Prerequisites:

- Standard `dd`, `seq`, and `du` utilities (present on virtually any Linux system).
- Enough free disk space: with the default settings the script writes `COUNT * SIZE_MB` = `1 * 500` = 500 MB.
- Write access to the target output directory (it is created automatically if missing).

### Configuration (top of script)

| Variable | Default | Meaning |
|---|---|---|
| `OUTDIR` | `${1:-$HOME/testfiles}` | Destination folder for generated files; overridden by the first command-line argument |
| `COUNT` | `1` | Number of files to generate |
| `SIZE_MB` | `500` | Size of each generated file, in megabytes |

---

## What the Script Does

### Step 1 – Determine and create the output directory
Sets `OUTDIR` from the first argument (or `$HOME/testfiles` if none given) and runs `mkdir -p "$OUTDIR"`.

### Step 2 – Announce the plan
Prints "Opretter $COUNT filer á ${SIZE_MB} MB i: $OUTDIR".

### Step 3 – Generate the files
Loops `for i in $(seq 1 $COUNT)`, and for each iteration runs:

```bash
dd if=/dev/urandom of="$OUTDIR/file_$(printf "%04d" $i).bin" bs=1M count=$SIZE_MB 2>/dev/null
```

writing a `SIZE_MB`-megabyte file of random data named `file_0001.bin`, `file_0002.bin`, etc. `dd`'s stderr (progress info) is discarded.

### Step 4 – Progress reporting
Every 100th file (`i % 100 == 0`) prints a "$i / $COUNT færdig..." progress line. With the default `COUNT=1` this never triggers.

### Step 5 – Final summary
Prints "Færdig!" together with the total size of `OUTDIR` as reported by `du -sh`.

---

## Notes

- Filename vs. behavior mismatch: the script is named `CreateTxTFiles.sh` but creates random-binary `.bin` files, not text files.
- Not destructive: it only creates new files; it never deletes or overwrites existing content, though re-running with the same `OUTDIR` and default `COUNT=1` will overwrite `file_0001.bin` each time since the filename is deterministic.
- With the default `SIZE_MB=500` and `COUNT=1`, running the script writes 500 MB per invocation — increasing `COUNT` (by editing the script) multiplies disk usage accordingly and no free-space check is performed.
- Output messages ("Opretter...", "færdig...", "Færdig!... brugt.") are in Danish.
- Hardcoded default path `$HOME/testfiles` and hardcoded `SIZE_MB=500`.
