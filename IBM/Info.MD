# Info

Provides an interactive menu to look up the serial number of an IBM/Lenovo server via `dmidecode`, reading either the chassis/system serial or the baseboard (motherboard) serial depending on the option chosen.

---

## Usage

```console
chmod +x Info.sh
sudo bash Info.sh
```

Run it directly on the machine whose serial number you want to read; it has no arguments and works on whichever host it's run on.

Prerequisites:

- `dmidecode` installed.
- Must be run as root (the script checks `whoami` and exits immediately if it isn't `root`), typically via `sudo`.

---

## What the Script Does

### Step 1 – Verify root privileges
Checks whether `whoami` returns `root`; if not, it prints "Please run as root." and exits without doing anything else.

### Step 2 – Present the menu
Prints two numbered options and reads a single value into `choice`:
- `1` – read the system/chassis serial number
- `2` – read the baseboard (motherboard) serial number

### Step 3 – Run the selected command
Based on `choice`:
- `1` runs `sudo dmidecode -t system | grep Serial`
- `2` runs `sudo dmidecode -t baseboard | grep Serial`
- Any other input prints "Invalid choice. Please choose 1 or 2." and the script ends without running `dmidecode`.

---

## Notes

- Read-only: it only queries hardware info via `dmidecode` and never modifies anything, so it's always safe to re-run.
- The root check uses `whoami` rather than `$EUID`/`id -u`, which is a less common but equivalent way to detect root.
- No validation loop: an invalid menu entry just ends the script with an error message rather than re-prompting.
- Despite the script's location under `MISC/IBM`, it works on any system with `dmidecode` (not IBM/Lenovo-specific) — it's just that the serial-number fields it greps for are most commonly used to identify IBM/Lenovo server hardware.
