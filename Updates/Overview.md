# Updates Scripts Overview

An index of the scripts in this folder and their documentation. Each script has a matching `.md` file (same base name) describing usage, configuration, step-by-step behavior, and notable gotchas.

---

## System & App Updates

| Script | Doc | Summary |
|---|---|---|
| `Total_Update.sh` | [Total_Update.md](Total_Update.md) | Checks for root privileges, then updates APT packages (`update`/`upgrade`/`dist-upgrade`/`autoremove`/`autoclean`) and refreshes the `locate` database (`updatedb`) on a Debian-based system. |
| `Total_Update_Debian.sh` | [Total_Update_Debian.md](Total_Update_Debian.md) | Runs a fuller update pass on a Debian/Ubuntu machine covering APT, Snap, Flatpak, firmware (`fwupd`), user-level pip packages, global npm packages, and the `locate` database, then reports whether a reboot is needed. |
| `Total_Update_Ubuntu.sh` | [Total_Update_Ubuntu.md](Total_Update_Ubuntu.md) | Ubuntu Desktop-labeled fork of `Total_Update_Debian.sh`: same full pass (APT, Snap, Flatpak, `fwupd`, pip, npm, `updatedb`), warns if the detected OS isn't Ubuntu. |
| `Total_Update_Ubuntu_Server.sh` | [Total_Update_Ubuntu_Server.md](Total_Update_Ubuntu_Server.md) | Headless variant for Ubuntu Server: same as `Total_Update_Ubuntu.sh` minus Flatpak; warns if a graphical desktop is detected (suggesting the desktop script instead). |
| `Total_Update_RaspberryPi.sh` | [Total_Update_RaspberryPi.md](Total_Update_RaspberryPi.md) | Raspberry Pi variant: APT, EEPROM/bootloader firmware via `rpi-eeprom-update` (instead of `fwupd`), Snap, pip, npm, `updatedb`. Reads `/proc/device-tree/model` to identify the Pi hardware. |
| `IBM_Firmware_Update.sh` | [IBM_Firmware_Update.md](IBM_Firmware_Update.md) | Checks for root privileges, then runs `fwupdmgr get-updates` followed by `fwupdmgr update` to detect and apply available firmware updates for devices on the system. |
| `Update_Flightradar24.sh` | [Update_Flightradar24.md](Update_Flightradar24.md) | Stops the `fr24feed` service, removes the old Flightradar24 package, downloads and installs the latest `.deb` package from the official repository, then restarts the service. |
| `VUE_update.sh` | [VUE_update.md](VUE_update.md) | Downloads, extracts, and installs VueScan on a Linux system as root — copying the icon, udev rule, and binary into place, purging conflicting `ippusbxd`/`ipp-usb` packages, and reloading udev rules. |

---

## Notes

- `Total_Update.sh` and `Total_Update_Debian.sh` are effectively distro-variant/scope-variant counterparts of each other: `Total_Update.sh` is the simpler script (APT maintenance + `updatedb` only), while `Total_Update_Debian.sh` is a more comprehensive rewrite that adds Snap, Flatpak, firmware, pip, and npm updates plus reboot detection. `Total_Update_Debian.sh`'s own header comment still internally labels it `ubuntu-total-update.sh`, a leftover from an Ubuntu-focused origin, even though its OS-detection logic handles both Ubuntu and Debian.
- `Total_Update_Ubuntu.sh`, `Total_Update_Ubuntu_Server.sh`, and `Total_Update_RaspberryPi.sh` are target-specific forks of `Total_Update_Debian.sh`, kept as separate files rather than folded into it: `Total_Update_Ubuntu.sh` matches `Total_Update_Debian.sh` step-for-step but is Ubuntu-labeled; `Total_Update_Ubuntu_Server.sh` drops the Flatpak step (no role on a headless box); `Total_Update_RaspberryPi.sh` also drops Flatpak and swaps the `fwupd` firmware step for `rpi-eeprom-update` (how Pi boot/EEPROM firmware actually updates). `Total_Update_Debian.sh` itself is unchanged and still exists as the generic Debian/Ubuntu combined script.
- All `Total_Update_*.sh` scripts' console output and internal comments are in Danish (e.g. "Opdaterer", "Fjerner", "Kør: sudo reboot"), unlike the rest of this folder's scripts.
- Most scripts require root/`sudo` and explicitly check for it: `IBM_Firmware_Update.sh`, `Total_Update.sh`, `Total_Update_Debian.sh`, `Total_Update_Ubuntu.sh`, `Total_Update_Ubuntu_Server.sh`, `Total_Update_RaspberryPi.sh`, and `VUE_update.sh`.
- Version/URL values that need manual upkeep: `Update_Flightradar24.sh` hardcodes the `fr24feed` `.deb` version in its download URL and filename, and `VUE_update.sh` requires the user to replace a placeholder `url="https://example.com/somefile.tar.gz"` with the real VueScan download link before it will work.
- Destructive/risky operations run non-interactively (no confirmation prompt): `Total_Update_Debian.sh`/`Total_Update_Ubuntu.sh`/`Total_Update_Ubuntu_Server.sh`/`Total_Update_RaspberryPi.sh` run `apt-get full-upgrade -y`, `apt-get autoremove -y`, and `snap remove ... --revision=...`; the Debian/Ubuntu-Desktop scripts add `flatpak uninstall --unused -y`; the Debian/Ubuntu variants' `fwupdmgr update -y` and the Raspberry Pi variant's `rpi-eeprom-update -a` both flash device firmware, which can be irreversible or require a manual re-flash if it fails mid-update. `VUE_update.sh` purges `ippusbxd`/`ipp-usb` packages as a side effect of installing VueScan.
