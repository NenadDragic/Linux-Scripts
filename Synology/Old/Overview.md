# Old Scripts Overview

An index of the scripts in this folder and their documentation. Each script has a matching `.md` file (same base name) describing usage, configuration, step-by-step behavior, and notable gotchas.

This `Old` subfolder holds scripts that appear to have been superseded by near-identical, differently-cased versions in the parent [`Synology`](../) folder (e.g. `Bak files - Delete.sh` here vs. `bak files - Delete.sh` in the parent, `TMP files - Delete.sh` here vs. `tmp files - Delete.sh` in the parent) — with the exception of `DDNS - Simply.sh`, which has no clear parent-folder replacement, since the parent's DDNS script (`DDNS - E-Studie.sh`) targets a completely different endpoint.

---

## File Cleanup

| Script | Doc | Summary |
|---|---|---|
| `Bak files - Delete.sh` | [Bak files - Delete.md](Bak%20files%20-%20Delete.md) | Deletes all files in the `/volume1/Dragic` directory that end with the `.bak` extension. |
| `Bak files - Find.sh` | [Bak files - Find.md](Bak%20files%20-%20Find.md) | Finds all files in the `/volume1/Dragic` directory that are named `*.bak`. |
| `TMP files - Delete.sh` | [TMP files - Delete.md](TMP%20files%20-%20Delete.md) | Deletes all files in the `/volume1/Dragic` directory that end with the `.tmp` extension. |
| `TMP files - Find.sh` | [TMP files - Find.md](TMP%20files%20-%20Find.md) | Finds all files in the `/volume1/Dragic` directory that end with the `.tmp` extension. |

## Dynamic DNS

| Script | Doc | Summary |
|---|---|---|
| `DDNS - Simply.sh` | [DDNS - Simply.md](DDNS%20-%20Simply.md) | Sends a DDNS update request to the Simply.com API to update the `nas.dragic.com` subdomain with the current IP. |

---

## Notes

- The parent folder's `tmp files - Delete.sh` operates on `/volume2/Dragic`, while this folder's `TMP files - Delete.sh` and `TMP files - Find.sh` operate on `/volume1/Dragic`. These are not simply identical duplicates of a moved/renamed script — the volume differs, so it's worth checking which one (if either) is actually still in use before relying on either.
- `DDNS - Simply.sh` has no equivalent in the parent folder to be superseded by: the parent's only DDNS script, `DDNS - E-Studie.sh`, calls a cPanel webcall URL rather than the Simply.com DDNS API, so the two are not interchangeable.
