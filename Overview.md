# Linux-Scripts Repository Overview

Root index of every documented folder in this repository. Each folder listed below has its own `Overview.md` indexing the scripts inside it; each script has a matching `.md` file describing usage, configuration, step-by-step behavior, and notable gotchas.

---

## MISC

General-purpose Linux admin/utility scripts, grouped by topic.

| Folder | Overview | Scripts | What's there |
|---|---|---|---|
| `Backup` | [Overview](Backup/Overview.md) | 8 | Rsync-based backups (NAS/USB/SD), NAS-share copy to an encrypted WD drive, raw `dd` disk imaging, per-user crontab backups, plus USB mount management. |
| `MISC/Create_PDF_From_Web` | [Overview](MISC/Create_PDF_From_Web/Overview.md) | 1 | Converts a list of URLs into dated PDFs via `wkhtmltopdf`. |
| `MISC/File_Handle` | [Overview](MISC/File_Handle/Overview.md) | 12 | File discovery, archiving (7z), renaming, SMB share mounting, and test-data generation. |
| `MISC/IBM` | [Overview](MISC/IBM/Overview.md) | 1 | IBM server hardware/firmware info menu. |
| `MISC/Install` | [Overview](MISC/Install/Overview.md) | 2 | Driver/monitor-mode setup for the AWUS036ACH Wi-Fi adapter, plus an interactive apt tool-picker. |
| `MISC/Network` | [Overview](MISC/Network/Overview.md) | 1 | WireGuard VPN up/down/status wrapper. |
| `MISC/Pic` | [Overview](MISC/Pic/Overview.md) | 9 | Photo/video sorting by date and camera model, HEIC/DNG conversion, playback, and library maintenance. |
| `MISC/Screen` | [Overview](MISC/Screen/Overview.md) | 4 | GNU `screen` session helpers, plus an SSH host picker. |
| `MISC/Updates` | [Overview](MISC/Updates/Overview.md) | 5 | System/package/firmware update scripts across different distros and apps. |
| `MISC/git` | [Overview](MISC/git/Overview.md) | 4 | Bulk git maintenance (init/pull/status/commit) across a fixed list of cloned repos. |

## Synology

Scripts intended to run as Synology DSM Task Scheduler jobs.

| Folder | Overview | Scripts | What's there |
|---|---|---|---|
| `Synology` | [Overview](Synology/Overview.md) | 28 | Backup/copy jobs, DDNS updates, disk/file-count monitoring, find/delete cleanup pairs, integrity checks, and a system reboot script. |
| `Synology/Old` | [Overview](Synology/Old/Overview.md) | 5 | Older/likely-superseded variants of some of the scripts above — see its overview for which ones and the caveats around relying on them. |

## Other

| Folder | Doc | What's there |
|---|---|---|
| `Ansible/Update - RPI` | [README.md](Ansible/Update%20-%20RPI/README.md) | Ansible playbook for setting up and updating Raspberry Pi devices (Danish). Not covered by the Shell/Overview template since it's an Ansible project, not standalone scripts — it already has its own README. |

---

## Notes

- Every `.sh` script in `MISC/` and `Synology/` (excluding `Templates/`) now has a matching `.md` file; see [Templates/](Templates/) for the templates used to write them (PowerShell, Shell, Python, Overview).
- Several scripts across these folders print console output/comments in Danish even though all documentation is written in English — each affected script's own `.md` flags this individually.
- Known cross-script issues worth being aware of (not doc bugs, but real script quirks — see the relevant folder Overview for detail): `Synology/tmp files - Find.sh` and `Synology/tmp files - Delete.sh` target different volumes; `Synology/Old/` scripts largely duplicate scripts in `Synology/` under different casing, with at least one path mismatch between them.
- `Templates/` itself is intentionally excluded from this index — it holds reusable skeletons, not documentation of actual scripts.
