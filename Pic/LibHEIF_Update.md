# LibHEIF Update Script

Builds and installs the latest tagged release of `libheif` from source (via `git`, `cmake`, `make`) on a Debian/Ubuntu-style system, and afterwards removes the distro-packaged `libheif1`/`libheif-dev` — but only if that doesn't drag other programs with it. This is a general system-maintenance script, not tied to a specific photo folder.

---

## Usage

```console
chmod +x LibHEIF_Update.sh
bash LibHEIF_Update.sh
```

Can be run from any directory — it does all of its work in a fixed temporary build folder. Requires `sudo` privileges (used for `apt remove`, `apt install`, `make install`, and `ldconfig`).

Prerequisites:

- An `apt`-based Linux distribution with `sudo` access.
- `git`, `cmake`, and `make` must already be installed — the dependency check below stops the script if any is missing (it does not install these three itself; `cmake` is reinstalled later as a build dependency).
- Internet access to clone `https://github.com/strukturag/libheif.git`.
- Dependency check: the script starts by sourcing the shared `lib/require_tools.sh` (found by walking up from the script's own folder) and stops with an `apt install` hint if any of these are missing: `git`, `cmake`, `make`, `sudo`

---

## What the Script Does

`set -e` is active, so the script aborts on the first unhandled command failure. `main()` runs the following functions in order, each logged with a `[$(date +'%Y-%m-%d %H:%M:%S')]` timestamp prefix via the `log()` helper:

### Step 1 – `install_dependencies`

Runs `sudo apt update`, then `sudo apt install -y build-essential cmake pkg-config libaom-dev libx265-dev libjpeg-dev libpng-dev libde265-dev libtool autoconf automake`.

### Step 2 – `build_latest_version`

- Removes `/tmp/libheif-build` if it already exists, then recreates it and `cd`s in.
- Clones `libheif` from GitHub into that directory, fetches all tags, and determines the latest one with `git describe --tags $(git rev-list --tags --max-count=1)`.
- Checks out that tag, creates a `build` subdirectory, configures with `cmake -DCMAKE_BUILD_TYPE=Release ..`, compiles with `make -j$(nproc)`, then installs with `sudo make install` and refreshes the linker cache with `sudo ldconfig`.

### Step 3 – `remove_old_version`

Runs only after the new version is built and installed. Simulates the removal first (`apt-get -s remove libheif1 libheif-dev`) and reads which packages apt would remove:

- nothing → logs that no distro packages are installed;
- only `libheif*` packages → runs `sudo apt-get remove --purge -y libheif1 libheif-dev` and `sudo ldconfig`;
- anything else (image viewers, thumbnailers, ImageMagick … that depend on `libheif1`) → lists those packages and removes **nothing**. The source build in `/usr/local` takes precedence over the distro copy in both `PATH` and the linker search order, so keeping the distro package is harmless.

There is no `apt autoremove` any more.

### Step 4 – `verify_installation`

Checks whether `heif-info` is now on `PATH`. If found, logs `heif-info --version`; otherwise logs a warning that the command was not found.

### Step 5 – `cleanup`

Removes `/tmp/libheif-build`.

---

## Notes

- Up to v1.0 the distro packages were purged with `-y` (plus `apt autoremove -y`) *before* the build. That could uninstall every program depending on `libheif1`, and a failed build left the system without any `libheif`. Since v1.1 the build comes first and the removal is skipped whenever it would take other packages with it.
- Requires working (and likely interactive, unless cached) `sudo` for several steps — it will prompt for a password if not already authenticated.
- The build working directory `/tmp/libheif-build` is hardcoded; it is wiped and recreated at the start of `build_latest_version` and removed again in `cleanup`, so nothing persists between runs.
- "Latest version" means the most recent reachable git tag (`git rev-list --tags --max-count=1`), not necessarily the highest semantic version if tags were not created in chronological order.
- Safe to re-run: each run starts from a fresh build folder, but every run does a full rebuild from source, which is time-consuming.
- Not photo-folder specific — this is a standalone dependency installer that the other scripts in this folder (e.g. `Convert.sh`, `Sort_Total.sh`) rely on indirectly for HEIC support.
- Comments are in English.
