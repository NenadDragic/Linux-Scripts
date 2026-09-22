# Install Tools

Presents a fixed list of apt packages and lets you pick which ones to install: filters out packages that are already installed or unavailable in the enabled repos, offers a graphical checklist (`whiptail`) with a text-based per-package fallback, handles two package-specific gotchas for Double Commander, then installs the selection with `apt-get`.

---

## Usage

```console
chmod +x Install_Tools.sh
./Install_Tools.sh
```

Can be run as a normal user (it asks for `sudo` itself) or directly with `sudo ./Install_Tools.sh` / as root. Takes no arguments — edit the `TOOLS` array at the top of the script to change what's offered.

Prerequisites:

- A Debian/Ubuntu-based system with `apt-get`, `dpkg-query` and `apt-cache`.
- Root access: either run as a non-root user with `sudo` installed and available (the script runs `sudo -v` up front), or run directly as root / via `sudo`.
- `whiptail` for the graphical checklist; if it's missing, the script falls back to asking one `[j/N]` question per package in the terminal.

### Configuration (top of script)

| Variable | Default | Meaning |
|---|---|---|
| `TOOLS` | `mtr`, `bat`, `glances`, `tmux`, `doublecmd-qt`, `doublecmd-plugins` | Candidate packages, as `package\|Danish description` pairs; edit this array to change what's offered |

---

## What the Script Does

### Step 1 – Resolve privileges
If already running as root, detects whether it was invoked via `sudo` (using `$SUDO_USER`) to know the real user/home for later steps, and runs the rest without `sudo`. Otherwise, requires `sudo` to be installed, calls `sudo -v` to obtain/cache credentials up front, and exits with an error if that fails.

### Step 2 – Update package lists
Runs `apt-get update -qq` so the availability check in the next step is accurate.

### Step 3 – Filter the candidate list
For each entry in `TOOLS`:
- Skipped with a checkmark if already installed — checked via `dpkg-query -W -f='${Status}'` for exactly `install ok installed`, so a package that was removed but not purged (status `config-files`) is *not* treated as installed.
- Skipped with a warning if `apt-cache policy` reports no install candidate (e.g. on Ubuntu, a package that needs the `universe` repo enabled).
- Otherwise added to the list offered for selection.

Exits immediately with "Intet at installere." if every candidate was filtered out.

### Step 4 – Let the user choose
If `whiptail` is available, shows a checklist of the remaining packages (all unchecked by default); cancelling exits cleanly. Otherwise, asks `[j/N]` for each package one at a time. Exits with "Intet valgt." if nothing was picked.

### Step 5 – Double Commander checks
Two checks run only if relevant packages were selected:
- If `doublecmd-plugins` was picked without `doublecmd-qt`, and neither `doublecmd-qt` nor `doublecmd-gtk` is already installed, warns that plugins alone install no GUI and asks (default yes) whether to add `doublecmd-qt` too.
- If `doublecmd-qt` was picked and `doublecmd-gtk` is already installed, warns that apt will remove `doublecmd-gtk` (Qt and GTK builds both provide/conflict/replace the virtual `doublecmd` package and can't coexist) and asks for confirmation (default no) before continuing; declining exits the script.

### Step 6 – Install
Prints the final selection and runs `apt-get install -y` with the selected packages.

### Step 7 – Optional `bat` symlink
If `bat` was selected and the `batcat` binary is present but no `bat` command is on `PATH` (the Debian/Ubuntu package installs the binary as `batcat`), asks (default no) whether to create `~/.local/bin/bat` as a symlink to `batcat` in the real user's home directory. If run as root via `sudo`, the created `~/.local` files are `chown`'d back to the real user.

---

## Notes

- **Not fully idempotent on re-runs with `doublecmd-*` mixed in:** if `doublecmd-qt` is already installed and you later run the script again just to add another tool, the Double Commander checks only look at `SELECTED`, so they won't re-trigger — this is intentional, not a bug, but worth knowing if you're checking the logic.
- **`apt-get` over `apt`:** the script deliberately uses `apt-get` for scripting, calling out in a comment that `apt`'s CLI is not considered stable and prints an "unstable CLI" warning.
- **Symlink question always asked, even after a previous run:** if `~/.local/bin/bat` already exists, `command -v bat` will find it and the question is skipped — but if the symlink was removed manually, the question reappears on every run where `bat`/`batcat` are involved.
- **Distribution-specific:** built around `apt-get`/`dpkg-query`/`apt-cache`, so it only works on Debian/Ubuntu-based systems; the "requires `universe`" hint in the availability warning is Ubuntu-specific phrasing.
- **`set -euo pipefail`:** the script exits immediately on most errors; the explicit early exits ("Intet at installere.", "Intet valgt.", cancelled `whiptail`, declined Double Commander confirmation) all use plain `exit 0`, so a deliberate no-op run is not distinguishable from success via the exit code.
- The script's own header comment still calls it `install-tools.sh`, although the file is named `Install_Tools.sh`.
- No dependency on any other script in the folder.
