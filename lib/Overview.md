# lib Overview

Shared code that the scripts in this repository source. Nothing here is run on its own.

---

## Shared Functions

| Script | Doc | Summary |
|---|---|---|
| `require_tools.sh` | [require_tools.md](require_tools.md) | Checks that the external tools a script needs are installed; prints one `apt install` command for the missing ones and stops the script. |

---

## Notes

- Scripts find this folder by walking up from their own location, so `lib/` must stay at the root of the repository.
