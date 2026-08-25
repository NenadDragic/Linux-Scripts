# LibHEIF Update Script

Removes any distro-packaged `libheif1`/`libheif-dev`, then builds and installs the latest tagged release of `libheif` from source (via `git`, `cmake`, `make`) on a Debian/Ubuntu-style system. This is a general system-maintenance script, not tied to a specific photo folder.

---

## Usage

```console
chmod +x LibHEIF_Update.sh
bash LibHEIF_Update.sh
```

Can be run from any directory — it does all of its work in a fixed temporary build folder. Requires `sudo` privileges (used for `apt remove`, `apt install`, `make install`, and `ldconfig`).

Prerequisites:

- An `apt`-based Linux distribution with `sudo` access.
- `git`, `cmake`, and `make` must already be installed — the script checks each with `check_command` and exits with an error if any is missing (it does not install these three itself).
- Internet access to clone `https://github.com/strukturag/libheif.git`.

---

## What the Script Does

`set -e` is active, so the script aborts on the first unhandled command failure. `main()` runs the following functions in order, each logged with a `[$(date +'%Y-%m-%d %H:%M:%S')]` timestamp prefix via the `log()` helper:

### Step 1 – `remove_old_version`
Runs `sudo apt remove --purge -y libheif1 libheif-dev` and `sudo apt autoremove -y`, both suffixed with `|| true` so a "package not installed" failure does not stop the script.

### Step 2 – `install_dependencies`
Runs `sudo apt update`, then `sudo apt install -y build-essential cmake pkg-config libaom-dev libx265-dev libjpeg-dev libpng-dev libde265-dev libtool autoconf automake`.

### Step 3 – `build_latest_version`
- Removes `/tmp/libheif-build` if it already exists, then recreates it and `cd`s in.
- Clones `libheif` from GitHub into that directory, fetches all tags, and determines the latest one with `git describe --tags $(git rev-list --tags --max-count=1)`.
- Checks out that tag, creates a `build` subdirectory, configures with `cmake -DCMAKE_BUILD_TYPE=Release ..`, compiles with `make -j$(nproc)`, then installs with `sudo make install` and refreshes the linker cache with `sudo ldconfig`.

### Step 4 – `verify_installation`
Checks whether `heif-info` is now on `PATH`. If found, logs `heif-info --version`; otherwise logs a warning that the command was not found.

### Step 5 – `cleanup`
Removes `/tmp/libheif-build`.

---

## Notes

- **Destructive by design:** existing `libheif1`/`libheif-dev` packages are purged before the source build even starts. If the clone, build, or install step fails, the system can be left without any `libheif` until the script is run again successfully.
- Requires working (and likely interactive, unless cached) `sudo` for several steps — it will prompt for a password if not already authenticated.
- The build working directory `/tmp/libheif-build` is hardcoded; it is wiped and recreated at the start of `build_latest_version` and removed again in `cleanup`, so nothing persists between runs.
- "Latest version" means the most recent reachable git tag (`git rev-list --tags --max-count=1`), not necessarily the highest semantic version if tags were not created in chronological order.
- Safe to re-run in the sense that each run starts by removing the old package/build state, but every run does a full rebuild from source, which is time-consuming.
- Not photo-folder specific — this is a standalone dependency installer that the other scripts in this folder (e.g. `Convert.sh`, `Sort_Total.sh`) rely on indirectly for HEIC support.
- Comments are in English.
