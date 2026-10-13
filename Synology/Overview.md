# Synology Scripts Overview

An index of the scripts in this folder and their documentation. Each script has a matching `.md` file describing usage, configuration, step-by-step behavior, and notable gotchas.

---

## DSM Task Scheduler Check

| Script | Doc | Summary |
| --- | --- | --- |
| `nas-dss-check.sh` | [nas-dss-check.md](nas-dss-check.md) | Finds the newest DSM configuration export (`.dss`) in `~/Downloads` and runs `nas-dss-check.py` on it against the `Devices` git repository. |
| `nas-dss-check.py` | [nas-dss-check.py.md](nas-dss-check.py.md) | Compares the Task Scheduler scripts in a `.dss` export with the scripts in git, shows the lines that differ, syntax-checks and lints them, and searches both for secrets. |

---

## Notes

- The two scripts share a base name, so the Python script's doc is named `nas-dss-check.py.md`; `nas-dss-check.md` documents the shell wrapper.
- The two `nas-dss-check` scripts run on the workstation, not on the NAS, and neither needs `sudo`. They only read the export and the git folders, unless `--export` is used.
- `USB_Copy_Clean_Delete.sh` has moved to the `Devices` repository (`NAS/Synology/root-scripts/`), next to the other scripts that run on the NAS.
- `nas-dss-check` requires `python3`; `shellcheck` is optional. The wrapper checks for both itself instead of using the shared `lib/require_tools.sh`.
- Comments and console output are in Danish.
