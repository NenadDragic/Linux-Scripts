# Install_AWUS036ACH

Sets up the Realtek RTL88xxAU Wi-Fi driver needed for the Alfa AWUS036ACH USB adapter on a Debian/Kali-based system: it updates the system, installs the driver package and build tooling, builds/installs the driver from source, and prints the commands needed to put the adapter into monitor mode afterward.

---

## Usage

```console
chmod +x Install_AWUS036ACH.sh
sudo bash Install_AWUS036ACH.sh
```

Run it from any writable directory — the script `git clone`s the driver source into an `rtl8812au` subfolder of the current directory and builds it there.

Prerequisites:

- A Debian/Kali-based system with `apt-get` and internet access.
- Root privileges (the package management and driver install commands use `sudo`, so the script should be run with `sudo` or as root).
- Build tooling implied by `make` (a C compiler / kernel headers), which is expected to already be present or pulled in as a dependency of `dkms`/`realtek-rtl88xxau-dkms`.
- `git`, `dkms`, and `realtek-rtl88xxau-dkms` — the script installs these itself via `apt-get` if missing.

---

## What the Script Does

### Step 1 – Update and upgrade the system
Runs `sudo apt-get update`, `sudo apt-get upgrade -y`, and `sudo apt-get dist-upgrade -y` to refresh the package index and bring all installed packages up to date.

### Step 2 – Install required packages
Runs `sudo apt-get install -y dkms git realtek-rtl88xxau-dkms` to install the DKMS framework, Git, and the Realtek RTL88xxAU DKMS driver package.

### Step 3 – Clone the driver source
Runs `git clone https://github.com/aircrack-ng/rtl8812au.git` and `cd rtl8812au`, checking out the aircrack-ng project's RTL8812AU driver source into a new subfolder of the current directory.

### Step 4 – Build and install the driver
Runs `make` to build the driver from source, then `sudo make install` to install it.

### Step 5 – Print monitor-mode setup instructions
Echoes the three commands needed to put the `wlan1` interface into monitor mode (`sudo ip link set wlan1 down`, `sudo iw dev wlan1 set type monitor`, `sudo ip link set wlan1 up`) and a link to a Hackernoon article on configuring the AWUS036ACH on Kali Linux. These commands are only printed, not executed.

---

## Notes

- Not idempotent: re-running it re-runs the full system upgrade and re-clones into `rtl8812au`, which will fail with a "destination path already exists" error if that folder is still present from a previous run.
- System-wide effects: `apt-get upgrade`/`dist-upgrade` can upgrade or change any installed package on the machine, not just Wi-Fi-related ones — this is a broad, potentially disruptive operation on a system already in use.
- Hardcoded interface name: the printed monitor-mode instructions assume the adapter shows up as `wlan1`; on a given machine it could be named differently (`wlan0`, `wlx...`, etc.), and the script does not detect or verify this.
- The monitor-mode commands are only echoed to the terminal as a reminder — the script does not put the adapter into monitor mode itself.
- Installs `realtek-rtl88xxau-dkms` from `apt-get` and *also* builds a second copy of a similar driver from source (`aircrack-ng/rtl8812au`) via DKMS/`make install`; having both present could lead to driver/module conflicts, which the script does not check for.
- Assumes a `dkms`/`apt-get`-based distribution (Debian/Kali); it will not work as-is on non-Debian-based Linux distributions.
