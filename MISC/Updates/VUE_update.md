# VUE Update

This script installs/updates VueScan on a Linux system: it downloads a tarball, extracts it, copies the VueScan binary and support files into system directories, purges two conflicting IPP/USB printing packages, and reloads udev rules. It must be run as root.

---

## Usage

```console
chmod +x VUE_update.sh
sudo bash VUE_update.sh
```

Run it from a directory the invoking user can write to — the tarball is downloaded and extracted into the current working directory, and the script expects `vuescan.svg`, `vuescan.rul`, and `vuescan` to end up directly in that directory after extraction (not in a subfolder).

Prerequisites:

- `wget` and `tar` available on the system.
- `apt` (Debian/Ubuntu-based system) for the package purge step.
- Must be run as root — the script checks `whoami` and exits otherwise.
- The `url` variable at the top of the script must be edited to point at a real VueScan `.tar.gz` download — as shipped it points at a placeholder (`https://example.com/somefile.tar.gz`) and will fail.

### Configuration (top of script)

| Variable | Default | Meaning |
|---|---|---|
| `url` | `https://example.com/somefile.tar.gz` | Placeholder download URL for the VueScan `.tar.gz` archive; must be replaced with the actual VueScan download link before running. |

---

## What the Script Does

### Step 1 – Verify root privileges
The script compares `$(whoami)` to `root`. If the current user is not root, it prints `Please run as root.\n` and exits without doing anything.

### Step 2 – Download the archive
Derives `filename` from the `url` variable using `basename`, then runs `wget $url` to download the archive into the current working directory, and prints "Download completed."

### Step 3 – Extract the archive
Runs `tar -xzf $filename` to extract the downloaded tarball into the current working directory, and prints "File extracted."

### Step 4 – Install VueScan files
Copies three files — assumed to now exist in the current directory from the extraction — into their system locations:
- `vuescan.svg` → `/usr/share/icons/hicolor/scalable/apps/`
- `vuescan.rul` → `/lib/udev/rules.d/60-vuescan.rules`
- `vuescan` → `/usr/bin/`

### Step 5 – Purge conflicting packages
Runs `sudo apt purge ippusbxd` and `sudo apt purge ipp-usb`, removing both packages (and their configuration) since they are known to conflict with VueScan's USB scanner access.

### Step 6 – Reload udev rules
Runs `sudo udevadm control --reload-rules` so the newly installed `60-vuescan.rules` udev rule takes effect without a reboot.

### Step 7 – Completion message
Prints "Script completed successfully."

---

## Notes

- **Placeholder URL**: the script will not work unedited — `url` must be changed from the example.com placeholder to a real VueScan download link, or the `wget`/`tar` steps will fail.
- **Destructive package removal**: Step 5 purges `ippusbxd` and `ipp-usb` system-wide via `apt purge`, which also deletes their configuration files. This affects any other software relying on IPP-over-USB printing/scanning support, not just VueScan.
- **Fragile extraction assumption**: the script assumes the extracted tarball places `vuescan.svg`, `vuescan.rul`, and `vuescan` directly in the current working directory. If the archive extracts into a subdirectory instead, the `cp` commands will fail with "No such file or directory".
- **No cleanup**: the downloaded `.tar.gz` file and any extracted files are left in the working directory after the script finishes.
- **Unquoted variables**: `$url` and `$filename` are used unquoted in the `wget`/`tar` commands, which could misbehave if either contained spaces or glob characters (not an issue with a normal URL/filename, but worth noting).
- Requires the `apt purge` prompts to be accepted or run non-interactively; the script does not pass `-y`, so `apt purge` may prompt for confirmation depending on the system's APT configuration.
