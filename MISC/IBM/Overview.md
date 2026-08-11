# IBM Scripts Overview

An index of the scripts in this folder and their documentation. Each script has a matching `.md` file (same base name) describing usage, configuration, step-by-step behavior, and notable gotchas.

---

## Hardware Info

| Script | Doc | Summary |
|---|---|---|
| `Info.sh` | [Info.MD](Info.MD) | Presents a menu to look up either the system serial number or the baseboard serial number of an IBM/Lenovo machine via `dmidecode`, based on the user's numeric choice. |

---

## Notes

- Must be run as root (`sudo ./Info.sh`); the script exits with an error message if the invoking user is not root.
- Invalid menu choices are handled gracefully with an on-screen error rather than a crash.
