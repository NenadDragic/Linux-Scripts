# require_tools

Shared dependency checker. Scripts in this repository source it and call `require_tools` with the external tools they need; if any are missing, it prints one `apt install` command for all of them and stops the script.

---

## Usage

Scripts do not source it directly. Each script starts with this block, which walks up from the script's own folder until it finds `lib/require_tools.sh`:

```bash
# --- Dependency check (auto-inserted) ---
_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
while [ "$_d" != "/" ] && [ ! -f "$_d/lib/require_tools.sh" ]; do _d="$(dirname "$_d")"; done
if [ ! -f "$_d/lib/require_tools.sh" ]; then
    echo "FEJL: Kunne ikke finde lib/require_tools.sh (delt dependency-checker)." >&2
    exit 1
fi
# shellcheck source=/dev/null
source "$_d/lib/require_tools.sh"
unset _d
require_tools rsync "runuser:util-linux"
```

Each argument is either `tool` or `tool:apt-package` (when the package name differs from the command).

Only add the block to scripts that use tools beyond the standard base system (coreutils, `find`, `sed`, `awk`, `grep`, `tar`, `gzip`, `mount` …). Tools a script only uses optionally (checked with `command -v`) are not listed.

---

## What the Script Does

### Step 1 – Check each tool
For every argument, looks the tool up with `command -v`, and also in `/usr/local/sbin`, `/usr/sbin` and `/sbin`, so tools like `cryptsetup` are found for normal users whose `PATH` has no `sbin`.

### Step 2 – Report and stop
If anything is missing, prints the missing tools and a single `sudo apt install <packages>` line (each package listed once) to stderr, then calls `exit 1`, which ends the calling script.

---

## Notes

- The file is meant to be sourced, not run.
- Messages are in Danish.
