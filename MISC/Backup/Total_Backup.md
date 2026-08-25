# Total Backup

This script must be run as root. It images three fixed NVMe partitions (`/dev/nvme0n1p1`, `p2`, `p3`) to raw `.img` files in a backup directory, naming each image after the partition's type (via `lsblk`) and the current date. For each partition it copies the data twice in a row into the same output file — once through `pv | dd` for a progress meter, then again through a second, independent `dd` — which is redundant and roughly doubles the read/write time for no benefit.

---

## Usage

```console
chmod +x Total_Backup.sh
sudo bash Total_Backup.sh
```

Run it as root (the script checks `whoami` and exits with an error if it isn't `root`), from any working directory — but note that `backup_dir` is a *relative* path (see Notes), so the current working directory at launch time determines where the images actually land. Takes no arguments.

Prerequisites:

- `lsblk`, `pv`, and `dd` (the `pv` package is often not installed by default and may need to be installed manually — the script does not auto-install it).
- Must be run as root.
- The directory referred to by `backup_dir` must already exist and be mounted; the script never creates it.
- The specific block devices `/dev/nvme0n1p1`, `/dev/nvme0n1p2`, and `/dev/nvme0n1p3` must exist on the machine it's run on.

### Configuration (top of script)

| Variable | Default | Meaning |
|---|---|---|
| `backup_dir` | `../../media/nenad/3CA79D5F2053D934` | Directory where `.img` backups are written — a *relative* path, resolved against the script's current working directory at launch, despite resembling an absolute mount path |
| `date` | `$(date +%Y-%m-%d)` | Date stamp appended to each output image's filename |

---

## What the Script Does

### Step 1 – Root check
Compares `whoami` to `root`; if they don't match, prints "Please run as root." and exits.

### Step 2 – Define paths and date
Sets `backup_dir` and captures the current date as `YYYY-MM-DD` into `date`.

### Step 3 – Back up drive 1 (`/dev/nvme0n1p1`)
Prints "Backing up drive 1...", looks up the partition type name via `lsblk -no parttypename`, then copies the partition to `"$backup_dir/$drive_type $date.img"` **twice in a row**: first via `pv -tpreb ... | dd of=... bs=4M` (progress shown by `pv`), then immediately again via a plain `dd if=... of=... bs=4M status=progress` reading the same source into the same destination file.

### Step 4 – Back up drive 2 (`/dev/nvme0n1p2`)
Identical pattern to Step 3, for the second partition.

### Step 5 – Back up drive 3 (`/dev/nvme0n1p3`)
Identical pattern to Step 3, for the third partition.

### Step 6 – Dead code
A fourth, near-identical block (again targeting `/dev/nvme0n1p3`) is present at the end of the script but entirely commented out — it has no effect.

### Step 7 – Completion message
Prints "Backup complete!".

---

## Notes

- Each of the three partitions is copied **twice**, back-to-back, into the exact same output file (once via `pv | dd`, once again via a bare `dd`) — the second pass re-reads the whole device and overwrites the first pass's output, roughly doubling total I/O and runtime with no added benefit. This looks like leftover/duplicated code rather than intended behavior.
- `backup_dir` is a *relative* path (`../../media/nenad/3CA79D5F2053D934`), not absolute, even though it looks like it targets a fixed external drive/mount label — the actual destination depends on the working directory the script is launched from.
- The script never creates `backup_dir` (unlike `MoveDocToArchive.sh`, which does `mkdir -p`); if it doesn't exist or isn't mounted, the `dd of=...` calls will fail.
- Destructive by nature: `dd of=...` unconditionally overwrites any existing file of the same name, and it reads raw block devices requiring root — there is no confirmation prompt before starting.
- Hardcoded device paths (`/dev/nvme0n1p1`, `p2`, `p3`) and the mount label `3CA79D5F2053D934` tie this script to one specific machine; on any other system it will target the wrong devices or fail outright.
- A fourth backup block (originally for `nvme0n1p3` again) is left commented out at the bottom of the file — dead code with no runtime effect.
- No dependency on any other script in the folder.
