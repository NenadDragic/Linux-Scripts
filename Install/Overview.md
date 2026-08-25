# Install Scripts Overview

An index of the scripts in this folder and their documentation. Each script has a matching `.md` file (same base name) describing usage, configuration, step-by-step behavior, and notable gotchas.

---

## Driver Installation

| Script | Doc | Summary |
|---|---|---|
| `Install_AWUS036ACH.sh` | [Install_AWUS036ACH.md](Install_AWUS036ACH.md) | Configures a Wi-Fi adapter on Kali Linux by updating/upgrading system packages and installing the driver for the Realtek RTL88xxAU wireless chipset (the Alfa AWUS036ACH adapter), then provides instructions for putting the adapter into monitor mode. |

---

## Notes

- Targets Kali Linux specifically and requires root (`sudo ./Install_AWUS036ACH.sh`).
- Combines `apt-get` package installation with a `git clone` + `make`/`make install` build of the driver from the `aircrack-ng/rtl8812au` repository.
- Monitor-mode configuration (`ip link` / `iw dev` commands) is presented as follow-up instructions rather than something the script executes automatically.
